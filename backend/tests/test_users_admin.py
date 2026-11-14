import pytest

PASSWORD = "Password123Secure!"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _admin_with_farm(client, email="admin@ganadera.com"):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Admin", "email": email, "password": PASSWORD},
    ).json()["access_token"]
    farm = client.post(
        "/api/v1/farms", json={"nombre": "Finca Principal"}, headers=_auth(token)
    ).json()
    return token, farm["id"]


def _create_user(client, admin_token, farm_id, role="VETERINARIO", email="vet@ganadera.com", **extra):
    return client.post(
        "/api/v1/users",
        json={
            "nombre": "Usuario Finca",
            "email": email,
            "password": PASSWORD,
            "role": role,
            "farm_id": farm_id,
            **extra,
        },
        headers=_auth(admin_token),
    )


def _login(client, email, role):
    return client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": PASSWORD, "role": role},
    )


def test_admin_creates_veterinarian_who_logs_in_with_role_defaults(client):
    admin_token, farm_id = _admin_with_farm(client)

    created = _create_user(client, admin_token, farm_id)
    assert created.status_code == 201
    body = created.json()
    assert body["role"] == "VETERINARIO"
    assert body["farm_id"] == farm_id
    assert body["permissions"] == ["registro", "sanidad", "reproduccion", "reportes"]

    login = _login(client, "vet@ganadera.com", "VETERINARIO")
    assert login.status_code == 200
    me = client.get("/api/v1/auth/me", headers=_auth(login.json()["access_token"]))
    assert me.json()["farm_id"] == farm_id

    listed = client.get("/api/v1/users", headers=_auth(admin_token))
    assert [user["email"] for user in listed.json()] == ["vet@ganadera.com"]


def test_field_worker_maps_to_mayordomo_role(client):
    admin_token, farm_id = _admin_with_farm(client)
    _create_user(client, admin_token, farm_id, role="MAYORDOMO", email="campo@ganadera.com")

    assert _login(client, "campo@ganadera.com", "VETERINARIO").status_code == 403
    assert _login(client, "campo@ganadera.com", "MAYORDOMO").status_code == 200


def test_admin_cannot_create_other_admins_or_duplicates(client):
    admin_token, farm_id = _admin_with_farm(client)
    assert _create_user(client, admin_token, farm_id, role="ADMIN").status_code == 422
    assert _create_user(client, admin_token, farm_id).status_code == 201
    assert _create_user(client, admin_token, farm_id).status_code == 409


def test_staff_cannot_use_admin_endpoints(client):
    admin_token, farm_id = _admin_with_farm(client)
    _create_user(client, admin_token, farm_id)
    vet_token = _login(client, "vet@ganadera.com", "VETERINARIO").json()["access_token"]

    assert client.get("/api/v1/users", headers=_auth(vet_token)).status_code == 403
    assert _create_user(client, vet_token, farm_id, email="otro@ganadera.com").status_code == 403
    assert client.post(
        "/api/v1/farms", json={"nombre": "Finca Pirata"}, headers=_auth(vet_token)
    ).status_code == 403


def test_admin_cannot_manage_users_or_farms_of_other_admins(client):
    admin_token, farm_id = _admin_with_farm(client)
    other_token, other_farm_id = _admin_with_farm(client, email="otro-admin@ganadera.com")
    vet_id = _create_user(client, admin_token, farm_id).json()["id"]

    assert _create_user(
        client, admin_token, other_farm_id, email="intruso@ganadera.com"
    ).status_code == 404
    assert client.patch(
        f"/api/v1/users/{vet_id}", json={"is_active": False}, headers=_auth(other_token)
    ).status_code == 404
    assert client.get("/api/v1/users", headers=_auth(other_token)).json() == []
    assert client.patch(
        f"/api/v1/farms/{farm_id}", json={"nombre": "Robada"}, headers=_auth(other_token)
    ).status_code == 404


def test_deactivated_user_cannot_log_in_or_use_token(client):
    admin_token, farm_id = _admin_with_farm(client)
    vet_id = _create_user(client, admin_token, farm_id).json()["id"]
    vet_token = _login(client, "vet@ganadera.com", "VETERINARIO").json()["access_token"]

    updated = client.patch(
        f"/api/v1/users/{vet_id}", json={"is_active": False}, headers=_auth(admin_token)
    )
    assert updated.status_code == 200
    assert updated.json()["is_active"] is False

    assert _login(client, "vet@ganadera.com", "VETERINARIO").status_code == 403
    assert client.get("/api/v1/auth/me", headers=_auth(vet_token)).status_code == 403


def test_password_change_by_admin_revokes_sessions(client):
    admin_token, farm_id = _admin_with_farm(client)
    vet_id = _create_user(client, admin_token, farm_id).json()["id"]
    vet_token = _login(client, "vet@ganadera.com", "VETERINARIO").json()["access_token"]

    client.patch(
        f"/api/v1/users/{vet_id}", json={"password": "NuevaClave2026!"}, headers=_auth(admin_token)
    )
    assert client.get("/api/v1/auth/me", headers=_auth(vet_token)).status_code == 401


@pytest.mark.parametrize(
    ("module", "method", "path"),
    [
        ("insumos", "get", "/api/v1/inventory"),
        ("produccion", "get", "/api/v1/production"),
    ],
)
def test_module_permissions_are_enforced(client, module, method, path):
    admin_token, farm_id = _admin_with_farm(client)
    vet_id = _create_user(client, admin_token, farm_id).json()["id"]
    vet_token = _login(client, "vet@ganadera.com", "VETERINARIO").json()["access_token"]

    # Por defecto el veterinario no tiene insumos ni producción.
    assert getattr(client, method)(path, headers=_auth(vet_token)).status_code == 403

    granted = client.patch(
        f"/api/v1/users/{vet_id}", json={"permisos": [module]}, headers=_auth(admin_token)
    )
    assert granted.json()["permissions"] == [module]
    assert getattr(client, method)(path, headers=_auth(vet_token)).status_code == 200


def test_revoking_registro_blocks_animal_creation_but_not_listing(client):
    admin_token, farm_id = _admin_with_farm(client)
    vet_id = _create_user(client, admin_token, farm_id).json()["id"]
    vet_token = _login(client, "vet@ganadera.com", "VETERINARIO").json()["access_token"]
    client.patch(
        f"/api/v1/users/{vet_id}", json={"permisos": ["sanidad"]}, headers=_auth(admin_token)
    )

    animal = {
        "tag_id": "GAV-001",
        "gender": "HEMBRA",
        "birth_date": "2024-01-10",
        "breed": "Holstein",
        "current_weight": 320,
        "farm_id": farm_id,
    }
    assert client.post("/api/v1/animals", json=animal, headers=_auth(vet_token)).status_code == 403
    assert client.get("/api/v1/animals", headers=_auth(vet_token)).status_code == 200
    assert client.post("/api/v1/animals", json=animal, headers=_auth(admin_token)).status_code == 201


def test_unknown_module_is_rejected(client):
    admin_token, farm_id = _admin_with_farm(client)
    response = _create_user(client, admin_token, farm_id, permisos=["finanzas"])
    assert response.status_code == 422


def test_admin_switches_active_farm(client):
    admin_token, farm_id = _admin_with_farm(client)
    second = client.post(
        "/api/v1/farms", json={"nombre": "Finca Norte"}, headers=_auth(admin_token)
    ).json()["id"]

    activated = client.post(f"/api/v1/farms/{second}/activate", headers=_auth(admin_token))
    assert activated.status_code == 200
    me = client.get("/api/v1/auth/me", headers=_auth(admin_token)).json()
    assert me["farm_id"] == second
    assert me["permissions"] == [
        "registro", "sanidad", "reproduccion", "produccion", "insumos", "reportes",
    ]
