import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sistema_dental/core/models/clinical_note.dart';
import 'package:sistema_dental/core/models/clinical_attachment.dart';
import 'package:intl/intl.dart';

/// Generador de Expediente Clínico Dental en formato PDF profesional.
class ClinicalHistoryPdfGenerator {
  /// Genera y muestra/descarga el expediente clínico completo del paciente en PDF.
  static Future<void> generateAndShow({
    required BuildContext context,
    required Map<String, dynamic> patient,
    required List<ClinicalNote> notes,
    required List<Map<String, dynamic>> appointments,
    required List<ClinicalAttachment> attachments,
    String clinicName = 'DentalSync Clinic',
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
        italic: await PdfGoogleFonts.nunitoItalic(),
      ),
    );

    final patientName = '${patient['first_name']} ${patient['last_name']}';
    final isSelf = patient['relationship'] == 'self';
    final relText = isSelf
        ? 'Paciente Titular (Self)'
        : (patient['relationship'] == 'child'
            ? 'Hijo/a'
            : (patient['relationship'] == 'spouse'
                ? 'Cónyuge'
                : (patient['relationship'] == 'parent'
                    ? 'Padre/Madre'
                    : 'Otro')));
    final dobStr = patient['date_of_birth'] != null
        ? patient['date_of_birth'].toString()
        : 'Sin registrar';
    final datePrintedStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context pdfContext) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#006C9C'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      clinicName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'EXPEDIENTE CLÍNICO DENTAL GENERAL',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Emisión: $datePrintedStr',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context pdfContext) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'Página ${pdfContext.pageNumber} de ${pdfContext.pagesCount} • DentalSync',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context pdfContext) {
          return [
            // ── DATOS DEL PACIENTE ─────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F0F8FF'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('#BEE3F8')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FICHA DE IDENTIFICACIÓN DEL PACIENTE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#006C9C'),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Nombre: $patientName',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Parentesco: $relText',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Fecha de Nacimiento: $dobStr',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Notas Clínicas Registradas: ${notes.length}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── SECCIÓN NOTAS CLÍNICAS Y DIAGNÓSTICOS ───────────────────
            pw.Text(
              'HISTORIAL DE CONSULTAS Y TRATAMIENTOS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#006C9C'),
              ),
            ),
            pw.SizedBox(height: 8),

            if (notes.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Text(
                  'No hay notas clínicas registradas para este paciente.',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
              )
            else
              ...notes.map((note) {
                final dateStr = note.createdAt != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt!)
                    : 'Sin fecha';
                final teethSummary = note.toothNumbers.isNotEmpty
                    ? note.toothNumbers.join(', ')
                    : null;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Fecha: $dateStr',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#006C9C'),
                            ),
                          ),
                          if (note.doctorName != null)
                            pw.Text(
                              'Atendió: Dr(a). ${note.doctorName}',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                            ),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey200, height: 12),

                      if (note.diagnosis != null && note.diagnosis!.isNotEmpty) ...[
                        pw.Text(
                          'Diagnóstico:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(note.diagnosis!, style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 6),
                      ],

                      if (note.treatmentPerformed != null && note.treatmentPerformed!.isNotEmpty) ...[
                        pw.Text(
                          'Tratamiento Realizado:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(note.treatmentPerformed!, style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 6),
                      ],

                      if (note.observations != null && note.observations!.isNotEmpty) ...[
                        pw.Text(
                          'Observaciones / Recomendaciones:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(note.observations!, style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 6),
                      ],

                      if (teethSummary != null) ...[
                        pw.Text(
                          'Dientes Tratados (Nomenclatura FDI):',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D97706')),
                        ),
                        pw.Text(teethSummary, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                );
              }),

            pw.SizedBox(height: 16),

            // ── CITAS AGENDADAS ───────────────────────────────────────
            pw.Text(
              'HISTORIAL DE CITAS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#006C9C'),
              ),
            ),
            pw.SizedBox(height: 8),

            if (appointments.isEmpty)
              pw.Text('Sin historial de citas.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700))
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#006C9C')),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['Fecha y Hora', 'Servicio', 'Dentista', 'Estado'],
                data: appointments.map((appt) {
                  final dateStr = appt['date_time'] != null
                      ? DateFormat('dd/MM/yyyy - hh:mm a').format(DateTime.parse(appt['date_time'] as String).toLocal())
                      : 'N/A';
                  final service = (appt['services'] as Map?)?['service_name'] ?? 'Consulta';
                  final doctor = (appt['doctors'] as Map?)?['profiles']?['name'] ?? 'Dentista';
                  final status = appt['status']?.toString() ?? 'upcoming';

                  return [dateStr, service, doctor, status];
                }).toList(),
              ),

            pw.SizedBox(height: 16),

            // ── RADIOGRAFÍAS Y ADJUNTOS ──────────────────────────────────
            pw.Text(
              'ESTUDIOS Y RADIOGRAFÍAS REGISTRADAS (${attachments.length})',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#006C9C'),
              ),
            ),
            pw.SizedBox(height: 8),

            if (attachments.isEmpty)
              pw.Text('Sin radiografías adjuntas.', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700))
            else
              ...attachments.map((att) {
                final dateStr = DateFormat('dd/MM/yyyy').format(att.createdAt.toLocal());
                return pw.Bullet(
                  text: '${att.fileName} • Fecha de subida: $dateStr',
                  style: const pw.TextStyle(fontSize: 10),
                );
              }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Expediente_${patientName.replaceAll(' ', '_')}.pdf',
    );
  }
}
