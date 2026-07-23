import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sistema_dental/features/secretary/data/billing_repository.dart';

class BillingReceiptPdf {
  static Future<void> printInvoice({
    required String clinicName,
    required Map<String, dynamic> invoice,
  }) async {
    final pdf = pw.Document();
    final patient = invoice['patients'];
    final appointment = invoice['appointments'];
    final payments = invoice['payments'] is List
        ? List<Map<String, dynamic>>.from(invoice['payments'])
        : <Map<String, dynamic>>[];
    payments.removeWhere((payment) => payment['voided_at'] != null);
    payments.sort(
      (a, b) => (a['paid_at']?.toString() ?? '').compareTo(
        b['paid_at']?.toString() ?? '',
      ),
    );
    final patientName =
        '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}'.trim();
    final serviceName =
        appointment?['services']?['service_name'] ?? 'Servicio dental';
    final doctorName =
        appointment?['doctors']?['profiles']?['name'] ?? 'No especificado';
    final issuedAt = DateTime.parse(invoice['issued_at']).toLocal();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => [
          _header(clinicName, 'COMPROBANTE DE CUENTA'),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _field('Factura', invoice['invoice_number']?.toString() ?? ''),
              _field('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(issuedAt)),
            ],
          ),
          pw.SizedBox(height: 16),
          _field('Paciente', patientName),
          _field('Servicio', serviceName.toString()),
          _field('Dentista', doctorName.toString()),
          pw.SizedBox(height: 20),
          _totals(invoice),
          pw.SizedBox(height: 24),
          pw.Text(
            'PAGOS REGISTRADOS',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 8),
          if (payments.isEmpty)
            pw.Text('Sin pagos registrados.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Recibo', 'Fecha', 'Método', 'Importe'],
              data: payments.map((payment) {
                final paidAt = DateTime.parse(payment['paid_at']).toLocal();
                return [
                  payment['receipt_number'] ?? '',
                  DateFormat('dd/MM/yyyy HH:mm').format(paidAt),
                  _methodLabel(payment['payment_method']?.toString()),
                  _money(billingMoney(payment['amount'])),
                ];
              }).toList(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey100,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          pw.SizedBox(height: 28),
          _footer(),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Factura_${invoice['invoice_number']}',
      onLayout: (_) => pdf.save(),
    );
  }

  static Future<void> printPayment({
    required String clinicName,
    required Map<String, dynamic> invoice,
    required Map<String, dynamic> payment,
  }) async {
    final pdf = pw.Document();
    final patient = invoice['patients'];
    final patientName =
        '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}'.trim();
    final paidAt = DateTime.parse(payment['paid_at']).toLocal();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(clinicName, 'RECIBO DE PAGO'),
            pw.SizedBox(height: 24),
            _field('Recibo', payment['receipt_number']?.toString() ?? ''),
            _field('Factura', invoice['invoice_number']?.toString() ?? ''),
            _field('Paciente', patientName),
            _field('Fecha', DateFormat('dd/MM/yyyy HH:mm').format(paidAt)),
            _field(
              'Método',
              _methodLabel(payment['payment_method']?.toString()),
            ),
            if ((payment['reference']?.toString() ?? '').isNotEmpty)
              _field('Referencia', payment['reference'].toString()),
            pw.SizedBox(height: 24),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              color: PdfColors.blueGrey50,
              child: pw.Column(
                children: [
                  pw.Text(
                    'IMPORTE RECIBIDO',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    _money(billingMoney(payment['amount'])),
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Saldo pendiente: ${_money(invoiceBalance(invoice))}',
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(
      name: 'Recibo_${payment['receipt_number']}',
      onLayout: (_) => pdf.save(),
    );
  }

  static pw.Widget _header(String clinicName, String documentTitle) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
      child: pw.Column(
        children: [
          pw.Text(
            clinicName,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            documentTitle,
            style: const pw.TextStyle(color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _field(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: value),
        ],
      ),
    ),
  );

  static pw.Widget _totals(Map<String, dynamic> invoice) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Container(
      width: 250,
      child: pw.Column(
        children: [
          _totalRow('Subtotal', billingMoney(invoice['subtotal'])),
          _totalRow('Descuento', -billingMoney(invoice['discount'])),
          _totalRow('Impuestos', billingMoney(invoice['tax'])),
          pw.Divider(),
          _totalRow('Total', billingMoney(invoice['total']), bold: true),
          _totalRow('Pagado', invoicePaidAmount(invoice)),
          _totalRow('Saldo', invoiceBalance(invoice), bold: true),
        ],
      ),
    ),
  );

  static pw.Widget _totalRow(
    String label,
    double amount, {
    bool bold = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
        ),
        pw.Text(
          _money(amount),
          style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
        ),
      ],
    ),
  );

  static pw.Widget _footer() => pw.Center(
    child: pw.Text(
      'Documento generado por DentalSync. Conserve este comprobante.',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey600),
    ),
  );

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  static String _methodLabel(String? value) => switch (value) {
    'cash' => 'Efectivo',
    'card' => 'Tarjeta',
    'transfer' => 'Transferencia',
    _ => 'Otro',
  };
}
