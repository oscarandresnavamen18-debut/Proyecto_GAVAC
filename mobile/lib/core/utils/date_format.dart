/// Fecha en formato dd/mm/aaaa.
String formatDate(DateTime? date) {
  if (date == null) return '—';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

/// Fecha en formato ISO (aaaa-mm-dd) para enviar al API.
String isoDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

DateTime? parseApiDate(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;
