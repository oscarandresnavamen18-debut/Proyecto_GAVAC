def test_multi_tenant_isolation(client):
    # User 1 & Farm 1
    t1 = client.post(
        "/api/v1/auth/register",
        json={"nombre": "User 1", "email": "u1@test.com", "password": "Password123Secure!"},
    ).json()["access_token"]
    h1 = {"Authorization": f"Bearer {t1}"}
    f1_id = client.post("/api/v1/farms", json={"nombre": "Finca 1"}, headers=h1).json()["id"]
    a1_id = client.post(
        "/api/v1/animals",
        json={
            "farm_id": f1_id,
            "tag_id": "F1-A1",
            "gender": "HEMBRA",
            "birth_date": "2023-01-01",
            "breed": "Angus",
            "current_weight": 380.0,
        },
        headers=h1,
    ).json()["id"]

    # User 2 & Farm 2
    t2 = client.post(
        "/api/v1/auth/register",
        json={"nombre": "User 2", "email": "u2@test.com", "password": "Password123Secure!"},
    ).json()["access_token"]
    h2 = {"Authorization": f"Bearer {t2}"}
    f2_id = client.post("/api/v1/farms", json={"nombre": "Finca 2"}, headers=h2).json()["id"]

    # User 2 intenta acceder al animal de User 1 -> 403 Prohibido
    access_res = client.get(f"/api/v1/animals/{a1_id}", headers=h2)
    assert access_res.status_code == 403

    # User 2 intenta crear animal en la finca de User 1 -> 403 Prohibido
    create_res = client.post(
        "/api/v1/animals",
        json={
            "farm_id": f1_id,
            "tag_id": "HACK-01",
            "gender": "MACHO",
            "birth_date": "2023-01-01",
            "breed": "Angus",
            "current_weight": 380.0,
        },
        headers=h2,
    )
    assert create_res.status_code == 403
