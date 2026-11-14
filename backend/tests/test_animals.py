def test_animal_crud(client):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "User 1", "email": "u1@ganadera.com", "password": "Password123Secure!"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    farm_id = client.post("/api/v1/farms", json={"nombre": "Finca Central"}, headers=headers).json()["id"]

    animal_res = client.post(
        "/api/v1/animals",
        json={
            "farm_id": farm_id,
            "tag_id": "CO-101",
            "name": "Mariposa",
            "gender": "HEMBRA",
            "birth_date": "2023-05-10",
            "breed": "Holstein",
            "color": "Blanco y Negro",
            "current_weight": 450.0,
            "status": "ACTIVO",
        },
        headers=headers,
    )
    assert animal_res.status_code == 201
    animal_id = animal_res.json()["id"]

    dup_res = client.post(
        "/api/v1/animals",
        json={
            "farm_id": farm_id,
            "tag_id": "CO-101",
            "name": "Otra Mariposa",
            "gender": "HEMBRA",
            "birth_date": "2023-05-10",
            "breed": "Holstein",
            "current_weight": 400.0,
        },
        headers=headers,
    )
    assert dup_res.status_code == 409

    get_res = client.get(f"/api/v1/animals/{animal_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["tag_id"] == "CO-101"

    patch_res = client.patch(f"/api/v1/animals/{animal_id}", json={"status": "VENDIDO"}, headers=headers)
    assert patch_res.status_code == 200
    assert patch_res.json()["status"] == "VENDIDO"


def _admin_animal(client):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Admin", "email": "editor@ganadera.com", "password": "Password123Secure!"},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    farm_id = client.post("/api/v1/farms", json={"nombre": "Finca"}, headers=headers).json()["id"]
    base = {"gender": "HEMBRA", "birth_date": "2022-01-01", "breed": "Holstein",
            "current_weight": 300, "farm_id": farm_id}
    first = client.post("/api/v1/animals", json={**base, "tag_id": "ED-1"}, headers=headers).json()
    client.post("/api/v1/animals", json={**base, "tag_id": "ED-2"}, headers=headers)
    return headers, first


def test_update_animal_core_fields(client):
    headers, animal = _admin_animal(client)
    response = client.patch(
        f"/api/v1/animals/{animal['id']}",
        json={"tag_id": " ED-9 ", "breed": "Gyr", "gender": "MACHO",
              "birth_date": "2021-05-05", "current_weight": 230},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert (body["tag_id"], body["breed"], body["gender"]) == ("ED-9", "Gyr", "MACHO")
    assert (body["birth_date"], body["current_weight"]) == ("2021-05-05", 230)


def test_update_animal_rejects_duplicate_tag(client):
    headers, animal = _admin_animal(client)
    response = client.patch(
        f"/api/v1/animals/{animal['id']}", json={"tag_id": "ED-2"}, headers=headers
    )
    assert response.status_code == 409


def test_deleted_animal_keeps_history_but_leaves_listing(client):
    headers, animal = _admin_animal(client)
    client.post(
        "/api/v1/health-records",
        json={"animal_id": animal["id"], "record_type": "VACUNA", "diagnosis": "Aftosa"},
        headers=headers,
    )
    assert client.delete(f"/api/v1/animals/{animal['id']}", headers=headers).status_code == 204

    tags = [a["tag_id"] for a in client.get("/api/v1/animals", headers=headers).json()]
    assert tags == ["ED-2"]
    assert len(client.get("/api/v1/health-records", headers=headers).json()) == 1
    assert client.patch(
        f"/api/v1/animals/{animal['id']}", json={"current_weight": 1}, headers=headers
    ).status_code == 404
