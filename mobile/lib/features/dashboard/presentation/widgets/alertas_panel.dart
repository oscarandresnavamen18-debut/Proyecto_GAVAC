import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/gavac_colors.dart';
import '../../data/services/alerts_api_service.dart';

/// Panel con las alarmas de la finca. Al tocar una alarma se llama
/// [onOpenModule] con el módulo donde se resuelve.
Future<void> showAlertasPanel(
  BuildContext context, {
  required List<Alerta> alertas,
  required ValueChanged<String> onOpenModule,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
      title: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: GavacColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alertas.isEmpty ? 'Alarmas' : 'Alarmas (${alertas.length})',
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: alertas.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 40,
                      color: GavacColors.primary,
                    ),
                    SizedBox(height: 8),
                    Text('Todo en orden: no hay alarmas pendientes.'),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: alertas.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final alerta = alertas[index];
                  final color = alerta.esAlta
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD97706);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        _icono(alerta.modulo),
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      alerta.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(alerta.detalle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      onOpenModule(alerta.modulo);
                    },
                  );
                },
              ),
      ),
    ),
  );
}

IconData _icono(String modulo) => switch (modulo) {
  'sanidad' => Icons.vaccines_outlined,
  'reproduccion' => Icons.favorite_border,
  _ => Icons.inventory_2_outlined,
};
