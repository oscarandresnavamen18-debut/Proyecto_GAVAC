from datetime import date, timedelta

PASSWORD = "Password123Secure!"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _admin_farm(client):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Admin", "email": "admin@ganadera.com", "password": PASSWORD},
    ).json()["access_token"]
    farm_id = client.post(
        "/api/v1/farms", json={"nombre": "La Esperanza"}, headers=_auth(token)
    ).json()["id"]
    return token, farm_id


def _animal(client, token, farm_id, tag, gender="HEMBRA", weight=400):
    return client.post(
        "/api/v1/animals",
        json={"tag_id": tag, "gender": gender, "birth_date": "2022-01-01",
              "breed": "Holstein", "current_weight": weight, "farm_id": farm_id},
        headers=_auth(token),
    ).json()["id"]


def test_dashboard_without_farm_is_empty(client):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Nuevo", "email": "nuevo@ganadera.com", "password": PASSWORD},
    ).json()["access_token"]
    body = client.get("/api/v1/dashboard", headers=_auth(token)).json()
    assert body["farm_id"] is None
    assert body["total_animales"] == 0
    assert body["alertas"] == 0


def test_dashboard_summarizes_every_module(client):
    token, farm_id = _admin_farm(client)
    h = _auth(token)
    today = date.today()
    lucero = _animal(client, token, farm_id, "V-1", weight=400)
    canela = _animal(client, token, farm_id, "V-2", weight=500)
    _animal(client, token, farm_id, "T-1", gender="MACHO", weight=600)
    removed = _animal(client, token, farm_id, "V-9")

    # Tratamiento activo en una vaca.
    client.post("/api/v1/health-records", json={
        "animal_id": canela, "record_type": "TRATAMIENTO", "diagnosis": "Mastitis",
        "treatment": "Antibiótico"}, headers=h)
    # Vacuna vencida y luego renovada: no debe contar como alerta.
    client.post("/api/v1/health-records", json={
        "animal_id": lucero, "record_type": "VACUNA", "diagnosis": "Aftosa",
        "recorded_at": (today - timedelta(days=400)).isoformat(),
        "next_check_at": (today - timedelta(days=30)).isoformat()}, headers=h)
    client.post("/api/v1/health-records", json={
        "animal_id": lucero, "record_type": "VACUNA", "diagnosis": "aftosa",
        "next_check_at": (today + timedelta(days=180)).isoformat()}, headers=h)
    # Vacuna por vencer: sí es alerta.
    client.post("/api/v1/health-records", json={
        "animal_id": canela, "record_type": "VACUNA", "diagnosis": "Brucelosis",
        "next_check_at": (today + timedelta(days=5)).isoformat()}, headers=h)

    # Lucero gestante con parto próximo; Canela ya parió (no cuenta).
    client.post("/api/v1/breeding-records", json={
        "animal_id": lucero, "record_type": "PRENEZ",
        "recorded_at": (today - timedelta(days=270)).isoformat()}, headers=h)
    client.post("/api/v1/breeding-records", json={
        "animal_id": canela, "record_type": "PRENEZ",
        "recorded_at": (today - timedelta(days=300)).isoformat()}, headers=h)
    client.post("/api/v1/breeding-records", json={
        "animal_id": canela, "record_type": "PARTO",
        "recorded_at": (today - timedelta(days=10)).isoformat()}, headers=h)

    for liters in (18, 22):
        client.post("/api/v1/production", json={"animal_id": lucero, "milk_liters": liters},
                    headers=h)
    client.post("/api/v1/inventory", json={"name": "Sal", "quantity": 5, "minimum_quantity": 10},
                headers=h)

    # Un animal eliminado no cuenta.
    client.post("/api/v1/health-records", json={
        "animal_id": removed, "record_type": "TRATAMIENTO", "diagnosis": "Cojera",
        "treatment": "Antiinflamatorio"}, headers=h)
    client.delete(f"/api/v1/animals/{removed}", headers=h)

    body = client.get("/api/v1/dashboard", headers=h).json()
    assert body["farm_id"] == farm_id and body["farm_name"] == "La Esperanza"
    assert (body["total_animales"], body["hembras"], body["machos"]) == (3, 2, 1)
    assert body["peso_promedio_kg"] == 500
    assert body["animales_en_tratamiento"] == 1
    assert (body["vacunas_por_vencer"], body["vacunas_vencidas"]) == (1, 0)
    assert (body["vacas_gestantes"], body["partos_proximos"]) == (1, 1)
    assert body["leche_litros_30_dias"] == 40
    assert body["leche_promedio_ordeno"] == 20
    assert body["insumos_bajo_minimo"] == 1
    assert body["alertas"] == 2


def test_dashboard_is_available_without_module_permissions(client):
    token, farm_id = _admin_farm(client)
    _animal(client, token, farm_id, "V-1")
    client.post("/api/v1/users", json={
        "nombre": "Campo", "email": "campo@ganadera.com", "password": PASSWORD,
        "role": "MAYORDOMO", "farm_id": farm_id, "permisos": []}, headers=_auth(token))
    worker = client.post(
        "/api/v1/auth/login", json={"email": "campo@ganadera.com", "password": PASSWORD}
    ).json()["access_token"]

    assert client.get("/api/v1/health-records", headers=_auth(worker)).status_code == 403
    body = client.get("/api/v1/dashboard", headers=_auth(worker)).json()
    assert body["total_animales"] == 1
