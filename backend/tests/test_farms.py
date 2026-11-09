def test_farm_lifecycle(client):
    reg_res = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Oscar Navarro", "email": "oscar@ganadera.com", "password": "Password123Secure!"},
    )
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    farm_res = client.post(
        "/api/v1/farms",
        json={"nombre": "Finca La Esperanza", "ubicacion": "Antioquia"},
        headers=headers,
    )
    assert farm_res.status_code == 201
    farm_id = farm_res.json()["id"]

    farm2_res = client.post("/api/v1/farms", json={"nombre": "Finca La Segunda"}, headers=headers)
    assert farm2_res.status_code == 403

    list_res = client.get("/api/v1/farms", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) == 1
    assert list_res.json()[0]["id"] == farm_id
