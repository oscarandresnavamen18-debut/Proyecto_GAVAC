from io import BytesIO

from openpyxl import load_workbook

PASSWORD = "Password123Secure!"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _admin_farm(client, email="admin@ganadera.com"):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Admin", "email": email, "password": PASSWORD},
    ).json()["access_token"]
    farm_id = client.post("/api/v1/farms", json={"nombre": "La Esperanza"},
                          headers=_auth(token)).json()["id"]
    return _auth(token), farm_id


def _lot(client, h, name):
    response = client.post("/api/v1/lots", json={"nombre": name, "area_hectareas": 4.5}, headers=h)
    assert response.status_code == 201, response.text
    return response.json()["id"]


def _animal(client, h, farm_id, tag, lote_id=None, gender="HEMBRA"):
    response = client.post("/api/v1/animals", json={
        "tag_id": tag, "gender": gender, "birth_date": "2022-01-01", "breed": "Gyr",
        "current_weight": 400, "farm_id": farm_id, "lote_id": lote_id}, headers=h)
    assert response.status_code == 201, response.text
    return response.json()["id"]


def _counts(client, h):
    return {lot["name"]: lot["animal_count"] for lot in client.get("/api/v1/lots", headers=h).json()}


# ---------- Potreros ----------

def test_lots_track_animals_and_movement_history(client):
    h, farm_id = _admin_farm(client)
    norte, sur = _lot(client, h, "Potrero Norte"), _lot(client, h, "Potrero Sur")
    assert client.post("/api/v1/lots", json={"nombre": "Potrero Norte"}, headers=h).status_code == 409

    a1 = _animal(client, h, farm_id, "V-1", lote_id=norte)
    a2 = _animal(client, h, farm_id, "V-2", lote_id=norte)
    _animal(client, h, farm_id, "V-3")
    assert client.get(f"/api/v1/animals/{a1}", headers=h).json()["lote_id"] == norte
    assert _counts(client, h) == {"Potrero Norte": 2, "Potrero Sur": 0}

    # No se acepta una fecha anterior a la entrada al potrero ni una fecha futura.
    for bad_date in ("2020-01-01", "2999-01-01"):
        assert client.post("/api/v1/lots/move", json={
            "animal_ids": [a1], "lote_destino_id": sur, "fecha": bad_date}, headers=h).status_code == 422
    moved = client.post("/api/v1/lots/move", json={
        "animal_ids": [a1, a2], "lote_destino_id": sur, "notas": "Rotación de pastos"}, headers=h)
    assert moved.status_code == 201, moved.text
    assert {(m["animal_tag"], m["from_lot_name"], m["to_lot_name"]) for m in moved.json()} == {
        ("V-1", "Potrero Norte", "Potrero Sur"), ("V-2", "Potrero Norte", "Potrero Sur")}
    assert _counts(client, h) == {"Potrero Norte": 0, "Potrero Sur": 2}

    # Mover al potrero donde ya está no genera movimiento.
    again = client.post("/api/v1/lots/move", json={"animal_ids": [a1], "lote_destino_id": sur}, headers=h)
    assert again.json() == []

    history = client.get(f"/api/v1/lots/movements?animal_id={a1}", headers=h).json()
    assert [(m["from_lot_name"], m["to_lot_name"]) for m in history] == [
        ("Potrero Norte", "Potrero Sur"), (None, "Potrero Norte")]
    assert history[0]["notes"] == "Rotación de pastos"
    assert history[1]["notes"] == "Ingreso al potrero"
    assert history[0]["created_by_name"] == "Admin"


def test_lot_with_animals_cannot_be_deactivated(client):
    h, farm_id = _admin_farm(client)
    norte = _lot(client, h, "Norte")
    animal = _animal(client, h, farm_id, "V-1", lote_id=norte)

    assert client.patch(f"/api/v1/lots/{norte}", json={"is_active": False}, headers=h).status_code == 409
    client.post("/api/v1/lots/move", json={"animal_ids": [animal], "lote_destino_id": None}, headers=h)
    assert client.get(f"/api/v1/animals/{animal}", headers=h).json()["lote_id"] is None
    assert client.patch(f"/api/v1/lots/{norte}", json={"is_active": False}, headers=h).status_code == 200
    assert _counts(client, h) == {}
    # Un potrero inactivo no recibe animales.
    assert client.post("/api/v1/lots/move", json={"animal_ids": [animal], "lote_destino_id": norte},
                       headers=h).status_code == 404


def test_lots_are_isolated_and_require_registro_permission(client):
    h, farm_id = _admin_farm(client)
    norte = _lot(client, h, "Norte")
    animal = _animal(client, h, farm_id, "V-1")
    other, _ = _admin_farm(client, email="otro@ganadera.com")

    assert client.get("/api/v1/lots", headers=other).json() == []
    assert client.post("/api/v1/lots/move", json={"animal_ids": [animal], "lote_destino_id": norte},
                       headers=other).status_code == 404

    client.post("/api/v1/users", json={
        "nombre": "Vet", "email": "vet@ganadera.com", "password": PASSWORD, "role": "VETERINARIO",
        "farm_id": farm_id, "permisos": ["sanidad"]}, headers=h)
    vet = client.post("/api/v1/auth/login", json={"email": "vet@ganadera.com", "password": PASSWORD})
    assert client.get("/api/v1/lots", headers=_auth(vet.json()["access_token"])).status_code == 403


# ---------- Salidas ----------

def test_sale_removes_animal_from_active_inventory(client):
    h, farm_id = _admin_farm(client)
    norte = _lot(client, h, "Norte")
    sold = _animal(client, h, farm_id, "V-1", lote_id=norte)
    _animal(client, h, farm_id, "V-2", lote_id=norte)

    response = client.post("/api/v1/exits", json={
        "animal_id": sold, "tipo": "VENTA", "fecha": "2026-11-12", "precio": 3500000,
        "comprador": "Subasta Ganadera del Meta"}, headers=h)
    assert response.status_code == 201, response.text
    body = response.json()
    assert (body["exit_type"], body["price"], body["buyer"], body["lot_name"]) == (
        "VENTA", 3500000, "Subasta Ganadera del Meta", "Norte")

    # Sale del inventario activo, del potrero y del resumen; su ficha sigue disponible.
    active = [a["tag_id"] for a in client.get("/api/v1/animals", headers=h).json()]
    every = {a["tag_id"]: a["status"] for a in client.get("/api/v1/animals?estado=todos", headers=h).json()}
    assert active == ["V-2"]
    assert every == {"V-1": "VENDIDO", "V-2": "ACTIVO"}
    assert _counts(client, h) == {"Norte": 1}
    assert client.get("/api/v1/dashboard", headers=h).json()["total_animales"] == 1

    # No recibe registros nuevos ni se puede mover ni vender otra vez.
    assert client.post("/api/v1/health-records", json={
        "animal_id": sold, "record_type": "VACUNA", "diagnosis": "Aftosa"}, headers=h).status_code == 422
    assert client.post("/api/v1/production", json={"animal_id": sold, "milk_liters": 10},
                       headers=h).status_code == 422
    assert client.post("/api/v1/lots/move", json={"animal_ids": [sold], "lote_destino_id": norte},
                       headers=h).status_code == 422
    assert client.post("/api/v1/exits", json={"animal_id": sold, "tipo": "MUERTE", "causa": "x"},
                       headers=h).status_code == 409


def test_death_requires_cause_and_exit_can_be_cancelled(client):
    h, farm_id = _admin_farm(client)
    norte = _lot(client, h, "Norte")
    animal = _animal(client, h, farm_id, "V-1", lote_id=norte)

    assert client.post("/api/v1/exits", json={"animal_id": animal, "tipo": "MUERTE"},
                       headers=h).status_code == 422
    death = client.post("/api/v1/exits", json={
        "animal_id": animal, "tipo": "MUERTE", "causa": "Picadura de serpiente",
        "precio": 999}, headers=h).json()
    assert (death["cause"], death["price"]) == ("Picadura de serpiente", None)
    assert [e["exit_type"] for e in client.get("/api/v1/exits?tipo=MUERTE", headers=h).json()] == ["MUERTE"]

    # Anular por error: vuelve a estar activo y en su potrero.
    assert client.delete(f"/api/v1/exits/{death['id']}", headers=h).status_code == 204
    restored = client.get(f"/api/v1/animals/{animal}", headers=h).json()
    assert (restored["status"], restored["lote_id"]) == ("ACTIVO", norte)
    assert client.get("/api/v1/exits", headers=h).json() == []


def test_exit_and_lot_reports(client):
    h, farm_id = _admin_farm(client)
    norte = _lot(client, h, "Norte")
    sold = _animal(client, h, farm_id, "V-1", lote_id=norte)
    _animal(client, h, farm_id, "V-2", lote_id=norte)
    client.post("/api/v1/exits", json={"animal_id": sold, "tipo": "VENTA", "precio": 2000000},
                headers=h)

    def summary(report):
        sheet = load_workbook(BytesIO(client.get(
            f"/api/v1/reports/{report}?formato=xlsx", headers=h).content)).active
        rows = [[c.value for c in row] for row in sheet.iter_rows(max_col=2)]
        start = next(i for i, r in enumerate(rows) if r[0] == "Resumen")
        out = {}
        for label, value in rows[start + 1:]:
            if label is None:
                break
            out[label] = value
        return out

    exits = summary("salidas")
    assert (exits["Ventas"], exits["Total vendido"], exits["Muertes"]) == ("1", "$ 2.000.000", "0")
    lots = summary("potreros")
    assert lots["Potreros activos"] == "1"
    assert lots["Animales por potrero"] == "Norte: 1"
    animals = summary("animales")
    assert (animals["Animales en la finca"], animals["Vendidos"]) == ("1", "1")
    for report in ("salidas", "potreros"):
        pdf = client.get(f"/api/v1/reports/{report}?formato=pdf", headers=h)
        assert pdf.status_code == 200 and pdf.content.startswith(b"%PDF")
