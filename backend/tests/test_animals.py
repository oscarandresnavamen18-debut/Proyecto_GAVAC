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
