import 'package:material_ui/material_ui.dart';

class GavacBrand extends StatelessWidget {
  const GavacBrand({
    required this.foregroundColor,
    this.compact = false,
    super.key,
  });

  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mark = Icon(
      Icons.agriculture_outlined,
      color: foregroundColor,
      size: compact ? 30 : 52,
    );
    final name = Text(
      'GAVAC',
      style: TextStyle(
        color: foregroundColor,
        fontSize: compact ? 24 : 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [mark, const SizedBox(width: 10), name],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: foregroundColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: mark,
        ),
        const SizedBox(height: 16),
        name,
        const SizedBox(height: 4),
        Text(
          'Gestión ganadera',
          style: TextStyle(
            color: foregroundColor.withValues(alpha: 0.85),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Administración ganadera colombiana',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
