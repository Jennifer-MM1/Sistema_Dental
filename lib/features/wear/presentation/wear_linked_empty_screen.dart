import 'package:flutter/material.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';
import 'package:sistema_dental/features/wear/presentation/wear_bootstrap_screen.dart';
import 'package:sistema_dental/features/wear/presentation/wear_shell.dart';

class WearLinkedEmptyScreen extends StatelessWidget {
  final WearPatientSummaryData? summary;

  const WearLinkedEmptyScreen({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    return WearShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 190;
          final width = compact ? 158.0 : 190.0;
          final data = summary;
          final patientPreview = data?.patientNames.take(2).join(', ') ?? '';

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WearTopBar(),
                    SizedBox(height: compact ? 5 : 7),
                    const WearTitle('Resumen'),
                    SizedBox(height: compact ? 9 : 12),
                    Row(
                      children: [
                        Container(
                          width: compact ? 34 : 40,
                          height: compact ? 34 : 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF12394B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF78F2C0),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data?.userName ?? 'Cliente',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 13 : 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                data?.roleLabel ?? 'DentalSync',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF78F2C0),
                                  fontSize: compact ? 8.5 : 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 9 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            value: '${data?.patientNames.length ?? 0}',
                            label: 'Pacientes',
                            color: const Color(0xFF008ED1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniMetric(
                            value: '${data?.appointmentCount ?? 0}',
                            label: 'Citas',
                            color: const Color(0xFF78F2C0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 9 : 11),
                    _InfoPanel(
                      title: data?.hasAppointments == true
                          ? 'Próxima cita'
                          : 'Sin citas',
                      body: data?.hasAppointments == true
                          ? '${data?.nextPatientName ?? 'Paciente'} · ${_formatTime(data?.nextAppointmentTime)}'
                          : 'No tiene citas actualmente.',
                    ),
                    if (patientPreview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _InfoPanel(title: 'A cargo', body: patientPreview),
                    ],
                    SizedBox(height: compact ? 8 : 12),
                    SizedBox(
                      width: double.infinity,
                      height: compact ? 29 : 33,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WearBootstrapScreen(),
                            ),
                            (_) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF087956),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Actualizar',
                          style: TextStyle(fontSize: compact ? 10 : 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return 'Pendiente';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _MiniMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final String body;

  const _InfoPanel({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C2D35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8B969E), fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}
