import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

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

  Future<void> _fetchClients() async {
    final client = Supabase.instance.client;
    try {
      final res = await client
          .from('clinic_memberships')
          .select('user_id, profiles(name, email)')
          .eq('clinic_id', widget.clinicId)
          .eq('role_in_clinic', 'client')
          .eq('is_active', true);
      
      setState(() {
        _clients = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching clients: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate() || _selectedClientId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final client = Supabase.instance.client;
      await client.from('patients').insert({
        'profile_id': _selectedClientId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'date_of_birth': _dateOfBirth?.toIso8601String(),
        'relationship': _relationship,
      });
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paciente registrado con éxito')));
      }
    } catch (e) {
      debugPrint('Error saving patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Nuevo Paciente'),
      content: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Seleccionar Cliente (Tutor)'),
                      value: _selectedClientId,
                      items: _clients.map((c) {
                        final name = c['profiles']['name'] ?? c['profiles']['email'];
                        return DropdownMenuItem(
                          value: c['user_id'] as String,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedClientId = val),
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Relación con el cliente'),
                      value: _relationship,
                      items: const [
                        DropdownMenuItem(value: 'self', child: Text('Él/Ella mismo/a')),
                        DropdownMenuItem(value: 'child', child: Text('Hijo/a')),
                        DropdownMenuItem(value: 'spouse', child: Text('Cónyuge')),
                        DropdownMenuItem(value: 'parent', child: Text('Padre/Madre')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (val) => setState(() => _relationship = val!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_dateOfBirth == null 
                          ? 'Seleccionar Fecha de Nacimiento' 
                          : 'Nacimiento: ${DateFormat('dd/MM/yyyy').format(_dateOfBirth!)}'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _savePatient,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar', style: TextStyle(color: Colors.white)),
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
  const ScheduleAppointmentDialog({super.key, required this.clinicId});

  @override
  State<ScheduleAppointmentDialog> createState() => _ScheduleAppointmentDialogState();
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final client = Supabase.instance.client;
    try {
      // 1. Fetch patients
      final clientsRes = await client
          .from('clinic_memberships')
          .select('user_id')
          .eq('clinic_id', widget.clinicId)
          .eq('role_in_clinic', 'client');
          
      if (clientsRes.isNotEmpty) {
        final clientIds = clientsRes.map((c) => c['user_id']).toList();
        final patientsRes = await client
            .from('patients')
            .select('id, first_name, last_name, profiles(name)')
            .inFilter('profile_id', clientIds);
        _patients = List<Map<String, dynamic>>.from(patientsRes);
      }
      
      // 2. Fetch doctors
      final docsRes = await client
          .from('clinic_memberships')
          .select('user_id, profiles(name)')
          .eq('clinic_id', widget.clinicId)
          .inFilter('role_in_clinic', ['dentist', 'owner'])
          .eq('is_active', true);
      _doctors = List<Map<String, dynamic>>.from(docsRes);
      
      // 3. Fetch services
      final servsRes = await client
          .from('services')
          .select('id, service_name, price, duration_mins')
          .eq('clinic_id', widget.clinicId);
      _services = List<Map<String, dynamic>>.from(servsRes);
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetch dialog data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final dateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      ).toUtc().toIso8601String();
      
      final client = Supabase.instance.client;
      await client.from('appointments').insert({
        'clinic_id': widget.clinicId,
        'patient_id': _selectedPatientId,
        'doctor_id': _selectedDoctorId,
        'service_id': _selectedServiceId,
        'date_time': dateTime,
        'status': 'upcoming',
      });
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita agendada exitosamente')));
      }
    } catch (e) {
      debugPrint('Error scheduling appt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agendar Cita'),
      content: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Paciente'),
                      value: _selectedPatientId,
                      items: _patients.map((p) {
                        return DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text('${p['first_name']} ${p['last_name']} (Tutor: ${p['profiles']['name']})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPatientId = val),
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Doctor'),
                      value: _selectedDoctorId,
                      items: _doctors.map((d) {
                        return DropdownMenuItem(
                          value: d['user_id'] as String,
                          child: Text('Dr. ${d['profiles']['name']}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDoctorId = val),
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Servicio'),
                      value: _selectedServiceId,
                      items: _services.map((s) {
                        return DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text('${s['service_name']} (\$${s['price']})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedServiceId = val),
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(_selectedDate == null ? 'Fecha' : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => _selectedDate = d);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(_selectedTime == null ? 'Hora' : _selectedTime!.format(context)),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                              if (t != null) setState(() => _selectedTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAppointment,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Agendar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
