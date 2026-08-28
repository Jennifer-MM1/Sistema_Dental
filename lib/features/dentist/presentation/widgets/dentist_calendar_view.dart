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
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = startOfCalendarWeek(DateTime.now());
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _patients = [];
  String _patientSearch = '';
  String? _clinicId;
  String? _currentDoctorId;
  String? _error;
  bool _loading = true;
  bool _onlyMyAppointments = false;
  bool _isMonthView = true;

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
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

      DateTime start;
      DateTime end;

      if (_isMonthView) {
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      } else {
        start = _weekStart;
        end = _weekStart.add(const Duration(days: 7));
      }

      var query = client
          .from('appointments')
          .select(
            '*, patients(first_name,last_name), services(service_name,duration_mins), doctors(profiles(name))',
          )
          .eq('clinic_id', clinicId)
          .gte('date_time', start.toUtc().toIso8601String())
          .lt('date_time', end.toUtc().toIso8601String());

      if (_onlyMyAppointments && doctor != null) {
        query = query.eq('doctor_id', doctor['id']);
      }
      final rows = await query.order('date_time');

      final patientsRows = await client
          .from('patients')
          .select('id, first_name, last_name, relationship')
          .eq('clinic_id', clinicId)
          .order('first_name');

      if (!mounted) return;
      setState(() {
        _clinicId = clinicId;
        _currentDoctorId = doctor?['id'] as String?;
        _appointments = List<Map<String, dynamic>>.from(rows);
        _patients = List<Map<String, dynamic>>.from(patientsRows);
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

  Future<void> _changeMonth(int months) async {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + months, 1);
    });
    await _loadAgenda();
  }

  Future<void> _changeWeek(int weeks) async {
    setState(() => _weekStart = _weekStart.add(Duration(days: weeks * 7)));
    await _loadAgenda();
  }

  Future<void> _today() async {
    setState(() {
      _selectedDate = DateTime.now();
      _weekStart = startOfCalendarWeek(DateTime.now());
    });
    await _loadAgenda();
  }

  Future<void> _schedule() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(clinicId: clinicId),
    );
    if (created == true) await _loadAgenda();
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
    if (changed == true) await _loadAgenda();
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
        padding: EdgeInsets.all(isDesktop ? 24 : 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calendario Clínico',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Consulta la agenda del mes o de la semana y gestiona pacientes.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Vista Mensual'),
                    selected: _isMonthView,
                    onSelected: (val) {
                      if (!val || _isMonthView) return;
                      setState(() => _isMonthView = true);
                      _loadAgenda();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Vista Semanal'),
                    selected: !_isMonthView,
                    onSelected: (val) {
                      if (!val || !_isMonthView) return;
                      setState(() => _isMonthView = false);
                      _loadAgenda();
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Toda la clínica'),
                    selected: !_onlyMyAppointments,
                    onSelected: (_) {
                      if (!_onlyMyAppointments) return;
                      setState(() => _onlyMyAppointments = false);
                      _loadAgenda();
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
                            _loadAgenda();
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHeaderCard(),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: isDesktop ? 980 : 850,
                  child: _isMonthView ? _buildMonthGrid() : _content(),
                ),
              ),
              const SizedBox(height: 24),
              _buildPatientsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final titleStr = _isMonthView
        ? DateFormat('MMMM yyyy').format(_selectedDate)
        : '${DateFormat('dd MMM').format(_weekStart)} – ${DateFormat('dd MMM yyyy').format(_weekStart.add(const Duration(days: 6)))}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _isMonthView ? _changeMonth(-1) : _changeWeek(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                titleStr.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            TextButton(onPressed: _today, child: const Text('Hoy')),
            IconButton(
              onPressed: () => _isMonthView ? _changeMonth(1) : _changeWeek(1),
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              onPressed: _loadAgenda,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }

    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;

    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: weekDays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: (firstWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - (firstWeekday - 1) + 1;
              final dayDate = DateTime(year, month, dayNumber);
              final isToday = DateUtils.isSameDay(dayDate, DateTime.now());
              final dayAppts = _forDay(dayDate);

              return InkWell(
                onTap: () {
                  if (dayAppts.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Citas del ${DateFormat('dd/MM/yyyy').format(dayDate)}'),
                        content: SizedBox(
                          width: 400,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: dayAppts.length,
                            itemBuilder: (ctx, idx) => _appointmentTile(dayAppts[idx]),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.lightBlueAccent : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday ? AppColors.primaryBlue : Colors.grey.shade200,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isToday ? AppColors.primaryBlue : AppColors.textPrimary,
                        ),
                      ),
                      if (dayAppts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${dayAppts.length} cita${dayAppts.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Libre',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsSection() {
    final filtered = _patientSearch.isEmpty
        ? _patients
        : _patients.where((p) {
            final name = '${p['first_name']} ${p['last_name']}'.toLowerCase();
            return name.contains(_patientSearch.toLowerCase());
          }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt, color: AppColors.primaryBlue, size: 22),
              const SizedBox(width: 10),
              Text(
                'Lista de Pacientes Clínicos (${_patients.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => setState(() => _patientSearch = val),
            decoration: InputDecoration(
              hintText: 'Buscar paciente por nombre...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),
          filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No se encontraron pacientes registrados.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final fullName = '${p['first_name']} ${p['last_name']}';
                    final relationship = p['relationship'] ?? 'Paciente';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.lightBlueAccent,
                        child: Icon(Icons.person, color: AppColors.primaryBlue),
                      ),
                      title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Relación: $relationship'),
                      trailing: ElevatedButton.icon(
                        onPressed: () async {
                          final clinicId = _clinicId;
                          if (clinicId == null) return;
                          final created = await showDialog<bool>(
                            context: context,
                            builder: (_) => ScheduleAppointmentDialog(
                              clinicId: clinicId,
                              initialPatientId: p['id'] as String,
                            ),
                          );
                          if (created == true) await _loadAgenda();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Agendar Cita'),
                      ),
                    );
                  },
                ),
        ],
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
