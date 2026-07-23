import 'package:flutter/material.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';

/// Widget interactivo del odontograma dental (32 dientes permanentes).
/// Usa nomenclatura FDI (ISO 3950):
/// - Cuadrante 1 (11-18): Superior derecho del paciente
/// - Cuadrante 2 (21-28): Superior izquierdo del paciente
/// - Cuadrante 3 (31-38): Inferior izquierdo del paciente
/// - Cuadrante 4 (41-48): Inferior derecho del paciente
class OdontogramWidget extends StatefulWidget {
  /// Dientes seleccionados actualmente (números FDI).
  final List<int> selectedTeeth;

  /// Callback cuando cambia la selección de dientes.
  final ValueChanged<List<int>>? onSelectionChanged;

  /// Si es true, el odontograma es solo de lectura (no se pueden tocar dientes).
  final bool readOnly;

  /// Tamaño del widget.
  final double? width;

  const OdontogramWidget({
    super.key,
    this.selectedTeeth = const [],
    this.onSelectionChanged,
    this.readOnly = false,
    this.width,
  });

  @override
  State<OdontogramWidget> createState() => _OdontogramWidgetState();
}

class _OdontogramWidgetState extends State<OdontogramWidget> {
  late Set<int> _selected;

  // Dientes por cuadrante (nomenclatura FDI)
  static const _upperRight = [18, 17, 16, 15, 14, 13, 12, 11]; // Q1
  static const _upperLeft = [21, 22, 23, 24, 25, 26, 27, 28]; // Q2
  static const _lowerLeft = [31, 32, 33, 34, 35, 36, 37, 38]; // Q3
  static const _lowerRight = [48, 47, 46, 45, 44, 43, 42, 41]; // Q4

  // Nombres de dientes para tooltip
  static const _toothNames = <int, String>{
    11: 'Incisivo central sup. der.',
    12: 'Incisivo lateral sup. der.',
    13: 'Canino sup. der.',
    14: 'Primer premolar sup. der.',
    15: 'Segundo premolar sup. der.',
    16: 'Primer molar sup. der.',
    17: 'Segundo molar sup. der.',
    18: 'Tercer molar sup. der.',
    21: 'Incisivo central sup. izq.',
    22: 'Incisivo lateral sup. izq.',
    23: 'Canino sup. izq.',
    24: 'Primer premolar sup. izq.',
    25: 'Segundo premolar sup. izq.',
    26: 'Primer molar sup. izq.',
    27: 'Segundo molar sup. izq.',
    28: 'Tercer molar sup. izq.',
    31: 'Incisivo central inf. izq.',
    32: 'Incisivo lateral inf. izq.',
    33: 'Canino inf. izq.',
    34: 'Primer premolar inf. izq.',
    35: 'Segundo premolar inf. izq.',
    36: 'Primer molar inf. izq.',
    37: 'Segundo molar inf. izq.',
    38: 'Tercer molar inf. izq.',
    41: 'Incisivo central inf. der.',
    42: 'Incisivo lateral inf. der.',
    43: 'Canino inf. der.',
    44: 'Primer premolar inf. der.',
    45: 'Segundo premolar inf. der.',
    46: 'Primer molar inf. der.',
    47: 'Segundo molar inf. der.',
    48: 'Tercer molar inf. der.',
  };

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.selectedTeeth);
  }

  @override
  void didUpdateWidget(OdontogramWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTeeth != widget.selectedTeeth) {
      _selected = Set<int>.from(widget.selectedTeeth);
    }
  }

  void _toggleTooth(int number) {
    if (widget.readOnly) return;
    setState(() {
      if (_selected.contains(number)) {
        _selected.remove(number);
      } else {
        _selected.add(number);
      }
    });
    widget.onSelectionChanged?.call(_selected.toList()..sort());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medical_services_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Odontograma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selected.length} seleccionado${_selected.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Leyenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.grey.shade200, 'Normal'),
              const SizedBox(width: 16),
              _buildLegendItem(AppColors.primaryBlue, 'Seleccionado'),
            ],
          ),
          const SizedBox(height: 20),

          // Arcada Superior (Q1 + Q2)
          Text(
            'SUPERIOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildDentalArch(
                _upperRight + _upperLeft,
                constraints.maxWidth,
                isUpper: true,
              );
            },
          ),

          // Línea divisoria (encía)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.pink.shade200,
                  Colors.pink.shade300,
                  Colors.pink.shade200,
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          // Arcada Inferior (Q4 + Q3)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildDentalArch(
                _lowerRight + _lowerLeft,
                constraints.maxWidth,
                isUpper: false,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'INFERIOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 2,
            ),
          ),

          // Dientes seleccionados
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withAlpha(51)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (_selected.toList()..sort()).map((tooth) {
                  return Chip(
                    label: Text(
                      '#$tooth',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    deleteIcon: widget.readOnly
                        ? null
                        : const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                    onDeleted: widget.readOnly
                        ? null
                        : () => _toggleTooth(tooth),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDentalArch(
    List<int> teeth,
    double maxWidth, {
    required bool isUpper,
  }) {
    final toothSize = ((maxWidth - 32) / 16).clamp(24.0, 38.0);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      children: teeth.map((tooth) {
        final isSelected = _selected.contains(tooth);
        final isMolar = _isMolar(tooth);

        return Tooltip(
          message: '${_toothNames[tooth] ?? ''} (#$tooth)',
          child: GestureDetector(
            onTap: widget.readOnly ? null : () => _toggleTooth(tooth),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isMolar ? toothSize + 4 : toothSize,
              height: toothSize + 8,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isUpper ? 8 : 4),
                  bottom: Radius.circular(isUpper ? 4 : 8),
                ),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondaryBlue
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withAlpha(77),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono del diente
                  Icon(
                    _getToothIcon(tooth),
                    size: toothSize * 0.4,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 1),
                  // Número
                  Text(
                    '$tooth',
                    style: TextStyle(
                      fontSize: toothSize * 0.28,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  bool _isMolar(int tooth) {
    final unit = tooth % 10;
    return unit >= 6 && unit <= 8; // Molares (6, 7, 8)
  }

  IconData _getToothIcon(int tooth) {
    final unit = tooth % 10;
    if (unit >= 6) return Icons.square_rounded; // Molares
    if (unit >= 4) return Icons.hexagon_outlined; // Premolares
    if (unit == 3) return Icons.change_history; // Caninos
    return Icons.crop_portrait; // Incisivos
  }
}
