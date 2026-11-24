from datetime import date, timedelta
from io import BytesIO

import pytest
from openpyxl import load_workbook

PASSWORD = "Password123Secure!"


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _table(sheet):
    """Encabezados y filas de datos de una hoja (la tabla va después del resumen)."""
    rows = [[c.value for c in row] for row in sheet.iter_rows()]
    header = next(i for i, r in enumerate(rows) if r[0] in (
        "Chapeta", "Aplicación", "Fecha", "Insumo"))
    return rows[header], [r for r in rows[header + 1:] if r[0] is not None]


def _summary(sheet):
    rows = [[c.value for c in row] for row in sheet.iter_rows(max_col=2)]
    start = next(i for i, r in enumerate(rows) if r[0] == "Resumen")
    result = {}
    for label, value in rows[start + 1:]:
        if label is None:
            break
        result[label] = value
    return result


def _admin_farm(client, email="admin@ganadera.com"):
    token = client.post(
        "/api/v1/auth/register",
        json={"nombre": "Admin", "email": email, "password": PASSWORD},
    ).json()["access_token"]
    farm_id = client.post(
        "/api/v1/farms", json={"nombre": "Finca Ñandú"}, headers=_auth(token)
    ).json()["id"]
    return token, farm_id


def _animal(client, token, farm_id, tag="GAV-001", gender="HEMBRA"):
    response = client.post(
        "/api/v1/animals",
        json={
            "tag_id": tag,
            "name": "Lucero",
            "gender": gender,
            "birth_date": "2022-03-10",
            "breed": "Holstein",
            "current_weight": 450,
            "farm_id": farm_id,
        },
        headers=_auth(token),
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


# ---------- Sanidad ----------

def test_vaccine_lifecycle_and_status(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    today = date.today()

    cases = [
        (today + timedelta(days=60), "VIGENTE"),
        (today + timedelta(days=5), "PROXIMO_A_VENCER"),
        (None, "VIGENTE"),
    ]
    for next_check, expected in cases:
        created = client.post(
            "/api/v1/health-records",
            json={
                "animal_id": animal_id,
                "record_type": "VACUNA",
                "diagnosis": "Aftosa",
                "dose": "2 ml",
                "next_check_at": next_check.isoformat() if next_check else None,
            },
            headers=_auth(token),
        )
        assert created.status_code == 201, created.text
        body = created.json()
        assert body["status"] == expected
        assert body["animal_tag"] == "GAV-001"
        assert body["veterinarian"] == "Admin"

    past = client.post(
        "/api/v1/health-records",
        json={
            "animal_id": animal_id,
            "record_type": "VACUNA",
            "diagnosis": "Brucelosis",
            "recorded_at": (today - timedelta(days=400)).isoformat(),
            "next_check_at": (today - timedelta(days=35)).isoformat(),
        },
        headers=_auth(token),
    )
    assert past.json()["status"] == "VENCIDO"

    listed = client.get("/api/v1/health-records", headers=_auth(token))
    assert len(listed.json()) == 4

    deleted = client.delete(f"/api/v1/health-records/{past.json()['id']}", headers=_auth(token))
    assert deleted.status_code == 204
    assert len(client.get("/api/v1/health-records", headers=_auth(token)).json()) == 3


def test_treatment_requires_valid_dates(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    response = client.post(
        "/api/v1/health-records",
        json={
            "animal_id": animal_id,
            "record_type": "TRATAMIENTO",
            "diagnosis": "Mastitis",
            "treatment": "Antibiótico",
            "recorded_at": "2026-05-10",
            "next_check_at": "2026-05-01",
        },
        headers=_auth(token),
    )
    assert response.status_code == 422

    ok = client.post(
        "/api/v1/health-records",
        json={
            "animal_id": animal_id,
            "record_type": "TRATAMIENTO",
            "diagnosis": "Mastitis",
            "treatment": "Antibiótico",
            "veterinarian": "Dra. Gómez",
        },
        headers=_auth(token),
    )
    assert ok.json()["status"] == "EN_TRATAMIENTO"
    assert ok.json()["veterinarian"] == "Dra. Gómez"


def test_health_records_are_isolated_between_farms(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    record_id = client.post(
        "/api/v1/health-records",
        json={"animal_id": animal_id, "record_type": "VACUNA", "diagnosis": "Aftosa"},
        headers=_auth(token),
    ).json()["id"]

    other, _ = _admin_farm(client, email="otro@ganadera.com")
    assert client.get("/api/v1/health-records", headers=_auth(other)).json() == []
    assert client.post(
        "/api/v1/health-records",
        json={"animal_id": animal_id, "record_type": "VACUNA", "diagnosis": "Intruso"},
        headers=_auth(other),
    ).status_code == 403
    assert client.delete(
        f"/api/v1/health-records/{record_id}", headers=_auth(other)
    ).status_code == 403


# ---------- Reproducción ----------

def test_pregnancy_computes_expected_birth(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    recorded = date.today() - timedelta(days=10)

    response = client.post(
        "/api/v1/breeding-records",
        json={"animal_id": animal_id, "record_type": "PRENEZ", "recorded_at": recorded.isoformat()},
        headers=_auth(token),
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["expected_at"] == (recorded + timedelta(days=283)).isoformat()
    assert body["status"] == "Gestante, parto en 273 días"

    for record_type in ("CELO", "INSEMINACION", "PARTO"):
        assert client.post(
            "/api/v1/breeding-records",
            json={"animal_id": animal_id, "record_type": record_type, "notes": "Toro 102"},
            headers=_auth(token),
        ).status_code == 201
    assert len(client.get("/api/v1/breeding-records", headers=_auth(token)).json()) == 4


def test_breeding_rejects_males_and_future_dates(client):
    token, farm_id = _admin_farm(client)
    bull = _animal(client, token, farm_id, tag="TORO-1", gender="MACHO")
    cow = _animal(client, token, farm_id, tag="VACA-1")

    assert client.post(
        "/api/v1/breeding-records",
        json={"animal_id": bull, "record_type": "CELO"},
        headers=_auth(token),
    ).status_code == 422
    assert client.post(
        "/api/v1/breeding-records",
        json={
            "animal_id": cow,
            "record_type": "CELO",
            "recorded_at": (date.today() + timedelta(days=3)).isoformat(),
        },
        headers=_auth(token),
    ).status_code == 422


def test_breeding_requires_module_permission(client):
    token, farm_id = _admin_farm(client)
    client.post(
        "/api/v1/users",
        json={
            "nombre": "Campo", "email": "campo@ganadera.com", "password": PASSWORD,
            "role": "MAYORDOMO", "farm_id": farm_id,
        },
        headers=_auth(token),
    )
    worker = client.post(
        "/api/v1/auth/login",
        json={"email": "campo@ganadera.com", "password": PASSWORD},
    ).json()["access_token"]
    # El trabajador de campo no tiene sanidad ni reproducción por defecto.
    assert client.get("/api/v1/breeding-records", headers=_auth(worker)).status_code == 403
    assert client.get("/api/v1/health-records", headers=_auth(worker)).status_code == 403


# ---------- Reportes ----------

@pytest.mark.parametrize("report", ["animales", "sanidad", "reproduccion", "produccion", "insumos"])
def test_reports_export_pdf_and_excel(client, report):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    client.post(
        "/api/v1/health-records",
        json={"animal_id": animal_id, "record_type": "VACUNA", "diagnosis": "Aftosa"},
        headers=_auth(token),
    )
    client.post(
        "/api/v1/breeding-records",
        json={"animal_id": animal_id, "record_type": "CELO"},
        headers=_auth(token),
    )
    client.post(
        "/api/v1/production",
        json={"animal_id": animal_id, "milk_liters": 18.5},
        headers=_auth(token),
    )
    client.post(
        "/api/v1/inventory",
        json={"name": "Sal mineralizada", "quantity": 40, "minimum_quantity": 50, "unit": "kg"},
        headers=_auth(token),
    )

    pdf = client.get(f"/api/v1/reports/{report}?formato=pdf", headers=_auth(token))
    assert pdf.status_code == 200, pdf.text
    assert pdf.headers["content-type"] == "application/pdf"
    assert pdf.content.startswith(b"%PDF")
    assert f"gavac_{report}_" in pdf.headers["content-disposition"]

    xlsx = client.get(f"/api/v1/reports/{report}?formato=xlsx", headers=_auth(token))
    assert xlsx.status_code == 200
    sheet = load_workbook(BytesIO(xlsx.content)).active
    assert sheet["A1"].value.startswith("GAVAC - Reporte de")
    assert "Finca Ñandú" in sheet["A2"].value
    assert "Generado el" in sheet["A2"].value and " de 20" in sheet["A2"].value
    headers, rows = _table(sheet)
    assert len(rows) == 1
    # Ninguna celda del registro queda vacía.
    assert all(value not in (None, "") for value in rows[0][: len(headers)])
    assert _summary(sheet)


def test_inventory_report_flags_low_stock(client):
    token, _ = _admin_farm(client)
    client.post(
        "/api/v1/inventory",
        json={"name": "Sal mineralizada", "quantity": 40, "minimum_quantity": 50, "unit": "kg"},
        headers=_auth(token),
    )
    xlsx = client.get("/api/v1/reports/insumos?formato=xlsx", headers=_auth(token))
    sheet = load_workbook(BytesIO(xlsx.content)).active
    headers, rows = _table(sheet)
    assert headers[:7] == ["Insumo", "Categoría", "Código", "Existencia", "Unidad",
                           "Mínimo", "Estado"]
    assert rows[0][:7] == ["Sal mineralizada", "GENERAL", "—", 40, "kg", 50, "Bajo el mínimo"]
    assert _summary(sheet)["Bajo el mínimo"] == "1"
    assert _summary(sheet)["Por reponer"] == "Sal mineralizada"


def test_animals_report_includes_all_fields_and_summary(client):
    token, farm_id = _admin_farm(client)
    _animal(client, token, farm_id, tag="GAV-001")
    _animal(client, token, farm_id, tag="GAV-002", gender="MACHO")
    sheet = load_workbook(BytesIO(client.get(
        "/api/v1/reports/animales?formato=xlsx", headers=_auth(token)).content)).active

    headers, rows = _table(sheet)
    assert headers == ["Chapeta", "Nombre", "Sexo", "Raza", "Color", "Nacimiento",
                       "Edad", "Peso (kg)", "Potrero", "Estado", "Registrado"]
    assert rows[0][:5] == ["GAV-001", "Lucero", "Hembra", "Holstein", "—"]
    assert "años" in rows[0][6]
    summary = _summary(sheet)
    assert (summary["Animales en la finca"], summary["Hembras"], summary["Machos"]) == ("2", "1", "1")
    assert (summary["Vendidos"], summary["Muertos"]) == ("0", "0")
    assert summary["Peso promedio"] == "450 kg"


def test_general_report_combines_permitted_modules(client):
    token, farm_id = _admin_farm(client)
    animal_id = _animal(client, token, farm_id)
    client.post(
        "/api/v1/production",
        json={"animal_id": animal_id, "milk_liters": 18.5},
        headers=_auth(token),
    )

    xlsx = client.get("/api/v1/reports/general?formato=xlsx", headers=_auth(token))
    assert xlsx.status_code == 200
    assert 'gavac_general_' in xlsx.headers["content-disposition"]
    workbook = load_workbook(BytesIO(xlsx.content))
    assert workbook.sheetnames == [
        "Resumen", "Registro animal", "Potreros", "Salidas", "Sanidad", "Reproducción",
        "Producción", "Insumos"]
    overview = [c.value for c in workbook["Resumen"]["A"]]
    assert "Producción" in overview and "Leche total" in overview

    pdf = client.get("/api/v1/reports/general?formato=pdf", headers=_auth(token))
    assert pdf.status_code == 200 and pdf.content.startswith(b"%PDF")

    # Un veterinario solo recibe los módulos que tiene habilitados.
    client.post(
        "/api/v1/users",
        json={"nombre": "Vet", "email": "vet2@ganadera.com", "password": PASSWORD,
              "role": "VETERINARIO", "farm_id": farm_id},
        headers=_auth(token),
    )
    vet = client.post(
        "/api/v1/auth/login", json={"email": "vet2@ganadera.com", "password": PASSWORD}
    ).json()["access_token"]
    vet_response = client.get("/api/v1/reports/general?formato=xlsx", headers=_auth(vet))
    assert vet_response.status_code == 403
def test_reports_require_permission_for_report_and_module(client):
    token, farm_id = _admin_farm(client)
    vet_id = client.post(
        "/api/v1/users",
        json={
            "nombre": "Vet", "email": "vet@ganadera.com", "password": PASSWORD,
            "role": "VETERINARIO", "farm_id": farm_id,
        },
        headers=_auth(token),
    ).json()["id"]
    vet = client.post(
        "/api/v1/auth/login", json={"email": "vet@ganadera.com", "password": PASSWORD}
    ).json()["access_token"]

    # Veterinario por defecto: reportes + sanidad, pero no insumos.
    assert client.get("/api/v1/reports/sanidad", headers=_auth(vet)).status_code == 403
    assert client.get("/api/v1/reports/insumos", headers=_auth(vet)).status_code == 403

    client.patch(f"/api/v1/users/{vet_id}", json={"permisos": ["sanidad"]}, headers=_auth(token))
    assert client.get("/api/v1/reports/sanidad", headers=_auth(vet)).status_code == 403
    assert client.get("/api/v1/reports/otro", headers=_auth(token)).status_code == 422
