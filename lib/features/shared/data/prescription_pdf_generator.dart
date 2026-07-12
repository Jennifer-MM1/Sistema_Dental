import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sistema_dental/core/models/clinical_note.dart';
import 'package:sistema_dental/core/models/prescription.dart';
import 'package:intl/intl.dart';

/// Generador de recetas dentales en formato PDF profesional.
/// Usa los paquetes `pdf` y `printing` para crear y mostrar/descargar el documento.
class PrescriptionPdfGenerator {
  /// Genera y muestra el PDF de una receta.
  static Future<void> generateAndShow({
    required BuildContext context,
    required Prescription prescription,
    required ClinicalNote note,
    required String patientName,
    String? patientDob,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
        italic: await PdfGoogleFonts.nunitoItalic(),
      ),
    );

    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final doctorName = prescription.doctorName ?? 'Dr(a).';
    final clinicName = prescription.clinicName ?? 'DentalSync Clinic';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── ENCABEZADO ──────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#006C9C'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      clinicName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'RECETA MÉDICA DENTAL',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromHex('#B3D9EC'),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── DATOS DEL PACIENTE Y DOCTOR ─────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColor.fromHex('#E2E8F0'),
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfLabel('Paciente:'),
                          pw.Text(
                            patientName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (patientDob != null) ...[
                            pw.SizedBox(height: 4),
                            _pdfLabel('Fecha de nacimiento:'),
                            pw.Text(patientDob, style: _pdfBody()),
                          ],
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _pdfLabel('Doctor:'),
                          pw.Text(
                            doctorName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          _pdfLabel('Fecha de emisión:'),
                          pw.Text(dateStr, style: _pdfBody()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // ── DIAGNÓSTICO ─────────────────────────────────────────
              if (note.diagnosis != null && note.diagnosis!.isNotEmpty) ...[
                _pdfSectionHeader('Diagnóstico'),
                pw.SizedBox(height: 6),
                pw.Text(note.diagnosis!, style: _pdfBody()),
                pw.SizedBox(height: 16),
              ],

              // ── TRATAMIENTO ─────────────────────────────────────────
              if (note.treatmentPerformed != null &&
                  note.treatmentPerformed!.isNotEmpty) ...[
                _pdfSectionHeader('Tratamiento Realizado'),
                pw.SizedBox(height: 6),
                pw.Text(note.treatmentPerformed!, style: _pdfBody()),
                pw.SizedBox(height: 16),
              ],

              // ── DIENTES INVOLUCRADOS ────────────────────────────────
              if (note.toothNumbers.isNotEmpty) ...[
                _pdfSectionHeader('Dientes Involucrados (FDI)'),
                pw.SizedBox(height: 6),
                pw.Text(
                  note.toothNumbers.join(', '),
                  style: _pdfBody(),
                ),
                pw.SizedBox(height: 16),
              ],

              // ── MEDICAMENTOS ────────────────────────────────────────
              _pdfSectionHeader('Medicamentos'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#CBD5E1'),
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Encabezado
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F5F9'),
                    ),
                    children: [
                      _pdfTableHeader('Medicamento'),
                      _pdfTableHeader('Dosis'),
                      _pdfTableHeader('Frecuencia'),
                      _pdfTableHeader('Duración'),
                    ],
                  ),
                  // Filas
                  ...prescription.medications.map(
                    (med) => pw.TableRow(
                      children: [
                        _pdfTableCell(med.name),
                        _pdfTableCell(med.dosage),
                        _pdfTableCell(med.frequency),
                        _pdfTableCell(med.duration),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── INDICACIONES ────────────────────────────────────────
              if (prescription.instructions != null &&
                  prescription.instructions!.isNotEmpty) ...[
                _pdfSectionHeader('Indicaciones Generales'),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFFBEB'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#FDE68A'),
                    ),
                  ),
                  child:
                      pw.Text(prescription.instructions!, style: _pdfBody()),
                ),
              ],

              pw.Spacer(),

              // ── PIE DE PÁGINA / FIRMA ───────────────────────────────
              pw.Divider(color: PdfColor.fromHex('#CBD5E1')),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Este documento fue generado digitalmente',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromHex('#94A3B8'),
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                      pw.Text(
                        'por DentalSync Connect',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromHex('#94A3B8'),
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 180,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColor.fromHex('#1E293B'),
                              width: 1,
                            ),
                          ),
                        ),
                        child: pw.SizedBox(height: 30),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        doctorName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Firma del Doctor',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromHex('#64748B'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Mostrar diálogo de impresión/descarga
    if (context.mounted) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receta_${patientName.replaceAll(' ', '_')}_$dateStr',
      );
    }
  }

  // ── Helpers de estilo PDF ─────────────────────────────────────────

  static pw.Widget _pdfLabel(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        color: PdfColor.fromHex('#64748B'),
      ),
    );
  }

  static pw.TextStyle _pdfBody() {
    return const pw.TextStyle(fontSize: 11);
  }

  static pw.Widget _pdfSectionHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#006C9C'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#334155'),
        ),
      ),
    );
  }

  static pw.Widget _pdfTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
