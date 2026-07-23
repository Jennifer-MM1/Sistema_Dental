import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';

class AddPatientDialog extends StatefulWidget {
  final String clinicId;
  const AddPatientDialog({super.key, required this.clinicId});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClientId;
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _dateOfBirth;
  String _relationship = 'self';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    final client = Supabase.instance.client;
    try {
      final res = await client
          .from('clinic_memberships')
          .select('user_id, profiles(name, email)')
          .eq('clinic_id', widget.clinicId)
          .eq('role_in_clinic', 'client')
          .eq('is_active', true);

      if (mounted) {
        setState(() {
          _clients = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching clients: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate() || _selectedClientId == null) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.rpc(
        'create_clinic_patient',
        params: {
          'p_clinic_id': widget.clinicId,
          'p_profile_id': _selectedClientId,
          'p_first_name': _firstNameController.text.trim(),
          'p_last_name': _lastNameController.text.trim(),
          'p_date_of_birth': _dateOfBirth?.toIso8601String().split('T').first,
          'p_relationship': _relationship,
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente registrado con éxito')),
        );
      }
    } catch (e) {
      debugPrint('Error saving patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Registrar Nuevo Paciente'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_clients.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withAlpha(12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'No hay clientes activos en esta clínica. Primero vincula al cliente con una invitación y después registra su paciente.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Cliente/Tutor',
                            helperText:
                                'El paciente quedará asociado a este cliente.',
                          ),
                          initialValue: _selectedClientId,
                          hint: const Text('Selecciona un cliente'),
                          items: _clients.map((c) {
                            final profile =
                                c['profiles'] as Map<String, dynamic>?;
                            final name =
                                profile?['name'] ??
                                profile?['email'] ??
                                'Cliente';
                            return DropdownMenuItem(
                              value: c['user_id'] as String,
                              child: Text(name.toString()),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedClientId = val),
                          validator: (val) =>
                              val == null ? 'Selecciona un cliente' : null,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido',
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_clients.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Relación con el cliente',
                          ),
                          initialValue: _relationship,
                          items: const [
                            DropdownMenuItem(
                              value: 'self',
                              child: Text('Él/Ella mismo/a'),
                            ),
                            DropdownMenuItem(
                              value: 'child',
                              child: Text('Hijo/a'),
                            ),
                            DropdownMenuItem(
                              value: 'spouse',
                              child: Text('Cónyuge'),
                            ),
                            DropdownMenuItem(
                              value: 'parent',
                              child: Text('Padre/Madre'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Otro'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _relationship = val!),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _dateOfBirth == null
                              ? 'Seleccionar Fecha de Nacimiento'
                              : 'Nacimiento: ${DateFormat('dd/MM/yyyy').format(_dateOfBirth!)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _dateOfBirth = date);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePatient,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// Schedule Appointment Dialog
// ----------------------------------------------------

class ScheduleAppointmentDialog extends StatefulWidget {
  final String clinicId;
  final String? initialPatientId;
  final String? appointmentId;
  final String? initialDoctorId;
  final String? initialServiceId;
  final DateTime? initialDateTime;

  const ScheduleAppointmentDialog({
    super.key,
    required this.clinicId,
    this.initialPatientId,
    this.appointmentId,
    this.initialDoctorId,
    this.initialServiceId,
    this.initialDateTime,
  });

  @override
  State<ScheduleAppointmentDialog> createState() =>
      _ScheduleAppointmentDialogState();
}

class _ScheduleAppointmentDialogState extends State<ScheduleAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _services = [];

  String? _selectedPatientId;
  String? _selectedDoctorId;
  String? _selectedServiceId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
    _selectedDoctorId = widget.initialDoctorId;
    _selectedServiceId = widget.initialServiceId;
    final initialDateTime = widget.initialDateTime?.toLocal();
    if (initialDateTime != null) {
      _selectedDate = DateTime(
        initialDateTime.year,
        initialDateTime.month,
        initialDateTime.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(initialDateTime);
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    final client = Supabase.instance.client;
    try {
      final patientsRes = await client
          .from('patients')
          .select('id, profile_id, first_name, last_name, profiles!inner(name)')
          .eq('clinic_id', widget.clinicId)
          .order('first_name');
      _patients = List<Map<String, dynamic>>.from(patientsRes);
      if (_selectedPatientId != null &&
          !_patients.any((patient) => patient['id'] == _selectedPatientId)) {
        _selectedPatientId = null;
      }

      // 2. Fetch doctors
      final docsRes = await client
          .from('doctors')
          .select('id, profiles(name)')
          .eq('clinic_id', widget.clinicId)
          .eq('is_available', true);
      _doctors = List<Map<String, dynamic>>.from(docsRes);
      if (_selectedDoctorId != null &&
          !_doctors.any((doctor) => doctor['id'] == _selectedDoctorId)) {
        _selectedDoctorId = null;
      }

      // 3. Fetch services
      final servsRes = await client
          .from('services')
          .select('id, service_name, price, duration_mins')
          .eq('clinic_id', widget.clinicId);
      _services = List<Map<String, dynamic>>.from(servsRes);
      if (_selectedServiceId != null &&
          !_services.any((service) => service['id'] == _selectedServiceId)) {
        _selectedServiceId = null;
      }

      if (mounted) {
        setState(() {
          _loadError = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch dialog data: $e');
      if (mounted) {
        setState(() {
          _loadError =
              'No se pudieron cargar pacientes, dentistas o servicios. '
              'Actualiza e intenta nuevamente.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final localDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final client = Supabase.instance.client;
      final service = _services.firstWhere(
        (item) => item['id'] == _selectedServiceId,
      );
      final duration = (service['duration_mins'] as num?)?.toInt() ?? 30;
      final repository = AppointmentRepository(client);
      if (widget.appointmentId != null) {
        await repository.rescheduleAppointment(
          appointmentId: widget.appointmentId!,
          clinicId: widget.clinicId,
          doctorId: _selectedDoctorId!,
          serviceId: _selectedServiceId!,
          localStart: localDateTime,
          durationMinutes: duration,
        );
      } else {
        final validation = await repository.validateAppointmentSlot(
          clinicId: widget.clinicId,
          doctorId: _selectedDoctorId!,
          localStart: localDateTime,
          durationMinutes: duration,
        );
        if (!validation.isValid) throw StateError(validation.message!);
        await client.from('appointments').insert({
          'clinic_id': widget.clinicId,
          'patient_id': _selectedPatientId,
          'doctor_id': _selectedDoctorId,
          'service_id': _selectedServiceId,
          'date_time': localDateTime.toUtc().toIso8601String(),
          'status': 'upcoming',
        });
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.appointmentId == null
                  ? 'Cita agendada exitosamente'
                  : 'Cita reprogramada exitosamente',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error scheduling appt: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createService() async {
    final service = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CreateServiceDialog(clinicId: widget.clinicId),
    );
    if (service == null || !mounted) return;

    setState(() {
      _services.add(service);
      _services.sort(
        (a, b) => (a['service_name'] as String).compareTo(
          b['service_name'] as String,
        ),
      );
      _selectedServiceId = service['id'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        widget.appointmentId == null ? 'Agendar Cita' : 'Reprogramar Cita',
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _loadError != null
          ? SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _loadError = null;
                      });
                      _fetchData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : SizedBox(
              width: 760,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Paciente',
                        ),
                        initialValue: _selectedPatientId,
                        items: _patients.map((p) {
                          final profile =
                              p['profiles'] as Map<String, dynamic>?;
                          final tutorName =
                              profile?['name'] as String? ?? 'Cliente';
                          return DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(
                              '${p['first_name']} ${p['last_name']} (Tutor: $tutorName)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPatientId = val),
                        validator: (val) => val == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Doctor'),
                        initialValue: _selectedDoctorId,
                        items: _doctors.map((d) {
                          return DropdownMenuItem(
                            value: d['id'] as String,
                            child: Text('Dr. ${d['profiles']['name']}'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedDoctorId = val),
                        validator: (val) => val == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_services.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withAlpha(12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryBlue.withAlpha(55),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Esta clínica todavía no tiene servicios registrados.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: _createService,
                                icon: const Icon(Icons.add),
                                label: const Text('Registrar primer servicio'),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Servicio',
                                ),
                                initialValue: _selectedServiceId,
                                items: _services.map((s) {
                                  return DropdownMenuItem(
                                    value: s['id'] as String,
                                    child: Text(
                                      '${s['service_name']} (\$${s['price']})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedServiceId = val),
                                validator: (val) =>
                                    val == null ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Registrar servicio',
                              onPressed: _createService,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text(
                                _selectedDate == null
                                    ? 'Fecha'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(_selectedDate!),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final now = DateTime.now();
                                final today = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate ?? today,
                                  firstDate: today,
                                  lastDate: today.add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (d != null) {
                                  setState(() => _selectedDate = d);
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text(
                                _selectedTime == null
                                    ? 'Hora'
                                    : _selectedTime!.format(context),
                              ),
                              trailing: const Icon(Icons.access_time),
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(
                                    hour: 9,
                                    minute: 0,
                                  ),
                                );
                                if (t != null) {
                                  setState(() => _selectedTime = t);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.appointmentId == null ? 'Agendar' : 'Reprogramar',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  const _CreateServiceDialog({required this.clinicId});

  final String clinicId;

  @override
  State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final price = double.parse(_priceController.text.replaceAll(',', '.'));
      final duration = int.parse(_durationController.text);
      final result = await Supabase.instance.client.rpc(
        'create_clinic_service',
        params: {
          'p_clinic_id': widget.clinicId,
          'p_service_name': _nameController.text.trim(),
          'p_price': price,
          'p_duration_mins': duration,
        },
      );

      if (mounted) {
        Navigator.pop(context, Map<String, dynamic>.from(result as Map));
      }
    } on PostgrestException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        '42501' =>
          'No se encontró una membresía activa de dentista en esta clínica.',
        'PGRST202' => 'Falta actualizar la función de servicios en Supabase.',
        _ => 'No se pudo registrar el servicio: ${error.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar el servicio: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar servicio'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  hintText: 'Ej. Limpieza dental',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el nombre del servicio'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final price = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  return price == null || price < 0
                      ? 'Escribe un precio válido'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración en minutos',
                ),
                validator: (value) {
                  final duration = int.tryParse(value ?? '');
                  return duration == null || duration <= 0 || duration > 480
                      ? 'Usa una duración entre 1 y 480 minutos'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
