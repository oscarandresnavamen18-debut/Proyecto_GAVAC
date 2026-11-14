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

    # El administrador puede tener varias fincas; la primera queda como activa.
    farm2_res = client.post("/api/v1/farms", json={"nombre": "Finca La Segunda"}, headers=headers)
    assert farm2_res.status_code == 201
    farm2_id = farm2_res.json()["id"]

    list_res = client.get("/api/v1/farms", headers=headers)
    assert list_res.status_code == 200
    assert [farm["id"] for farm in list_res.json()] == [farm_id, farm2_id]
    assert client.get("/api/v1/auth/me", headers=headers).json()["farm_id"] == farm_id
