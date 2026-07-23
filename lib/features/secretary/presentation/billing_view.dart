import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/features/secretary/data/billing_receipt_pdf.dart';
import 'package:sistema_dental/features/secretary/data/billing_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingView extends StatefulWidget {
  const BillingView({super.key});

  @override
  State<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends State<BillingView> {
  late final BillingRepository _repository;
  List<Map<String, dynamic>> _invoices = [];
  String? _clinicId;
  String _clinicName = 'DentalSync';
  String _query = '';
  String _status = 'all';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = BillingRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw StateError('No hay una sesión activa.');
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .limit(1)
          .single();
      final clinicId = membership['clinic_id'] as String;
      final results = await Future.wait([
        _repository.getInvoices(clinicId),
        _repository.getClinicName(clinicId),
      ]);
      if (!mounted) return;
      setState(() {
        _clinicId = clinicId;
        _invoices = results[0] as List<Map<String, dynamic>>;
        _clinicName = results[1] as String;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().contains('invoices')
              ? 'El módulo contable aún no está instalado en Supabase. Aplica la migración 202607210001_billing.sql.'
              : 'No se pudo cargar la facturación: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _visibleInvoices {
    final query = _query.trim().toLowerCase();
    return _invoices.where((invoice) {
      if (_status != 'all' && invoice['status'] != _status) return false;
      final patient = invoice['patients'];
      final searchable = [
        invoice['invoice_number'],
        patient?['first_name'],
        patient?['last_name'],
      ].join(' ').toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _clinicId == null ? null : _createInvoice,
        icon: const Icon(Icons.add),
        label: const Text('Nueva factura'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          children: [
            const Text(
              'Facturación y pagos',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Control de saldos, pagos y comprobantes.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            if (_error != null)
              _errorCard()
            else ...[
              _summary(),
              const SizedBox(height: 20),
              _filters(),
              const SizedBox(height: 16),
              if (_visibleInvoices.isEmpty)
                _emptyState()
              else
                ..._visibleInvoices.map(_invoiceCard),
            ],
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    final valid = _invoices.where((invoice) => invoice['status'] != 'void');
    final total = valid.fold<double>(
      0,
      (sum, item) => sum + billingMoney(item['total']),
    );
    final paid = valid.fold<double>(
      0,
      (sum, item) => sum + invoicePaidAmount(item),
    );
    final balance = valid.fold<double>(
      0,
      (sum, item) => sum + invoiceBalance(item),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 720
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard('Facturado', total, Icons.receipt_long, width),
            _summaryCard('Cobrado', paid, Icons.payments, width),
            _summaryCard('Por cobrar', balance, Icons.pending_actions, width),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    double amount,
    IconData icon,
    double width,
  ) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  _money(amount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _filters() => Row(
    children: [
      Expanded(
        child: TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar factura o paciente',
            filled: true,
          ),
        ),
      ),
      const SizedBox(width: 12),
      DropdownButton<String>(
        value: _status,
        onChanged: (value) => setState(() => _status = value ?? 'all'),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Todas')),
          DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
          DropdownMenuItem(value: 'partial', child: Text('Parciales')),
          DropdownMenuItem(value: 'paid', child: Text('Pagadas')),
          DropdownMenuItem(value: 'void', child: Text('Anuladas')),
        ],
      ),
      IconButton(
        onPressed: _load,
        tooltip: 'Actualizar',
        icon: const Icon(Icons.refresh),
      ),
    ],
  );

  Widget _invoiceCard(Map<String, dynamic> invoice) {
    final patient = invoice['patients'];
    final appointment = invoice['appointments'];
    final patientName =
        '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}'.trim();
    final payments = invoice['payments'] is List
        ? List<Map<String, dynamic>>.from(invoice['payments'])
        : <Map<String, dynamic>>[];
    payments.sort((a, b) => (b['paid_at'] ?? '').compareTo(a['paid_at'] ?? ''));
    final status = invoice['status']?.toString() ?? 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(status == 'paid' ? Icons.check : Icons.receipt),
        ),
        title: Text('${invoice['invoice_number']} · $patientName'),
        subtitle: Text(
          '${appointment?['services']?['service_name'] ?? 'Servicio'} · ${_statusLabel(status)}',
        ),
        trailing: Text(
          _money(invoiceBalance(invoice)),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: invoiceBalance(invoice) == 0
                ? Colors.green
                : Colors.orange.shade800,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Column(
              children: [
                const Divider(),
                _amountRow('Total', billingMoney(invoice['total'])),
                _amountRow('Pagado', invoicePaidAmount(invoice)),
                _amountRow(
                  'Saldo pendiente',
                  invoiceBalance(invoice),
                  bold: true,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => BillingReceiptPdf.printInvoice(
                        clinicName: _clinicName,
                        invoice: invoice,
                      ),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir cuenta'),
                    ),
                    if (invoiceBalance(invoice) > 0 && status != 'void')
                      FilledButton.icon(
                        onPressed: () => _registerPayment(invoice),
                        icon: const Icon(Icons.payment),
                        label: const Text('Registrar pago'),
                      ),
                    if (payments.isEmpty && status != 'void')
                      TextButton.icon(
                        onPressed: () => _voidInvoice(invoice),
                        icon: const Icon(Icons.block),
                        label: const Text('Anular factura'),
                      ),
                  ],
                ),
                if (payments.isNotEmpty) ...[
                  const Divider(height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pagos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...payments.map((payment) {
                    final isVoided = payment['voided_at'] != null;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isVoided ? Icons.money_off : Icons.price_check,
                        color: isVoided ? Colors.red : null,
                      ),
                      title: Text(
                        '${payment['receipt_number']} · ${_money(billingMoney(payment['amount']))}',
                        style: TextStyle(
                          decoration: isVoided
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        isVoided
                            ? 'Pago anulado · ${payment['void_reason'] ?? ''}'
                            : '${_paymentMethod(payment['payment_method'])} · ${_dateTime(payment['paid_at'])}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Imprimir recibo',
                            onPressed: isVoided
                                ? null
                                : () => BillingReceiptPdf.printPayment(
                                    clinicName: _clinicName,
                                    invoice: invoice,
                                    payment: payment,
                                  ),
                            icon: const Icon(Icons.print_outlined),
                          ),
                          IconButton(
                            tooltip: 'Anular pago',
                            onPressed: isVoided
                                ? null
                                : () => _voidPayment(payment),
                            icon: const Icon(Icons.block, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvoice() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    final appointments = await _repository.getBillableAppointments(clinicId);
    if (!mounted) return;
    if (appointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay citas completadas pendientes de facturar.'),
        ),
      );
      return;
    }
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateInvoiceDialog(
        appointments: appointments,
        repository: _repository,
      ),
    );
    if (created == true) await _load();
  }

  Future<void> _registerPayment(Map<String, dynamic> invoice) async {
    final paymentId = await showDialog<String>(
      context: context,
      builder: (_) => _PaymentDialog(invoice: invoice, repository: _repository),
    );
    if (paymentId == null) return;
    await _load();
    if (!mounted) return;
    final refreshed = _invoices
        .where((item) => item['id'] == invoice['id'])
        .firstOrNull;
    if (refreshed == null) return;
    final payment = (refreshed['payments'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .where((item) => item['id'].toString() == paymentId)
        .firstOrNull;
    if (payment != null) {
      await BillingReceiptPdf.printPayment(
        clinicName: _clinicName,
        invoice: refreshed,
        payment: payment,
      );
    }
  }

  Future<void> _voidInvoice(Map<String, dynamic> invoice) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anular factura'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Motivo de anulación'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 5) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    try {
      await _repository.voidInvoice(invoiceId: invoice['id'], reason: reason);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _voidPayment(Map<String, dynamic> payment) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anular pago'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Motivo de anulación'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 5) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Anular pago'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    try {
      await _repository.voidPayment(paymentId: payment['id'], reason: reason);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Widget _amountRow(String label, double value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
        Text(
          _money(value),
          style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      ],
    ),
  );

  Widget _errorCard() => Card(
    color: Colors.red.shade50,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!)),
          TextButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      ),
    ),
  );

  Widget _emptyState() => const Card(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: Text('No hay facturas con estos filtros.')),
    ),
  );

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Operación no completada: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _statusLabel(String value) => switch (value) {
    'paid' => 'Pagada',
    'partial' => 'Pago parcial',
    'void' => 'Anulada',
    _ => 'Pendiente',
  };
  String _paymentMethod(dynamic value) => switch (value) {
    'cash' => 'Efectivo',
    'card' => 'Tarjeta',
    'transfer' => 'Transferencia',
    _ => 'Otro',
  };
  String _dateTime(dynamic value) => DateFormat(
    'dd/MM/yyyy HH:mm',
  ).format(DateTime.parse(value.toString()).toLocal());
  String _money(double value) => '\$${value.toStringAsFixed(2)}';
}

class _CreateInvoiceDialog extends StatefulWidget {
  const _CreateInvoiceDialog({
    required this.appointments,
    required this.repository,
  });
  final List<Map<String, dynamic>> appointments;
  final BillingRepository repository;

  @override
  State<_CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<_CreateInvoiceDialog> {
  String? _appointmentId;
  final _discount = TextEditingController(text: '0');
  final _tax = TextEditingController(text: '0');
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _discount.dispose();
    _tax.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final appointmentId = _appointmentId;
    if (appointmentId == null) return;
    setState(() => _saving = true);
    try {
      await widget.repository.createInvoice(
        appointmentId: appointmentId,
        discount: double.tryParse(_discount.text) ?? 0,
        tax: double.tryParse(_tax.text) ?? 0,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nueva factura'),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _appointmentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Cita completada'),
              items: widget.appointments.map((appointment) {
                final patient = appointment['patients'];
                final name =
                    '${patient?['first_name']} ${patient?['last_name']}';
                final service = appointment['services'];
                return DropdownMenuItem(
                  value: appointment['id'] as String,
                  child: Text(
                    '$name · ${service?['service_name']} · \$${billingMoney(service?['price']).toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _appointmentId = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Descuento \$',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tax,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Impuestos \$',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notas opcionales'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('Crear factura'),
      ),
    ],
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.invoice, required this.repository});
  final Map<String, dynamic> invoice;
  final BillingRepository repository;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amount;
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: invoiceBalance(widget.invoice).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_amount.text) ?? 0;
    if (value <= 0 || value > invoiceBalance(widget.invoice)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El importe debe ser positivo y no superar el saldo.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await widget.repository.registerPayment(
        invoiceId: widget.invoice['id'],
        amount: value,
        paymentMethod: _method,
        reference: _reference.text,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context, id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Registrar pago'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Saldo: \$${invoiceBalance(widget.invoice).toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Importe'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Método'),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
              DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
              DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
              DropdownMenuItem(value: 'other', child: Text('Otro')),
            ],
            onChanged: (value) => setState(() => _method = value ?? 'cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reference,
            decoration: const InputDecoration(labelText: 'Referencia'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notas'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: const Text('Guardar e imprimir'),
      ),
    ],
  );
}
