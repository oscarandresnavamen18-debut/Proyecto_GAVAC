from datetime import date, timedelta

PASSWORD = "Password123Secure!"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _admin_farm(client):
    token = client.post("/api/v1/auth/register", json={
        "nombre": "Admin", "email": "admin@ganadera.com", "password": PASSWORD}).json()["access_token"]
    farm_id = client.post("/api/v1/farms", json={"nombre": "La Esperanza"},
                          headers=_auth(token)).json()["id"]
    return _auth(token), farm_id


def _animal(client, h, farm_id, tag):
    return client.post("/api/v1/animals", json={
        "tag_id": tag, "gender": "HEMBRA", "birth_date": "2022-01-01", "breed": "Gyr",
        "current_weight": 400, "farm_id": farm_id}, headers=h).json()["id"]


def _seed(client, h, farm_id):
    today = date.today()
    v1, v2, v3 = (_animal(client, h, farm_id, t) for t in ("V-1", "V-2", "V-3"))
    # Vacuna vencida (V-1) y por vencer (V-2); V-3 renovó su vacuna vencida.
    client.post("/api/v1/health-records", json={
        "animal_id": v1, "record_type": "VACUNA", "diagnosis": "Aftosa",
        "recorded_at": (today - timedelta(days=200)).isoformat(),
        "next_check_at": (today - timedelta(days=10)).isoformat()}, headers=h)
    client.post("/api/v1/health-records", json={
        "animal_id": v2, "record_type": "VACUNA", "diagnosis": "Brucelosis",
        "next_check_at": (today + timedelta(days=3)).isoformat()}, headers=h)
    client.post("/api/v1/health-records", json={
        "animal_id": v3, "record_type": "VACUNA", "diagnosis": "Aftosa",
        "recorded_at": (today - timedelta(days=200)).isoformat(),
        "next_check_at": (today - timedelta(days=10)).isoformat()}, headers=h)
    client.post("/api/v1/health-records", json={
        "animal_id": v3, "record_type": "VACUNA", "diagnosis": "aftosa",
        "next_check_at": (today + timedelta(days=180)).isoformat()}, headers=h)
    # Parto vencido (V-1) y próximo (V-2).
    client.post("/api/v1/breeding-records", json={
        "animal_id": v1, "record_type": "PRENEZ",
        "recorded_at": (today - timedelta(days=290)).isoformat()}, headers=h)
    client.post("/api/v1/breeding-records", json={
        "animal_id": v2, "record_type": "PRENEZ",
        "recorded_at": (today - timedelta(days=270)).isoformat()}, headers=h)
    # Insumo bajo el mínimo y uno con existencia suficiente.
    client.post("/api/v1/inventory", json={"name": "Sal", "quantity": 5, "minimum_quantity": 10,
                                           "unit": "kg"}, headers=h)
    client.post("/api/v1/inventory", json={"name": "Melaza", "quantity": 50, "minimum_quantity": 10},
                headers=h)
    return v1, v2, v3


def test_alerts_cover_vaccines_births_and_inventory(client):
    h, farm_id = _admin_farm(client)
    _seed(client, h, farm_id)

    alerts = client.get("/api/v1/alerts", headers=h).json()
    summary = [(a["tipo"], a["severidad"], a["modulo"]) for a in alerts]
    assert summary == [
        ("VACUNA_VENCIDA", "ALTA", "sanidad"),
        ("PARTO_VENCIDO", "ALTA", "reproduccion"),
        # Dentro de cada gravedad, lo más urgente primero: el insumo es de hoy.
        ("INSUMO_BAJO_MINIMO", "MEDIA", "insumos"),
        ("VACUNA_POR_VENCER", "MEDIA", "sanidad"),
        ("PARTO_PROXIMO", "MEDIA", "reproduccion"),
    ]
    assert alerts[0]["titulo"] == "Vacuna vencida: Aftosa · V-1"
    assert "hace 10 días" in alerts[0]["detalle"]
    assert alerts[2]["detalle"] == "Quedan 5 kg; el mínimo es 10."
    assert "en 3 días" in alerts[3]["detalle"]
    # El resumen del inicio cuenta las mismas alertas de vacunas e insumos.
    dashboard = client.get("/api/v1/dashboard", headers=h).json()
    assert dashboard["alertas"] == 3


def test_alerts_disappear_when_resolved_or_animal_leaves(client):
    h, farm_id = _admin_farm(client)
    v1, v2, _ = _seed(client, h, farm_id)

    # Registrar el parto resuelve la alarma; vender el animal quita las suyas.
    client.post("/api/v1/breeding-records", json={"animal_id": v1, "record_type": "PARTO"}, headers=h)
    client.post("/api/v1/exits", json={"animal_id": v2, "tipo": "VENTA"}, headers=h)

    tipos = [a["tipo"] for a in client.get("/api/v1/alerts", headers=h).json()]
    assert tipos == ["VACUNA_VENCIDA", "INSUMO_BAJO_MINIMO"]


def test_alerts_only_include_permitted_modules(client):
    h, farm_id = _admin_farm(client)
    _seed(client, h, farm_id)
    client.post("/api/v1/users", json={
        "nombre": "Campo", "email": "campo@ganadera.com", "password": PASSWORD,
        "role": "MAYORDOMO", "farm_id": farm_id}, headers=h)
    worker = client.post("/api/v1/auth/login", json={
        "email": "campo@ganadera.com", "password": PASSWORD}).json()["access_token"]

    # El trabajador de campo tiene insumos, pero no sanidad ni reproducción.
    modules = {a["modulo"] for a in client.get("/api/v1/alerts", headers=_auth(worker)).json()}
    assert modules == {"insumos"}


def test_no_farm_means_no_alerts(client):
    token = client.post("/api/v1/auth/register", json={
        "nombre": "Nuevo", "email": "nuevo@ganadera.com", "password": PASSWORD}).json()["access_token"]
    assert client.get("/api/v1/alerts", headers=_auth(token)).json() == []
