import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';

final clinicalStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(appointmentRepositoryProvider);
  final appointments = await repo.getAppointmentsForPatient(''); // General fetch fallback
  
  int completed = 0;
  int upcoming = 0;
  int cancelled = 0;
  int inLobby = 0;

  for (final appt in appointments) {
    switch (appt.status) {
      case 'completed':
        completed++;
        break;
      case 'upcoming':
        upcoming++;
        break;
      case 'cancelled':
        cancelled++;
        break;
      case 'in_lobby':
        inLobby++;
        break;
    }
  }

  return {
    'total': appointments.length,
    'completed': completed,
    'upcoming': upcoming,
    'cancelled': cancelled,
    'inLobby': inLobby,
  };
});

class ClinicalReportsView extends ConsumerWidget {
  const ClinicalReportsView({super.key});

  Future<void> _exportPdfReport(BuildContext context, Map<String, dynamic> stats) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('DentalSync Connect - Reporte Médico Operativo',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateTime.now().toString().split(' ')[0]),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Resumen Estadístico de Citas y Atención',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headers: ['Métrica', 'Valor'],
                  data: [
                    ['Total de Citas Registradas', '${stats['total']}'],
                    ['Citas Completadas', '${stats['completed']}'],
                    ['Citas Próximas / Agendadas', '${stats['upcoming']}'],
                    ['En Sala de Espera', '${stats['inLobby']}'],
                    ['Citas Canceladas', '${stats['cancelled']}'],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Este documento es un resumen estadístico generado automáticamente por DentalSync Connect.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Reporte_Clinico_DentalSync_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(clinicalStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Médicos y Métricas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () {
              statsAsync.whenData((stats) => _exportPdfReport(context, stats));
            },
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final total = stats['total'] as int? ?? 0;
          final completed = stats['completed'] as int? ?? 0;
          final upcoming = stats['upcoming'] as int? ?? 0;
          final cancelled = stats['cancelled'] as int? ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Métricas Operativas de la Clínica',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _MetricCard(
                      title: 'Total Citas',
                      value: '$total',
                      icon: Icons.calendar_month,
                      color: Colors.blue,
                    ),
                    _MetricCard(
                      title: 'Completadas',
                      value: '$completed',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _MetricCard(
                      title: 'Programadas',
                      value: '$upcoming',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                    _MetricCard(
                      title: 'Canceladas',
                      value: '$cancelled',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'Acciones de Reportes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _exportPdfReport(context, stats),
                          icon: const Icon(Icons.download),
                          label: const Text('Descargar Reporte PDF Resumido'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error cargando métricas: $err')),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
