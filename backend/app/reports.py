"""Generación de reportes por módulo y del resumen general, en PDF y Excel."""
from collections import Counter
from dataclasses import dataclass, field
from datetime import date, datetime
from io import BytesIO
from typing import Callable

from fpdf import FPDF
from fpdf.fonts import FontFace
from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.worksheet import Worksheet
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Animal, ProductionRecord, User
from app.routers.breeding import breeding_status, farm_breeding_records
from app.routers.health_records import farm_health_records, health_status
from app.routers.inventory import farm_inventory

PRIMARY_HEX = "1A3A32"
PRIMARY_RGB = (26, 58, 50)
EMPTY = "—"

MONTHS = ("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
          "agosto", "septiembre", "octubre", "noviembre", "diciembre")

HEALTH_STATUS_LABELS = {
    "VIGENTE": "Vigente",
    "PROXIMO_A_VENCER": "Próximo a vencer",
    "VENCIDO": "Vencido",
    "EN_TRATAMIENTO": "En tratamiento",
    "FINALIZADO": "Finalizado",
}
BREEDING_LABELS = {
    "CELO": "Celo",
    "INSEMINACION": "Inseminación",
    "PRENEZ": "Preñez",
    "PARTO": "Parto",
}
BREEDING_PLURALS = {
    "CELO": "Celos",
    "INSEMINACION": "Inseminaciones",
    "PRENEZ": "Preñeces",
    "PARTO": "Partos",
}


@dataclass
class Report:
    title: str
    headers: list[str]
    rows: list[list[object]]
    # Peso relativo del ancho de cada columna en el PDF.
    widths: list[int]
    # Indicadores que se muestran antes de la tabla: (nombre, valor).
    summary: list[tuple[str, str]] = field(default_factory=list)


def long_date(value: date) -> str:
    """Fecha en español: 14 de noviembre de 2026."""
    return f"{value.day} de {MONTHS[value.month - 1]} de {value.year}"


def _fmt_date(value: date | datetime | None) -> str:
    if value is None:
        return EMPTY
    if isinstance(value, datetime):
        value = value.date()
    return value.strftime("%d/%m/%Y")


def _fmt_number(value: float) -> str:
    text = f"{value:,.2f}".rstrip("0").rstrip(".")
    # Formato colombiano: punto de miles y coma decimal.
    return text.replace(",", "_").replace(".", ",").replace("_", ".")


def _text(value: object) -> object:
    """Reemplaza vacíos por un guion para que ninguna celda quede en blanco."""
    if value is None or (isinstance(value, str) and not value.strip()):
        return EMPTY
    return value


def _age(birth: date, today: date) -> str:
    months = (today.year - birth.year) * 12 + today.month - birth.month
    if today.day < birth.day:
        months -= 1
    months = max(months, 0)
    if months < 12:
        return f"{months} {'mes' if months == 1 else 'meses'}"
    years, rest = divmod(months, 12)
    label = f"{years} {'año' if years == 1 else 'años'}"
    return label if rest == 0 else f"{label} y {rest} {'mes' if rest == 1 else 'meses'}"


class _UserNames:
    """Nombres de quienes registraron cada dato, con caché por reporte."""

    def __init__(self, db: Session):
        self._db = db
        self._cache: dict[int, str] = {}

    def __call__(self, user_id: int | None) -> str:
        if user_id is None:
            return EMPTY
        if user_id not in self._cache:
            user = self._db.get(User, user_id)
            self._cache[user_id] = user.full_name if user else EMPTY
        return self._cache[user_id]


# ---------------------------------------------------------------------------
# Reportes por módulo
# ---------------------------------------------------------------------------

def _animals_report(db: Session, farm_id: int) -> Report:
    today = date.today()
    animals = db.scalars(
        select(Animal)
        .where(Animal.finca_id == farm_id, Animal.is_active.is_(True))
        .order_by(Animal.tag_id)
    ).all()
    weights = [float(a.current_weight) for a in animals]
    genders = Counter(a.gender.value for a in animals)
    breeds = Counter(a.breed for a in animals)
    return Report(
        title="Registro animal",
        headers=["Chapeta", "Nombre", "Sexo", "Raza", "Color", "Nacimiento",
                 "Edad", "Peso (kg)", "Estado", "Registrado"],
        rows=[
            [
                a.tag_id,
                _text(a.name),
                a.gender.value.capitalize(),
                a.breed,
                _text(a.color),
                _fmt_date(a.birth_date),
                _age(a.birth_date, today),
                float(a.current_weight),
                a.status.value.capitalize(),
                _fmt_date(a.created_at),
            ]
            for a in animals
        ],
        widths=[3, 3, 2, 3, 2, 3, 3, 2, 2, 3],
        summary=[
            ("Total de animales", str(len(animals))),
            ("Hembras", str(genders.get("HEMBRA", 0))),
            ("Machos", str(genders.get("MACHO", 0))),
            ("Peso promedio",
             f"{_fmt_number(sum(weights) / len(weights))} kg" if weights else EMPTY),
            ("Raza principal", breeds.most_common(1)[0][0] if breeds else EMPTY),
        ],
    )


def _health_report(db: Session, farm_id: int) -> Report:
    records = farm_health_records(db, farm_id)
    statuses = Counter(health_status(r) for r, _ in records)
    return Report(
        title="Sanidad",
        headers=["Aplicación", "Chapeta", "Animal", "Tipo", "Vacuna / Diagnóstico",
                 "Medicamento", "Dosis", "Veterinario", "Próxima fecha", "Estado",
                 "Observaciones"],
        rows=[
            [
                _fmt_date(r.recorded_at),
                a.tag_id,
                _text(a.name),
                "Vacuna" if r.record_type == "VACUNA" else "Tratamiento",
                _text(r.diagnosis),
                _text(r.treatment),
                _text(r.dose),
                _text(r.veterinarian),
                _fmt_date(r.next_check_at),
                HEALTH_STATUS_LABELS[health_status(r)],
                _text(r.notes),
            ]
            for r, a in records
        ],
        widths=[2, 2, 2, 2, 3, 3, 2, 3, 2, 2, 3],
        summary=[
            ("Registros sanitarios", str(len(records))),
            ("Vacunas", str(sum(1 for r, _ in records if r.record_type == "VACUNA"))),
            ("Tratamientos activos", str(statuses.get("EN_TRATAMIENTO", 0))),
            ("Vacunas por vencer", str(statuses.get("PROXIMO_A_VENCER", 0))),
            ("Vacunas vencidas", str(statuses.get("VENCIDO", 0))),
        ],
    )


def _breeding_report(db: Session, farm_id: int) -> Report:
    records = farm_breeding_records(db, farm_id)
    names = _UserNames(db)
    events = Counter(r.record_type for r, _ in records)
    return Report(
        title="Reproducción",
        headers=["Fecha", "Chapeta", "Animal", "Evento", "Fecha esperada",
                 "Estado", "Observaciones", "Registrado por"],
        rows=[
            [
                _fmt_date(r.recorded_at),
                a.tag_id,
                _text(a.name),
                BREEDING_LABELS.get(r.record_type, r.record_type),
                _fmt_date(r.expected_at),
                breeding_status(r),
                _text(r.notes),
                names(r.created_by),
            ]
            for r, a in records
        ],
        widths=[2, 2, 2, 2, 2, 4, 4, 3],
        summary=[("Eventos registrados", str(len(records)))]
        + [(BREEDING_PLURALS[key], str(events.get(key, 0))) for key in BREEDING_LABELS],
    )


def _production_report(db: Session, farm_id: int) -> Report:
    rows = db.execute(
        select(ProductionRecord, Animal)
        .join(Animal, Animal.id == ProductionRecord.animal_id)
        .where(Animal.finca_id == farm_id)
        .order_by(ProductionRecord.recorded_at.desc(), ProductionRecord.id.desc())
    ).all()
    names = _UserNames(db)
    milk = [float(r.quantity) for r, _ in rows if r.record_type == "MILK"]
    weighings = sum(1 for r, _ in rows if r.record_type != "MILK")
    return Report(
        title="Producción",
        headers=["Fecha", "Chapeta", "Animal", "Tipo", "Cantidad", "Unidad",
                 "Observaciones", "Registrado por"],
        rows=[
            [
                _fmt_date(r.recorded_at),
                a.tag_id,
                _text(a.name),
                "Leche" if r.record_type == "MILK" else "Peso",
                float(r.quantity),
                r.unit,
                _text(r.notes),
                names(r.created_by),
            ]
            for r, a in rows
        ],
        widths=[2, 2, 2, 2, 2, 1, 4, 3],
        summary=[
            ("Registros de producción", str(len(rows))),
            ("Leche total", f"{_fmt_number(sum(milk))} L"),
            ("Promedio por ordeño",
             f"{_fmt_number(sum(milk) / len(milk))} L" if milk else EMPTY),
            ("Pesajes registrados", str(weighings)),
        ],
    )


def _inventory_report(db: Session, farm_id: int) -> Report:
    items = farm_inventory(db, farm_id)
    low = [item for item, quantity in items if quantity < item.minimum_quantity]
    return Report(
        title="Insumos",
        headers=["Insumo", "Categoría", "Código", "Existencia", "Unidad", "Mínimo",
                 "Estado", "Registrado"],
        rows=[
            [
                item.name,
                item.category,
                _text(item.sku),
                float(quantity),
                item.unit,
                float(item.minimum_quantity),
                "Bajo el mínimo" if quantity < item.minimum_quantity else "Disponible",
                _fmt_date(item.created_at),
            ]
            for item, quantity in items
        ],
        widths=[4, 3, 2, 2, 2, 2, 3, 2],
        summary=[
            ("Insumos activos", str(len(items))),
            ("Bajo el mínimo", str(len(low))),
            ("Por reponer", ", ".join(i.name for i in low[:5]) or "Ninguno"),
        ],
    )


# clave del reporte -> (módulo de permiso, generador)
REPORTS: dict[str, tuple[str, Callable[[Session, int], Report]]] = {
    "animales": ("registro", _animals_report),
    "sanidad": ("sanidad", _health_report),
    "reproduccion": ("reproduccion", _breeding_report),
    "produccion": ("produccion", _production_report),
    "insumos": ("insumos", _inventory_report),
}


def build_report(db: Session, key: str, farm_id: int) -> Report:
    return REPORTS[key][1](db, farm_id)


def build_general(db: Session, farm_id: int, allowed: Callable[[str], bool]) -> list[Report]:
    """Reportes de todos los módulos que el usuario puede consultar."""
    return [build(db, farm_id) for module, build in REPORTS.values() if allowed(module)]


# ---------------------------------------------------------------------------
# Excel
# ---------------------------------------------------------------------------

_THIN = Side(style="thin", color="E2E8F0")


def _write_sheet(ws: Worksheet, report: Report, farm_name: str) -> None:
    ws.append([f"GAVAC - Reporte de {report.title}"])
    ws.append([f"Finca: {farm_name}   |   Generado el {long_date(date.today())}"])
    ws["A1"].font = Font(bold=True, size=14, color=PRIMARY_HEX)
    ws["A2"].font = Font(italic=True, color="64748B")
    ws.append([])

    if report.summary:
        ws.append(["Resumen"])
        ws.cell(row=ws.max_row, column=1).font = Font(bold=True, color=PRIMARY_HEX)
        for label, value in report.summary:
            ws.append([label, value])
            ws.cell(row=ws.max_row, column=1).font = Font(color="475569")
            ws.cell(row=ws.max_row, column=2).font = Font(bold=True)
        ws.append([])

    ws.append(report.headers)
    header_row = ws.max_row
    for cell in ws[header_row]:
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = PatternFill("solid", fgColor=PRIMARY_HEX)
        cell.alignment = Alignment(vertical="center", wrap_text=True)
    for row in report.rows:
        ws.append(row)
        for cell in ws[ws.max_row]:
            cell.border = Border(bottom=_THIN)
            if isinstance(cell.value, float):
                cell.number_format = "#,##0.##"
    if not report.rows:
        ws.append(["No hay registros para este reporte."])

    for index, header in enumerate(report.headers, start=1):
        values = [str(header)] + [str(r[index - 1]) for r in report.rows]
        if index == 1:
            values += [label for label, _ in report.summary]
        width = max(len(v) for v in values)
        ws.column_dimensions[get_column_letter(index)].width = min(max(width + 2, 10), 45)
    ws.freeze_panes = ws.cell(row=header_row + 1, column=1)
    if report.rows:
        last = get_column_letter(len(report.headers))
        ws.auto_filter.ref = f"A{header_row}:{last}{header_row + len(report.rows)}"


def render_xlsx(report: Report, farm_name: str) -> bytes:
    wb = Workbook()
    ws = wb.active
    ws.title = report.title[:31]
    _write_sheet(ws, report, farm_name)
    buffer = BytesIO()
    wb.save(buffer)
    return buffer.getvalue()


def render_general_xlsx(reports: list[Report], farm_name: str) -> bytes:
    wb = Workbook()
    summary = wb.active
    summary.title = "Resumen"
    summary.append(["GAVAC - Resumen general de la finca"])
    summary.append([f"Finca: {farm_name}   |   Generado el {long_date(date.today())}"])
    summary["A1"].font = Font(bold=True, size=14, color=PRIMARY_HEX)
    summary["A2"].font = Font(italic=True, color="64748B")
    for report in reports:
        summary.append([])
        summary.append([report.title])
        summary.cell(row=summary.max_row, column=1).font = Font(
            bold=True, size=12, color=PRIMARY_HEX)
        for label, value in report.summary:
            summary.append([label, value])
            summary.cell(row=summary.max_row, column=2).font = Font(bold=True)
    summary.column_dimensions["A"].width = 32
    summary.column_dimensions["B"].width = 40

    for report in reports:
        _write_sheet(wb.create_sheet(report.title[:31]), report, farm_name)
    buffer = BytesIO()
    wb.save(buffer)
    return buffer.getvalue()


# ---------------------------------------------------------------------------
# PDF
# ---------------------------------------------------------------------------

def _pdf_text(value: object) -> str:
    # Las fuentes base del PDF usan Latin-1 (cubre tildes y ñ).
    if isinstance(value, float):
        value = _fmt_number(value)
    return str(value).replace(EMPTY, "-").encode("latin-1", "replace").decode("latin-1")


class _GavacPDF(FPDF):
    def footer(self):
        self.set_y(-10)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(148, 163, 184)
        self.cell(0, 5, _pdf_text(
            f"GAVAC - Gestión ganadera   |   Página {self.page_no()}/{{nb}}"), align="C")


def _new_pdf() -> FPDF:
    pdf = _GavacPDF(orientation="L", unit="mm", format="A4")
    pdf.set_auto_page_break(auto=True, margin=14)
    pdf.set_margins(12, 12, 12)
    return pdf


def _pdf_header(pdf: FPDF, title: str, farm_name: str, subtitle: str = "") -> None:
    pdf.set_font("Helvetica", "B", 16)
    pdf.set_text_color(*PRIMARY_RGB)
    pdf.cell(0, 9, _pdf_text(title), new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color(100, 116, 139)
    line = f"Finca: {farm_name}   |   Generado el {long_date(date.today())}"
    pdf.cell(0, 6, _pdf_text(line + (f"   |   {subtitle}" if subtitle else "")),
             new_x="LMARGIN", new_y="NEXT")
    pdf.ln(3)


def _pdf_summary(pdf: FPDF, summary: list[tuple[str, str]]) -> None:
    """Indicadores como tarjetas en una fila."""
    if not summary:
        return
    gap = 3
    width = (pdf.epw - gap * (len(summary) - 1)) / len(summary)
    top = pdf.get_y()
    for index, (label, value) in enumerate(summary):
        x = pdf.l_margin + index * (width + gap)
        pdf.set_fill_color(240, 246, 243)
        pdf.set_draw_color(214, 228, 221)
        pdf.rect(x, top, width, 15, style="DF")
        pdf.set_xy(x + 2, top + 2)
        pdf.set_font("Helvetica", "", 8)
        pdf.set_text_color(100, 116, 139)
        pdf.cell(width - 4, 4, _pdf_text(label))
        pdf.set_xy(x + 2, top + 7)
        pdf.set_font("Helvetica", "B", 11)
        pdf.set_text_color(*PRIMARY_RGB)
        pdf.cell(width - 4, 6, _pdf_text(value))
    pdf.set_y(top + 19)


def _pdf_table(pdf: FPDF, report: Report) -> None:
    if not report.rows:
        pdf.set_font("Helvetica", "I", 10)
        pdf.set_text_color(100, 116, 139)
        pdf.cell(0, 8, _pdf_text("No hay registros para este reporte."),
                 new_x="LMARGIN", new_y="NEXT")
        return
    total = sum(report.widths)
    widths = [pdf.epw * w / total for w in report.widths]
    pdf.set_font("Helvetica", "", 8)
    pdf.set_text_color(30, 41, 59)
    pdf.set_draw_color(226, 232, 240)
    with pdf.table(
        col_widths=widths,
        headings_style=FontFace(emphasis="BOLD", color=(255, 255, 255),
                                fill_color=PRIMARY_RGB),
        cell_fill_color=(248, 250, 252),
        cell_fill_mode="ROWS",
        line_height=5.5,
        first_row_as_headings=True,
    ) as table:
        table.row([_pdf_text(h) for h in report.headers])
        for values in report.rows:
            table.row([_pdf_text(v) for v in values])


def render_pdf(report: Report, farm_name: str) -> bytes:
    pdf = _new_pdf()
    pdf.add_page()
    _pdf_header(pdf, f"GAVAC - Reporte de {report.title}", farm_name,
                f"Registros: {len(report.rows)}")
    _pdf_summary(pdf, report.summary)
    _pdf_table(pdf, report)
    return bytes(pdf.output())


def render_general_pdf(reports: list[Report], farm_name: str) -> bytes:
    pdf = _new_pdf()
    pdf.add_page()
    _pdf_header(pdf, "GAVAC - Resumen general de la finca", farm_name)
    for report in reports:
        pdf.set_font("Helvetica", "B", 12)
        pdf.set_text_color(*PRIMARY_RGB)
        pdf.cell(0, 8, _pdf_text(report.title), new_x="LMARGIN", new_y="NEXT")
        _pdf_summary(pdf, report.summary)
    for report in reports:
        pdf.add_page()
        _pdf_header(pdf, report.title, farm_name, f"Registros: {len(report.rows)}")
        _pdf_summary(pdf, report.summary)
        _pdf_table(pdf, report)
    return bytes(pdf.output())
