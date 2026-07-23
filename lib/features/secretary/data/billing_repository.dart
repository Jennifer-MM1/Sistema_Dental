import 'package:supabase_flutter/supabase_flutter.dart';

double billingMoney(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class BillingRepository {
  BillingRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getInvoices(String clinicId) async {
    final rows = await _client
        .from('invoices')
        .select(
          '*, patients(first_name,last_name), appointments(date_time, services(service_name), doctors(profiles(name))), payments(*)',
        )
        .eq('clinic_id', clinicId)
        .order('issued_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getBillableAppointments(
    String clinicId,
  ) async {
    final invoiced = await _client
        .from('invoices')
        .select('appointment_id')
        .eq('clinic_id', clinicId)
        .not('appointment_id', 'is', null);
    final invoicedIds = invoiced
        .map((row) => row['appointment_id']?.toString())
        .whereType<String>()
        .toSet();

    final rows = await _client
        .from('appointments')
        .select(
          'id,date_time,patients(first_name,last_name),services(service_name,price),doctors(profiles(name))',
        )
        .eq('clinic_id', clinicId)
        .eq('status', 'completed')
        .order('date_time', ascending: false);
    return List<Map<String, dynamic>>.from(
      rows.where((row) => !invoicedIds.contains(row['id']?.toString())),
    );
  }

  Future<String> getClinicName(String clinicId) async {
    final row = await _client
        .from('clinics')
        .select('business_name')
        .eq('id', clinicId)
        .single();
    return row['business_name']?.toString() ?? 'DentalSync';
  }

  Future<String> createInvoice({
    required String appointmentId,
    double discount = 0,
    double tax = 0,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'create_invoice_for_appointment',
      params: {
        'p_appointment_id': appointmentId,
        'p_discount': discount,
        'p_tax': tax,
        'p_notes': notes,
      },
    );
    return result.toString();
  }

  Future<String> registerPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final result = await _client.rpc(
      'register_invoice_payment',
      params: {
        'p_invoice_id': invoiceId,
        'p_amount': amount,
        'p_payment_method': paymentMethod,
        'p_reference': reference,
        'p_notes': notes,
      },
    );
    return result.toString();
  }

  Future<void> voidInvoice({
    required String invoiceId,
    required String reason,
  }) async {
    await _client.rpc(
      'void_invoice',
      params: {'p_invoice_id': invoiceId, 'p_reason': reason},
    );
  }

  Future<void> voidPayment({
    required String paymentId,
    required String reason,
  }) async {
    await _client.rpc(
      'void_payment',
      params: {'p_payment_id': paymentId, 'p_reason': reason},
    );
  }
}

double invoicePaidAmount(Map<String, dynamic> invoice) {
  final payments = invoice['payments'];
  if (payments is! List) return 0;
  return payments
      .where((payment) => payment is Map && payment['voided_at'] == null)
      .fold<double>(0, (sum, payment) => sum + billingMoney(payment['amount']));
}

double invoiceBalance(Map<String, dynamic> invoice) {
  final balance = billingMoney(invoice['total']) - invoicePaidAmount(invoice);
  return balance < 0.005 ? 0 : balance;
}
