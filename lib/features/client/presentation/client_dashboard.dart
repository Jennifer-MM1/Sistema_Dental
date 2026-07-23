import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/client/data/notification_repository.dart';
import 'package:sistema_dental/features/client/data/patient_repository.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';
import 'package:sistema_dental/features/client/presentation/widgets/patient_selector.dart';
import 'package:sistema_dental/features/client/presentation/widgets/patient_clinical_history_view.dart';
import 'package:sistema_dental/features/shared/presentation/user_profile_view.dart';
import 'package:sistema_dental/core/models/appointment.dart';
import 'package:intl/intl.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  int _selectedIndex = 0;
  String _userName = 'Cliente';
  String _clinicName = 'Clínica';

  static const _sections = [
    (Icons.grid_view, 'Inicio'),
    (Icons.calendar_month_outlined, 'Mis citas'),
    (Icons.medical_information_outlined, 'Historial clínico'),
    (Icons.settings_outlined, 'Configuración'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSidebarProfile();
  }

  Future<void> _loadSidebarProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      final membership = await client
          .from('clinic_memberships')
          .select('clinics(business_name)')
          .eq('user_id', user.id)
          .eq('role_in_clinic', 'client')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _userName = profile?['name'] as String? ?? user.email ?? 'Cliente';
        _clinicName =
            membership?['clinics']?['business_name'] as String? ?? 'Clínica';
      });
    } catch (error) {
      debugPrint('Error al cargar el perfil del cliente: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: AppColors.primaryBlue),
              title: const Text(
                'DentalSync',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildTopBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'DentalSync',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _sections.length; index++)
            _buildSidebarItem(index, _sections[index].$1, _sections[index].$2),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => _selectSection(3),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.lightBlueAccent,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            'Cliente / paciente',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final selected = _selectedIndex == index;
    return InkWell(
      onTap: () => _selectSection(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSection(int index) {
    setState(() => _selectedIndex = index);
    if (MediaQuery.of(context).size.width <= 900 &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sections[_selectedIndex].$2,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _clinicName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedIndex == 3)
            IconButton(
              tooltip: 'Ayuda',
              onPressed: _showProfileHelp,
              icon: const Icon(Icons.help_outline),
            ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) async {
              if (value == 'mode') {
                context.go('/mode_selector');
              } else if (value == 'logout') {
                await ref.read(loginProvider.notifier).logout();
                if (mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'mode',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz),
                    SizedBox(width: 8),
                    Text('Cambiar modo'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) {
      return const ClientScheduleView();
    } else if (_selectedIndex == 2) {
      return const Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: PatientSelector(),
          ),
          Expanded(child: PatientClinicalHistoryView()),
        ],
      );
    } else if (_selectedIndex == 3) {
      return const ClientProfileView();
    }

    // Vista Home
    return const ClientHomeView();
  }

  void _showProfileHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ayuda de perfil'),
        content: const Text(
          'Desde esta sección puedes actualizar tus datos, cambiar tu contraseña, configurar recordatorios y vincular un smartwatch.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Vista: Home
// ----------------------------------------------------
class ClientHomeView extends ConsumerStatefulWidget {
  const ClientHomeView({super.key});

  @override
  ConsumerState<ClientHomeView> createState() => _ClientHomeViewState();
}

class _ClientHomeViewState extends ConsumerState<ClientHomeView> {
  Map<String, dynamic>? _nextAppointment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNextAppointment();
  }

  Future<void> _fetchNextAppointment() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final patientRes = await client
          .from('patients')
          .select('id')
          .eq('profile_id', user.id);
      if (patientRes.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final patientIds = patientRes.map((p) => p['id']).toList();

      final apptRes = await client
          .from('appointments')
          .select('*, doctors(profiles(name)), services(service_name)')
          .inFilter('patient_id', patientIds)
          .gte('date_time', DateTime.now().toUtc().toIso8601String())
          .order('date_time', ascending: true)
          .limit(1);

      if (apptRes.isNotEmpty) {
        _nextAppointment = apptRes[0];
      }
    } catch (e) {
      debugPrint('Error fetching next appointment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.value?.name ?? 'Paciente';
    final selectedPatient = ref.watch(selectedPatientProvider);
    final displayFirstName =
        selectedPatient?.firstName ?? userName.split(' ').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatientSelector(),
          Text(
            '¡Hola, $displayFirstName!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu salud dental es nuestra prioridad hoy.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_nextAppointment != null)
            _buildNextAppointmentCard(_nextAppointment!)
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  'No tienes citas próximas.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(Map<String, dynamic> appt) {
    final date = DateTime.parse(appt['date_time']).toLocal();
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    final timeStr = DateFormat('HH:mm').format(date);
    final doctorName = appt['doctors']?['profiles']?['name'] ?? 'Doctor';
    final serviceName = appt['services']?['service_name'] ?? 'Consulta General';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRÓXIMA CITA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            serviceName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dr. $doctorName',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(dateStr, style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(timeStr, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Vista: Records
// ----------------------------------------------------
class ClientRecordsView extends StatefulWidget {
  const ClientRecordsView({super.key});

  @override
  State<ClientRecordsView> createState() => _ClientRecordsViewState();
}

class _ClientRecordsViewState extends State<ClientRecordsView> {
  List<dynamic> _completedAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final patientRes = await client
          .from('patients')
          .select('id')
          .eq('profile_id', user.id);
      if (patientRes.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final patientIds = patientRes.map((p) => p['id']).toList();

      final apptRes = await client
          .from('appointments')
          .select('*, doctors(profiles(name)), services(service_name)')
          .inFilter('patient_id', patientIds)
          .eq('status', 'completed')
          .order('date_time', ascending: false);

      setState(() {
        _completedAppointments = apptRes;
      });
    } catch (e) {
      debugPrint('Error fetching records: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text(
          'Historial clínico',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        if (_completedAppointments.isEmpty)
          const Text(
            'No hay registros médicos disponibles.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ..._completedAppointments.map((appt) {
            final date = DateTime.parse(appt['date_time']).toLocal();
            final doctorName =
                appt['doctors']?['profiles']?['name'] ?? 'Doctor';
            final serviceName = appt['services']?['service_name'] ?? 'Consulta';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lightBlueAccent,
                  child: Icon(Icons.check_circle, color: AppColors.primaryBlue),
                ),
                title: Text(
                  serviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Dr. $doctorName · ${DateFormat('dd/MM/yyyy').format(date)}',
                ),
              ),
            );
          }),
      ],
    );
  }
}

// Vista de Schedule (Segunda pestaña)
class ClientScheduleView extends ConsumerStatefulWidget {
  const ClientScheduleView({super.key});

  @override
  ConsumerState<ClientScheduleView> createState() => _ClientScheduleViewState();
}

class _ClientScheduleViewState extends ConsumerState<ClientScheduleView> {
  String _filter = 'upcoming';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(clientAppointmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatientSelector(),
          const SizedBox(height: 16),
          const Text(
            'Mis citas',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _search = value.trim()),
            decoration: InputDecoration(
              hintText: 'Buscar por dentista o servicio',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _filterChip('upcoming', 'Próximas'),
              _filterChip('completed', 'Anteriores'),
              _filterChip('cancelled', 'Canceladas'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  const Center(child: Text('No se pudieron cargar las citas.')),
              data: _buildAppointments,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildAppointments(List<Appointment> appointments) {
    bool matchesStatus(Appointment appointment) {
      if (_filter == 'upcoming') {
        return const {
          'upcoming',
          'in_lobby',
          'in_treatment',
        }.contains(appointment.status);
      }
      return appointment.status == _filter;
    }

    bool matchesSearch(Appointment appointment) {
      if (_search.isEmpty) return true;
      final text =
          '${appointment.doctorName ?? ''} '
                  '${appointment.serviceName ?? ''}'
              .toLowerCase();
      return text.contains(_search.toLowerCase());
    }

    final filtered = appointments
        .where((item) => matchesStatus(item) && matchesSearch(item))
        .toList();
    final active = _filter == 'upcoming'
        ? filtered
              .where(
                (item) =>
                    item.status == 'in_lobby' || item.status == 'in_treatment',
              )
              .firstOrNull
        : null;
    final remaining = filtered.where((item) => item.id != active?.id).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _search.isEmpty
              ? 'No hay citas en esta categoría.'
              : 'No se encontraron citas con esa búsqueda.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      children: [
        if (active != null) ...[
          const Text(
            'Tu turno actual',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCurrentTurnCard(active),
          const SizedBox(height: 24),
        ],
        Text(
          _filter == 'upcoming'
              ? 'Próximas citas'
              : _filter == 'completed'
              ? 'Citas anteriores'
              : 'Citas canceladas',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...remaining.map(
          (appointment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAppointmentListCard(appointment),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTurnCard(Appointment appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NÚMERO DE TURNO',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appointment.queueCode ?? 'Sin asignar',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      appointment.status == 'in_lobby'
                          ? 'EN ESPERA'
                          : 'EN CONSULTA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${appointment.doctorName ?? 'Dentista'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    appointment.serviceName ?? 'Consulta',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentListCard(Appointment appointment) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    final month = months[appointment.dateTime.month - 1];
    final day = DateFormat('dd').format(appointment.dateTime);
    final time = DateFormat('HH:mm').format(appointment.dateTime);
    final doctor = appointment.doctorName ?? 'Doctor';
    final details = '${appointment.serviceName ?? 'Consulta'} • $time';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}

// Vista de Perfil (Cuarta pestaña)
class ClientProfileView extends ConsumerWidget {
  const ClientProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const UserProfileView(roleLabel: 'Paciente');
  }
}

class LegacyClientProfileView extends ConsumerWidget {
  const LegacyClientProfileView({super.key});

  void _showLinkWatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vincular Wear OS'),
          content: const Text(
            'DentalSync buscará relojes Wear OS emparejados con este teléfono y enviará tu sesión de forma automática.',
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.watch_rounded, color: Colors.white),
                  label: const Text('Vincular automáticamente'),
                  onPressed: () async {
                    final authUser = ref
                        .read(authRepositoryProvider)
                        .currentAuthUser;
                    final link = await WearLinkService.instance
                        .linkCurrentSession(role: 'client');

                    if (link.success && authUser != null) {
                      final repo = ref.read(notificationRepositoryProvider);
                      await repo.registerDevice(
                        deviceType: 'wear_os',
                        pushToken: 'wear_os_companion_${authUser.id}',
                      );
                      ref
                          .read(smartwatchLinkedOverrideProvider.notifier)
                          .markLinked();
                      await ref
                          .refresh(linkedDevicesProvider.future)
                          .then((_) {});
                      ref
                          .read(smartwatchLinkedOverrideProvider.notifier)
                          .clear();
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            link.success
                                ? 'Sesión enviada. En el reloj toca Reintentar.'
                                : link.message,
                          ),
                          backgroundColor: link.success
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  label: const Text('Registrar solo notificaciones'),
                  onPressed: () async {
                    final authUser = ref
                        .read(authRepositoryProvider)
                        .currentAuthUser;
                    final repo = ref.read(notificationRepositoryProvider);
                    await repo.registerDevice(
                      deviceType: 'wear_os',
                      pushToken: 'wear_os_notifications_${authUser?.id ?? ""}',
                    );
                    await ref
                        .refresh(linkedDevicesProvider.future)
                        .then((_) {});
                    ref.read(smartwatchLinkedOverrideProvider.notifier).clear();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificaciones Wear OS activadas.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showUnlinkWatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desvincular Smartwatch'),
          content: const Text(
            '¿Estás seguro de que deseas desvincular tus relojes inteligentes de DentalSync? Dejarás de recibir notificaciones de tu turno.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final repo = ref.read(notificationRepositoryProvider);
                ref
                    .read(smartwatchLinkedOverrideProvider.notifier)
                    .markUnlinked();
                final success = await repo.deactivateSmartwatchDevices();
                final unlinkNotice = await WearLinkService.instance
                    .unlinkCurrentSession();
                final stillLinked = await repo.hasActiveSmartwatchDevice();
                await ref.refresh(linkedDevicesProvider.future).then((_) {});
                stillLinked
                    ? ref
                          .read(smartwatchLinkedOverrideProvider.notifier)
                          .clear()
                    : ref
                          .read(smartwatchLinkedOverrideProvider.notifier)
                          .markUnlinked();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? unlinkNotice.success
                                  ? 'Smartwatch desvinculado. Actualiza el reloj.'
                                  : 'Smartwatch desvinculado en la app. Actualiza o reinicia el reloj si sigue conectado.'
                            : 'No se pudo desvincular el smartwatch.',
                      ),
                      backgroundColor: success ? null : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text(
                'Sí, Desvincular',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final devicesAsync = ref.watch(linkedDevicesProvider);

    final user = userAsync.value;
    final userName = user?.name ?? 'Paciente';
    final userEmail = user?.email ?? '';
    final userId = user?.id != null
        ? (user!.id.length > 8 ? user.id.substring(0, 8) : user.id)
        : 'DS-2026-PEND';

    final linkedDevices = devicesAsync.value ?? [];
    final smartwatchOverride = ref.watch(smartwatchLinkedOverrideProvider);
    final watchDevices = linkedDevices.where(
      (d) => d['device_type'] == 'watch_os' || d['device_type'] == 'wear_os',
    );
    final isWatchLinked = smartwatchOverride ?? watchDevices.isNotEmpty;

    // Descripción del smartwatch conectado
    String watchSubtitle = 'Sincronización con dispositivos';
    if (isWatchLinked) {
      final types = watchDevices
          .map((d) {
            final dt = d['device_type'] as String;
            return dt == 'watch_os' ? 'Apple Watch' : 'Wear OS';
          })
          .join(', ');
      watchSubtitle = 'Conectado: $types';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar y datos principales
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.lightBlueAccent,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Identificador del paciente: $userId',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(userEmail, style: const TextStyle(color: AppColors.primaryBlue)),

          const SizedBox(height: 32),

          // Secciones de Configuración
          _buildSectionTitle('PERFIL'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Información personal',
            subtitle: 'Nombre, identificador y contacto',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('NOTIFICACIONES'),
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: 'Recordatorios',
            subtitle: 'Próximas citas y tratamientos',
            trailing: Switch(
              value: true,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (val) {},
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.watch_outlined,
            title: 'Alertas del reloj inteligente',
            subtitle: watchSubtitle,
            trailing: Switch(
              value: isWatchLinked,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (val) {
                if (val) {
                  _showLinkWatchDialog(context, ref);
                } else {
                  _showUnlinkWatchDialog(context, ref);
                }
              },
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('SEGURIDAD'),
          _buildSettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometría',
            subtitle: 'Acceso con Huella o Rostro',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.lock_reset,
            title: 'Cambiar contraseña',
            subtitle: 'Última actualización hace 3 meses',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 32),

          // Botón Cerrar Sesión
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                foregroundColor: AppColors.error,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Versión 2.4.0 (Build 882)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
