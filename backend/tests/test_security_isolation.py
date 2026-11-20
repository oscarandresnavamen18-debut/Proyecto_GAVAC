def _register(client, name, email):
    response = client.post(
        "/api/v1/auth/register",
        json={"nombre": name, "email": email, "password": "Password123Secure!"},
    )
    assert response.status_code == 201
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _create_farm(client, headers, name):
    response = client.post(
        "/api/v1/farms",
        json={"nombre": name},
        headers=headers,
    )
    assert response.status_code == 201
    return response.json()


def _create_animal(client, headers, farm_id, tag_id):
    response = client.post(
        "/api/v1/animals",
        json={
            "farm_id": farm_id,
            "tag_id": tag_id,
            "gender": "HEMBRA",
            "birth_date": "2023-01-01",
            "breed": "Angus",
            "current_weight": 380.0,
        },
        headers=headers,
    )
    assert response.status_code == 201
    return response.json()


def _create_event(client, headers, animal_id, description):
    response = client.post(
        f"/api/v1/animals/{animal_id}/events",
        json={
            "event_type": "VACUNACION",
            "event_date": "2026-03-01",
            "description": description,
        },
        headers=headers,
    )
    assert response.status_code == 201
    return response.json()


def test_complete_farm_workflow_and_multi_tenant_isolation(client):
    owner_headers = _register(client, "User 1", "u1@test.com")
    other_headers = _register(client, "User 2", "u2@test.com")

    owner_farm = _create_farm(client, owner_headers, "Finca 1")
    owner_animal = _create_animal(client, owner_headers, owner_farm["id"], "F1-A1")
    owner_event = _create_event(
        client, owner_headers, owner_animal["id"], "Vacuna de prueba"
    )
    other_farm = _create_farm(client, other_headers, "Finca 2")
    other_animal = _create_animal(client, other_headers, other_farm["id"], "F2-A1")
    _create_event(client, other_headers, other_animal["id"], "Vacuna propia")

    # Collection endpoints only return records belonging to the signed-in user.
    assert [farm["id"] for farm in client.get(
        "/api/v1/farms", headers=owner_headers
    ).json()] == [owner_farm["id"]]
    assert [animal["id"] for animal in client.get(
        "/api/v1/animals", headers=owner_headers
    ).json()] == [owner_animal["id"]]
    assert [farm["id"] for farm in client.get(
        "/api/v1/farms", headers=other_headers
    ).json()] == [other_farm["id"]]
    assert [animal["id"] for animal in client.get(
        "/api/v1/animals", headers=other_headers
    ).json()] == [other_animal["id"]]

    assert client.get(
        f"/api/v1/farms/{owner_farm['id']}", headers=owner_headers
    ).status_code == 200
    assert client.get(
        f"/api/v1/animals/{owner_animal['id']}", headers=owner_headers
    ).status_code == 200
    update_response = client.patch(
        f"/api/v1/animals/{owner_animal['id']}",
        json={"current_weight": 390.0},
        headers=owner_headers,
    )
    assert update_response.status_code == 200
    assert update_response.json()["current_weight"] == 390.0
    events_response = client.get(
        f"/api/v1/animals/{owner_animal['id']}/events",
        headers=owner_headers,
    )
    assert events_response.status_code == 200
    assert [event["id"] for event in events_response.json()] == [owner_event["id"]]
    summary_response = client.get(
        f"/api/v1/farms/{owner_farm['id']}/summary",
        headers=owner_headers,
    )
    assert summary_response.status_code == 200
    assert summary_response.json() == {
        "farm_id": owner_farm["id"],
        "total_animales": 1,
        "por_estado": {"ACTIVO": 1},
        "total_eventos": 1,
    }

    assert client.get(
        f"/api/v1/farms/{owner_farm['id']}", headers=other_headers
    ).status_code == 403
    assert client.get(
        f"/api/v1/farms/{owner_farm['id']}/summary", headers=other_headers
    ).status_code == 403
    assert client.get(
        f"/api/v1/animals/{owner_animal['id']}", headers=other_headers
    ).status_code == 403
    assert client.patch(
        f"/api/v1/animals/{owner_animal['id']}",
        json={"current_weight": 999.0},
        headers=other_headers,
    ).status_code == 403
    assert client.post(
        "/api/v1/animals",
        json={
            "farm_id": owner_farm["id"],
            "tag_id": "HACK-01",
            "gender": "HEMBRA",
            "birth_date": "2023-01-01",
            "breed": "Angus",
            "current_weight": 380.0,
        },
        headers=other_headers,
    ).status_code == 403
    assert client.get(
        f"/api/v1/animals/{owner_animal['id']}/events",
        headers=other_headers,
    ).status_code == 403
    assert client.post(
        f"/api/v1/animals/{owner_animal['id']}/events",
        json={
            "event_type": "TRATAMIENTO",
            "event_date": "2026-03-02",
            "description": "Intento de tratamiento no autorizado",
        },
        headers=other_headers,
    ).status_code == 403
    assert client.delete(
        f"/api/v1/animals/{owner_animal['id']}",
        headers=other_headers,
    ).status_code == 403
    assert client.delete(
        f"/api/v1/animals/{owner_animal['id']}/events/{owner_event['id']}",
        headers=other_headers,
    ).status_code == 403

    assert client.get(
        f"/api/v1/animals/{owner_animal['id']}", headers=owner_headers
    ).json()["current_weight"] == 390.0
    assert len(client.get(
        f"/api/v1/animals/{owner_animal['id']}/events",
        headers=owner_headers,
    ).json()) == 1
