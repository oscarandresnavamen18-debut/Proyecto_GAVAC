from datetime import datetime, timezone


def _register(client, email):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "nombre": "Usuario Test",
            "email": email,
            "password": "clave-segura-123",
        },
    )
    assert response.status_code == 201
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _create_farm_and_animal(client, headers, tag="VACA-001"):
    farm_response = client.post(
        "/api/v1/farms",
        json={"nombre": "Finca de Prueba"},
        headers=headers,
    )
    assert farm_response.status_code == 201
    farm_id = farm_response.json()["id"]
    animal_response = client.post(
        "/api/v1/animals",
        json={
            "farm_id": farm_id,
            "tag_id": tag,
            "gender": "HEMBRA",
            "birth_date": "2022-01-01",
            "breed": "Holstein",
            "current_weight": 400,
        },
        headers=headers,
    )
    assert animal_response.status_code == 201
    return farm_id, animal_response.json()


def test_inventory_create_list_deactivate_and_isolate_farms(client):
    owner_headers = _register(client, "inventory-owner@example.com")
    other_headers = _register(client, "inventory-other@example.com")
    _create_farm_and_animal(client, owner_headers)
    _create_farm_and_animal(client, other_headers, "VACA-002")

    created = client.post(
        "/api/v1/inventory",
        json={
            "name": "Sal mineral",
            "category": "Alimento",
            "unit": "kg",
            "quantity": 12.5,
            "minimum_quantity": 2,
        },
        headers=owner_headers,
    )
    assert created.status_code == 201
    item = created.json()
    assert item["name"] == "Sal mineral"
    assert item["category"] == "ALIMENTO"
    assert item["quantity"] == 12.5

    listed = client.get("/api/v1/inventory", headers=owner_headers)
    assert listed.status_code == 200
    assert [row["id"] for row in listed.json()] == [item["id"]]
    assert client.get("/api/v1/inventory", headers=other_headers).json() == []

    forbidden = client.delete(
        f"/api/v1/inventory/{item['id']}",
        headers=other_headers,
    )
    assert forbidden.status_code == 403

    deactivated = client.delete(
        f"/api/v1/inventory/{item['id']}",
        headers=owner_headers,
    )
    assert deactivated.status_code == 204
    assert client.get("/api/v1/inventory", headers=owner_headers).json() == []


def test_production_create_list_delete_and_isolate_farms(client):
    owner_headers = _register(client, "production-owner@example.com")
    other_headers = _register(client, "production-other@example.com")
    _, animal = _create_farm_and_animal(client, owner_headers, "VACA-003")
    _create_farm_and_animal(client, other_headers, "VACA-004")

    created = client.post(
        "/api/v1/production",
        json={
            "animal_id": animal["id"],
            "milk_liters": 18.5,
            "weight_kg": 420,
            "recorded_at": datetime(2026, 11, 10, tzinfo=timezone.utc).isoformat(),
        },
        headers=owner_headers,
    )
    assert created.status_code == 201
    records = created.json()
    assert [(row["record_type"], row["quantity"], row["unit"]) for row in records] == [
        ("MILK", 18.5, "L"),
        ("WEIGHT", 420, "kg"),
    ]

    listed = client.get("/api/v1/production", headers=owner_headers)
    assert listed.status_code == 200
    assert len(listed.json()) == 2
    assert listed.json()[0]["animal_tag"] == "VACA-003"
    assert client.get("/api/v1/production", headers=other_headers).json() == []

    forbidden = client.delete(
        f"/api/v1/production/{records[0]['id']}",
        headers=other_headers,
    )
    assert forbidden.status_code == 403

    deleted = client.delete(
        f"/api/v1/production/{records[0]['id']}",
        headers=owner_headers,
    )
    assert deleted.status_code == 204
    assert len(client.get("/api/v1/production", headers=owner_headers).json()) == 1


def test_production_requires_at_least_one_measurement(client):
    headers = _register(client, "production-empty@example.com")
    _, animal = _create_farm_and_animal(client, headers, "VACA-005")

    response = client.post(
        "/api/v1/production",
        json={"animal_id": animal["id"]},
        headers=headers,
    )
    assert response.status_code == 422
