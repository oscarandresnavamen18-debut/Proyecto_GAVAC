from datetime import date, timedelta


PASSWORD = "Password123Secure!"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _admin_farm(client, email="admin@ganadera.com"):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Admin", "email": email, "password": PASSWORD},
    ).json()["access_token"]
    farm_id = client.post(
        "/api/v1/farms", json={"nombre": "Finca Ñandú"}, headers=_auth(token)
    ).json()["id"]
    return token, farm_id


def _animal(client, token, farm_id, tag="GAV-001", gender="HEMBRA"):
    response = client.post(
        "/api/v1/animals",
        json={
            "tag_id": tag,
            "name": "Lucero",
            "gender": gender,
            "birth_date": "2022-03-10",
            "breed": "Holstein",
            "current_weight": 450,
            "farm_id": farm_id,
        },
        headers=_auth(token),
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


# ---------- Sanidad ----------

def test_vaccine_lifecycle_and_status(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    today = date.today()

    cases = [
        (today + timedelta(days=60), "VIGENTE"),
        (today + timedelta(days=5), "PROXIMO_A_VENCER"),
        (None, "VIGENTE"),
    ]
    for next_check, expected in cases:
        created = client.post(
            "/api/v1/health-records",
            json={
                "animal_id": animal_id,
                "record_type": "VACUNA",
                "diagnosis": "Aftosa",
                "dose": "2 ml",
                "next_check_at": next_check.isoformat() if next_check else None,
            },
            headers=_auth(token),
        )
        assert created.status_code == 201, created.text
        body = created.json()
        assert body["status"] == expected
        assert body["animal_tag"] == "GAV-001"
        assert body["veterinarian"] == "Admin"

    past = client.post(
        "/api/v1/health-records",
        json={
            "animal_id": animal_id,
            "record_type": "VACUNA",
            "diagnosis": "Brucelosis",
            "recorded_at": (today - timedelta(days=400)).isoformat(),
            "next_check_at": (today - timedelta(days=35)).isoformat(),
        },
        headers=_auth(token),
    )
    assert past.json()["status"] == "VENCIDO"

    listed = client.get("/api/v1/health-records", headers=_auth(token))
    assert len(listed.json()) == 4

    deleted = client.delete(f"/api/v1/health-records/{past.json()['id']}", headers=_auth(token))
    assert deleted.status_code == 204
    assert len(client.get("/api/v1/health-records", headers=_auth(token)).json()) == 3


def test_treatment_requires_valid_dates(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    response = client.post(
        "/api/v1/health-records",
        json={
            "animal_id": animal_id,
            "record_type": "TRATAMIENTO",
            "diagnosis": "Mastitis",
            "treatment": "Antibiótico",
            "recorded_at": "2026-05-10",
            "next_check_at": "2026-05-01",
        },
        headers=_auth(token),
    )
    assert response.status_code == 422

    ok = client.post(
        "/api/v1/health-records",
        json={
            "animal_id": animal_id,
            "record_type": "TRATAMIENTO",
            "diagnosis": "Mastitis",
            "treatment": "Antibiótico",
            "veterinarian": "Dra. Gómez",
        },
        headers=_auth(token),
    )
    assert ok.json()["status"] == "EN_TRATAMIENTO"
    assert ok.json()["veterinarian"] == "Dra. Gómez"


def test_health_records_are_isolated_between_farms(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    record_id = client.post(
        "/api/v1/health-records",
        json={"animal_id": animal_id, "record_type": "VACUNA", "diagnosis": "Aftosa"},
        headers=_auth(token),
    ).json()["id"]

    other, _ = _admin_farm(client, email="otro@ganadera.com")
    assert client.get("/api/v1/health-records", headers=_auth(other)).json() == []
    assert client.post(
        "/api/v1/health-records",
        json={"animal_id": animal_id, "record_type": "VACUNA", "diagnosis": "Intruso"},
        headers=_auth(other),
    ).status_code == 403
    assert client.delete(
        f"/api/v1/health-records/{record_id}", headers=_auth(other)
    ).status_code == 403


# ---------- Reproducción ----------

def test_pregnancy_computes_expected_birth(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    recorded = date.today() - timedelta(days=10)

    response = client.post(
        "/api/v1/breeding-records",
        json={"animal_id": animal_id, "record_type": "PRENEZ", "recorded_at": recorded.isoformat()},
        headers=_auth(token),
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["expected_at"] == (recorded + timedelta(days=283)).isoformat()
    assert body["status"] == "Gestante, parto en 273 días"

    for record_type in ("CELO", "INSEMINACION", "PARTO"):
        assert client.post(
            "/api/v1/breeding-records",
            json={"animal_id": animal_id, "record_type": record_type, "notes": "Toro 102"},
            headers=_auth(token),
        ).status_code == 201
    assert len(client.get("/api/v1/breeding-records", headers=_auth(token)).json()) == 4


def test_breeding_rejects_males_and_future_dates(client):
    token, farm_id = _admin_farm(client)
    bull = _animal(client, token, farm_id, tag="TORO-1", gender="MACHO")
    cow = _animal(client, token, farm_id, tag="VACA-1")

    assert client.post(
        "/api/v1/breeding-records",
        json={"animal_id": bull, "record_type": "CELO"},
        headers=_auth(token),
    ).status_code == 422
    assert client.post(
        "/api/v1/breeding-records",
        json={
            "animal_id": cow,
            "record_type": "CELO",
            "recorded_at": (date.today() + timedelta(days=3)).isoformat(),
        },
        headers=_auth(token),
    ).status_code == 422


def test_breeding_requires_module_permission(client):
    token, farm_id = _admin_farm(client)
    client.post(
        "/api/v1/users",
        json={
            "nombre": "Campo", "email": "campo@ganadera.com", "password": PASSWORD,
            "role": "MAYORDOMO", "farm_id": farm_id,
        },
        headers=_auth(token),
    )
    worker = client.post(
        "/api/v1/auth/login",
        json={"email": "campo@ganadera.com", "password": PASSWORD},
    ).json()["access_token"]
    # El trabajador de campo no tiene sanidad ni reproducción por defecto.
    assert client.get("/api/v1/breeding-records", headers=_auth(worker)).status_code == 403
    assert client.get("/api/v1/health-records", headers=_auth(worker)).status_code == 403
