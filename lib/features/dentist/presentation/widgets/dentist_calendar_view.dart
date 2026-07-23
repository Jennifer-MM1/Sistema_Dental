import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/quick_actions_dialogs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DentistCalendarView extends StatefulWidget {
  const DentistCalendarView({super.key});

  @override
  State<DentistCalendarView> createState() => _DentistCalendarViewState();
}

class _DentistCalendarViewState extends State<DentistCalendarView> {
  DateTime _weekStart = startOfCalendarWeek(DateTime.now());
  List<Map<String, dynamic>> _appointments = [];
  String? _clinicId;
  String? _currentDoctorId;
  String? _error;
  bool _loading = true;
  bool _onlyMyAppointments = false;

  @override
  void initState() {
    super.initState();
    _loadWeek();
  }

  Future<void> _loadWeek() async {
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
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .limit(1)
          .single();
      final clinicId = membership['clinic_id'] as String;
      final doctor = await client
          .from('doctors')
          .select('id')
          .eq('clinic_id', clinicId)
          .eq('user_id', user.id)
          .maybeSingle();
      final end = _weekStart.add(const Duration(days: 7));
      var query = client
          .from('appointments')
          .select(
            '*, patients(first_name,last_name), services(service_name,duration_mins), doctors(profiles(name))',
          )
          .eq('clinic_id', clinicId)
          .gte('date_time', _weekStart.toUtc().toIso8601String())
          .lt('date_time', end.toUtc().toIso8601String());
      if (_onlyMyAppointments && doctor != null) {
        query = query.eq('doctor_id', doctor['id']);
      }
      final rows = await query.order('date_time');
      if (!mounted) return;
      setState(() {
        _clinicId = clinicId;
        _currentDoctorId = doctor?['id'] as String?;
        _appointments = List<Map<String, dynamic>>.from(rows);
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo cargar el calendario: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeWeek(int weeks) async {
    setState(() => _weekStart = _weekStart.add(Duration(days: weeks * 7)));
    await _loadWeek();
  }

  Future<void> _today() async {
    setState(() => _weekStart = startOfCalendarWeek(DateTime.now()));
    await _loadWeek();
  }

  Future<void> _schedule() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(clinicId: clinicId),
    );
    if (created == true) await _loadWeek();
  }

  Future<void> _reschedule(Map<String, dynamic> appointment) async {
    final clinicId = _clinicId;
    if (clinicId == null || appointment['status'] != 'upcoming') return;
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(
        clinicId: clinicId,
        appointmentId: appointment['id'] as String,
        initialPatientId: appointment['patient_id'] as String,
        initialDoctorId: appointment['doctor_id'] as String,
        initialServiceId: appointment['service_id'] as String,
        initialDateTime: DateTime.parse(appointment['date_time']),
      ),
    );
    if (changed == true) await _loadWeek();
  }

  List<Map<String, dynamic>> _forDay(DateTime day) =>
      _appointments.where((item) {
        return DateUtils.isSameDay(
          DateTime.parse(item['date_time']).toLocal(),
          day,
        );
      }).toList();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _clinicId == null ? null : _schedule,
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendario semanal',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Consulta todas las citas de la clínica o únicamente las tuyas.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Toda la clínica'),
                  selected: !_onlyMyAppointments,
                  onSelected: (_) {
                    if (!_onlyMyAppointments) return;
                    setState(() => _onlyMyAppointments = false);
                    _loadWeek();
                  },
                ),
                ChoiceChip(
                  label: const Text('Sólo mis citas'),
                  selected: _onlyMyAppointments,
                  onSelected: _currentDoctorId == null
                      ? null
                      : (_) {
                          if (_onlyMyAppointments) return;
                          setState(() => _onlyMyAppointments = true);
                          _loadWeek();
                        },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _changeWeek(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '${DateFormat('dd MMM').format(_weekStart)} – ${DateFormat('dd MMM yyyy').format(_weekStart.add(const Duration(days: 6)))}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(onPressed: _today, child: const Text('Hoy')),
                  IconButton(
                    onPressed: () => _changeWeek(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  IconButton(
                    onPressed: _loadWeek,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 980
            ? (constraints.maxWidth - 72) / 7
            : 230.0;
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (index) {
                final day = _weekStart.add(Duration(days: index));
                return _dayColumn(day, width, index == 6);
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _dayColumn(DateTime day, double width, bool isLast) {
    final appointments = _forDay(day);
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    return Container(
      width: width,
      margin: EdgeInsets.only(right: isLast ? 0 : 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? AppColors.primaryBlue : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat('EEE dd').format(day),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isToday ? AppColors.primaryBlue : AppColors.textPrimary,
            ),
          ),
          const Divider(),
          if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Sin citas',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...appointments.map(_appointmentTile),
        ],
      ),
    );
  }

  Widget _appointmentTile(Map<String, dynamic> appointment) {
    final date = DateTime.parse(appointment['date_time']).toLocal();
    final patient = appointment['patients'];
    final doctorName = appointment['doctors']?['profiles']?['name'] as String?;
    final status = appointment['status']?.toString() ?? 'upcoming';
    return InkWell(
      onTap: status == 'upcoming' ? () => _reschedule(appointment) : null,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: status == 'cancelled'
              ? Colors.red.shade50
              : AppColors.lightBlueAccent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (status == 'upcoming')
                  const Icon(Icons.edit_calendar_outlined, size: 15),
              ],
            ),
            Text(
              '${patient?['first_name'] ?? ''} ${patient?['last_name'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              appointment['services']?['service_name'] ?? 'Consulta',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            if (doctorName != null)
              Text(
                'Dr. $doctorName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            Text(
              calendarAppointmentStatusLabel(status),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime startOfCalendarWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

String calendarAppointmentStatusLabel(String value) => switch (value) {
  'upcoming' => 'Programada',
  'in_lobby' => 'En espera',
  'in_treatment' => 'En consulta',
  'completed' => 'Completada',
  'cancelled' => 'Cancelada',
  _ => value,
};
