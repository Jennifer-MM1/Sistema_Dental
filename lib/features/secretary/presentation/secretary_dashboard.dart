import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:sistema_dental/features/shared/presentation/widgets/patient_check_in_scanner.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/quick_actions_dialogs.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/staff_management_view.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';
import 'package:sistema_dental/features/shared/presentation/user_profile_view.dart';
import 'package:sistema_dental/features/shared/presentation/widgets/floating_dock_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int _selectedIndex = 0;

  Future<String?> _getClinicId() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    final membership = await client
        .from('clinic_memberships')
        .select('clinic_id')
        .eq('user_id', user.id)
        .inFilter('role_in_clinic', ['owner', 'secretary', 'dentist'])
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    return membership?['clinic_id'] as String?;
  }

  Future<void> _quickRegisterPatient() async {
    final clinicId = await _getClinicId();
    if (clinicId == null || !mounted) return;
    showDialog(
      context: context,
      builder: (_) => AddPatientDialog(clinicId: clinicId),
    );
  }

  Future<void> _quickScheduleAppointment() async {
    final clinicId = await _getClinicId();
    if (clinicId == null || !mounted) return;
    showDialog(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(clinicId: clinicId),
    );
  }

  void _handleSync() {
    setState(() {}); // Simple rebuild to trigger FutureBuilders
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Datos sincronizados.'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobileOrTablet = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width <= 1300;
    final isDesktop = !isMobileOrTablet;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: AppColors.primaryBlue),
              title: const Text(
                'DentalSync Admin',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Sincronizar datos',
                  icon: const Icon(Icons.sync, color: AppColors.primaryBlue),
                  onPressed: _handleSync,
                ),
              ],
            ),
      drawer: Drawer(child: _buildSidebar()),
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              if (isDesktop) _buildSidebar(),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop) _buildTopBar(),
                    Expanded(child: _buildMainContent()),
                  ],
                ),
              ),
            ],
          ),
          if (!isDesktop)
            FloatingDockNavBar(
              selectedIndex: _currentDockIndex,
              onItemSelected: (index) {
                if (index == 0) setState(() => _selectedIndex = 0);
                if (index == 3) setState(() => _selectedIndex = 1);
                if (index == 4) setState(() => _selectedIndex = 4);
              },
              items: [
                const DockItemData(
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                DockItemData(
                  icon: Icons.person_add_rounded,
                  label: 'Reg. Paciente',
                  onTapOverride: _quickRegisterPatient,
                ),
                DockItemData(
                  icon: Icons.edit_calendar_rounded,
                  label: 'Reg. Cita',
                  onTapOverride: _quickScheduleAppointment,
                ),
                const DockItemData(
                  icon: Icons.people_rounded,
                  label: 'Pacientes',
                ),
                const DockItemData(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                ),
              ],
            ),
        ],
      ),
    );
  }

  int get _currentDockIndex {
    if (_selectedIndex == 0) return 0;
    if (_selectedIndex == 1) return 3;
    if (_selectedIndex == 4) return 4;
    return -1;
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFFF1F5F9), // Color grisáceo claro
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'DentalSync',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Administración Central',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(0, Icons.dashboard_outlined, 'Panel General'),
          _buildSidebarItem(1, Icons.people_outline, 'Gestión Pacientes'),
          _buildSidebarItem(
            2,
            Icons.medical_services_outlined,
            'Gestión Dentistas',
          ),
          _buildSidebarItem(3, Icons.calendar_month_outlined, 'Agenda Global'),
          _buildSidebarItem(4, Icons.person_outline, 'Perfil'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                setState(() => _selectedIndex = 4);
                if (MediaQuery.of(context).size.width <= 900) {
                  Navigator.of(context).pop();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.lightBlueAccent,
                      child: Icon(
                        Icons.support_agent,
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Recepción',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Secretaría',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
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
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (MediaQuery.of(context).size.width <= 900) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Buscar...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Flexible(
            child: Text(
              'DentalSync Connect',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.sync, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none, color: AppColors.error),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.textSecondary,
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                setState(() => _selectedIndex = 4);
              } else if (value == 'mode') {
                context.go('/mode_selector');
              } else if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mode',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Cambiar Modo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar Sesión',
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

  Widget _buildMainContent() {
    final isDesktop = MediaQuery.of(context).size.width > 1300;
    final bottomPad = isDesktop ? 0.0 : 90.0;

    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = const SecretaryDashboardView(key: ValueKey(0));
        break;
      case 1:
        content = const PatientsManagementView(key: ValueKey(1));
        break;
      case 2:
        content = const StaffManagementView(
          key: ValueKey(2),
          dentistsOnly: true,
          showInviteAction: true,
          includeInactiveMembers: true,
        );
        break;
      case 3:
        content = const GlobalAgendaView(key: ValueKey(3));
        break;
      case 4:
        content = const UserProfileView(
          key: ValueKey(4),
          roleLabel: 'Secretaria / Recepción',
          avatarIcon: Icons.support_agent,
        );
        break;
      default:
        content = const UserProfileView(
          key: ValueKey(99),
          roleLabel: 'Secretaria / Recepción',
          avatarIcon: Icons.support_agent,
        );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: content,
      ),
    );
  }
}

// ----------------------------------------------------
// Vistas Individuales
// ----------------------------------------------------

class SecretaryDashboardView extends StatefulWidget {
  const SecretaryDashboardView({super.key});

  @override
  State<SecretaryDashboardView> createState() => _SecretaryDashboardViewState();
}

class _SecretaryDashboardViewState extends State<SecretaryDashboardView> {
  bool _isLoading = true;
  int _appointmentsToday = 0;
  int _newPatients = 0;
  int _activeDentists = 0;
  List<dynamic> _upcomingAppts = [];
  String? _clinicId;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .limit(1)
          .single();

      final clinicId = membership['clinic_id'] as String;
      _clinicId = clinicId;

      // Dentists
      final dentists = await client
          .from('clinic_memberships')
          .select('id')
          .eq('clinic_id', clinicId)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .eq('is_active', true);
      _activeDentists = dentists.length;

      // Patients
      final patients = await client
          .from('clinic_memberships')
          .select('id')
          .eq('clinic_id', clinicId)
          .eq('role_in_clinic', 'client')
          .eq('is_active', true);
      _newPatients = patients.length;

      // Appointments Today
      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toUtc().toIso8601String();
      final endOfDay = DateTime(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      ).toUtc().toIso8601String();

      final appts = await client
          .from('appointments')
          .select(
            '*, patients(first_name, last_name), doctors(profiles(name)), services(service_name, price)',
          )
          .eq('clinic_id', clinicId)
          .gte('date_time', startOfDay)
          .lte('date_time', endOfDay)
          .order('date_time', ascending: true);

      _appointmentsToday = appts.length;

      _upcomingAppts = appts
          .where(
            (a) => a['status'] != 'completed' && a['status'] != 'cancelled',
          )
          .take(3)
          .toList();
    } catch (e) {
      debugPrint('Error fetch stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de Administración',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Resumen general de la clínica para el día de hoy.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 900
                  ? 3
                  : (constraints.maxWidth > 600 ? 2 : 1);
              double width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Citas Hoy',
                      '$_appointmentsToday',
                      'Citas programadas',
                      Icons.calendar_today,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Clientes',
                      '$_newPatients',
                      'En la clínica',
                      Icons.person_add_alt_1,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Dentistas',
                      '$_activeDentists',
                      'Activos',
                      Icons.medical_services,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildQuickActions()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildUpcomingAppointments()),
                  ],
                )
              : Column(
                  children: [
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildUpcomingAppointments(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Frecuentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _clinicId == null ? null : _openAddPatient,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Registrar Paciente',
              style: TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _clinicId == null ? null : _openScheduleAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryBlue,
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            label: const Text(
              'Agendar Cita Manual',
              style: TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddPatient() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AddPatientDialog(clinicId: clinicId),
    );
    if (created == true) await _refreshStats();
  }

  Future<void> _openScheduleAppointment() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(clinicId: clinicId),
    );
    if (created == true) await _refreshStats();
  }

  Future<void> _refreshStats() async {
    if (mounted) setState(() => _isLoading = true);
    await _fetchStats();
  }

  Widget _buildUpcomingAppointments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Citas Inminentes (Global)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (_upcomingAppts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No hay citas pendientes para hoy.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._upcomingAppts.map((appt) {
              final date = DateTime.parse(appt['date_time']).toLocal();
              final time =
                  '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              final patientName =
                  '${appt['patients']?['first_name'] ?? 'Paciente'} ${appt['patients']?['last_name'] ?? ''}';
              final doctorName =
                  appt['doctors']?['profiles']?['name'] ?? 'Doctor';
              final reason = appt['services']?['service_name'] ?? 'Consulta';
              return Column(
                children: [
                  _buildAppointmentRow(
                    time,
                    patientName,
                    'Dr. $doctorName',
                    reason,
                  ),
                  const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
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
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentRow(
    String time,
    String patient,
    String doctor,
    String reason,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              patient,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              doctor,
              style: const TextStyle(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reason,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalAgendaView extends StatefulWidget {
  const GlobalAgendaView({super.key});

  @override
  State<GlobalAgendaView> createState() => _GlobalAgendaViewState();
}

class _GlobalAgendaViewState extends State<GlobalAgendaView> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _appointments = [];
  String? _clinicId;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw StateError('No hay una sesiÃ³n activa.');

      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .limit(1)
          .single();
      final clinicId = membership['clinic_id'] as String;
      final range = appointmentLocalDayUtcRange(_selectedDate);
      final appointments = await client
          .from('appointments')
          .select(
            '*, patients(first_name, last_name, profile_id), doctors(profiles(name)), services(service_name, duration_mins)',
          )
          .eq('clinic_id', clinicId)
          .gte('date_time', range.startUtc.toIso8601String())
          .lt('date_time', range.endUtc.toIso8601String())
          .order('date_time');

      if (!mounted) return;
      setState(() {
        _clinicId = clinicId;
        _appointments = appointments;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'No se pudo cargar la agenda: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeDay(int days) async {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    await _loadAgenda();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null) return;
    setState(() => _selectedDate = selected);
    await _loadAgenda();
  }

  Future<void> _scheduleAppointment() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(clinicId: clinicId),
    );
    if (created == true) await _loadAgenda();
  }

  Future<void> _rescheduleAppointment(Map<String, dynamic> appointment) async {
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

  String _formatSelectedDate() {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${_selectedDate.day} de ${months[_selectedDate.month - 1]} de ${_selectedDate.year}';
  }

  Future<void> _changeStatus(String appointmentId, String newStatus, String successMessage) async {
    try {
      await Supabase.instance.client
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: AppColors.success),
        );
        await _loadAgenda();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar el estado: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _scanCheckIn() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientCheckInScannerPage(),
      ),
    );
    if (scannedCode == null || !mounted) return;

    final code = scannedCode.trim();
    final appointment = _appointments.where((a) => 
        (a['patients']?['profile_id'] == code || a['patient_id'] == code) && 
        a['status'] == 'upcoming').firstOrNull;

    if (appointment != null) {
      await _changeStatus(appointment['id'], 'in_lobby', 'Llegada registrada exitosamente.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró una cita pendiente para este paciente en el día seleccionado.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _statusLabel(String status) => switch (status) {
    'upcoming' => 'Programada',
    'in_lobby' => 'En espera',
    'in_treatment' => 'En consulta',
    'completed' => 'Completada',
    'cancelled' => 'Cancelada',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'completed' => Colors.green,
    'cancelled' => Colors.red,
    'in_treatment' => Colors.orange,
    'in_lobby' => Colors.purple,
    _ => AppColors.primaryBlue,
  };

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'secScanCheckInBtn',
            onPressed: _clinicId == null ? null : _scanCheckIn,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryBlue,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear Llegada'),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'secAddApptBtn',
            onPressed: _clinicId == null ? null : _scheduleAppointment,
            backgroundColor: AppColors.primaryBlue,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Nueva cita', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agenda Global',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Citas de todos los dentistas de la clÃ­nica.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'DÃ­a anterior',
                      onPressed: () => _changeDay(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            _formatSelectedDate(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'DÃ­a siguiente',
                      onPressed: () => _changeDay(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    IconButton(
                      tooltip: 'Actualizar agenda',
                      onPressed: _loadAgenda,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildAgendaContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.red),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadAgenda,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_appointments.isEmpty) {
      return const Center(child: Text('No hay citas programadas este dÃ­a.'));
    }

    return ListView.separated(
      itemCount: _appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        final date = DateTime.parse(appointment['date_time']).toLocal();
        final patient = appointment['patients'];
        final doctor = appointment['doctors'];
        final service = appointment['services'];
        final status = appointment['status']?.toString() ?? 'upcoming';
        final patientName =
            '${patient?['first_name'] ?? 'Paciente'} ${patient?['last_name'] ?? ''}'
                .trim();
        final doctorName = doctor?['profiles']?['name'] ?? 'Sin asignar';
        final serviceName = service?['service_name'] ?? 'Consulta';
        final time =
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: status == 'upcoming'
                ? () => _rescheduleAppointment(appointment)
                : null,
            leading: SizedBox(
              width: 58,
              child: Text(
                time,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              patientName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Dr. $doctorName  â€¢  $serviceName'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(_statusLabel(status)),
                  side: BorderSide(color: _statusColor(status)),
                  labelStyle: TextStyle(color: _statusColor(status)),
                  backgroundColor: _statusColor(status).withValues(alpha: 0.08),
                ),
                if (status == 'upcoming') ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.edit_calendar_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Marcar llegada',
                    icon: const Icon(Icons.login, color: AppColors.primaryBlue),
                    onPressed: () => _changeStatus(appointment['id'], 'in_lobby', 'Llegada registrada.'),
                  ),
                ],
                if (status == 'in_lobby')
                  IconButton(
                    tooltip: 'Llamar a consultorio',
                    icon: const Icon(Icons.campaign, color: AppColors.primaryBlue),
                    onPressed: () => _changeStatus(appointment['id'], 'in_treatment', 'Paciente llamado a consultorio.'),
                  ),
                if (status == 'in_treatment')
                  IconButton(
                    tooltip: 'Completar consulta',
                    icon: const Icon(Icons.check_circle, color: AppColors.primaryBlue),
                    onPressed: () => _changeStatus(appointment['id'], 'completed', 'Consulta completada.'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PatientsManagementView extends StatefulWidget {
  const PatientsManagementView({super.key});

  @override
  State<PatientsManagementView> createState() => _PatientsManagementViewState();
}

class _PatientsManagementViewState extends State<PatientsManagementView> {
  bool _isLoading = true;
  List<dynamic> _patients = [];
  String? _clinicId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients({bool showLoader = false}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (showLoader && mounted) setState(() => _isLoading = true);

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .limit(1)
          .single();

      final clinicId = membership['clinic_id'] as String;

      final patientsRes = await client
          .from('patients')
          .select('*, profiles(phone)')
          .eq('clinic_id', clinicId)
          .order('last_name');

      if (!mounted) return;
      setState(() {
        _clinicId = clinicId;
        _patients = patientsRes;
      });
    } catch (e) {
      debugPrint('Error fetch patients: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDesktop = MediaQuery.of(context).size.width > 900;
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visiblePatients = _patients.where((patient) {
      if (normalizedQuery.isEmpty) return true;
      final profile = patient['profiles'];
      final searchable = [
        patient['first_name'],
        patient['last_name'],
        patient['relationship'],
        profile is Map ? profile['phone'] : null,
      ].whereType<Object>().join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Gestión de Pacientes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Directorio completo de pacientes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _clinicId == null ? null : _addPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text(
                    'Añadir',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar paciente',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Actualizar pacientes',
                  onPressed: () => _fetchPatients(showLoader: true),
                  icon: const Icon(Icons.refresh),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'ID',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 250,
                            child: Text(
                              'Nombre del Paciente',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text(
                              'Teléfono',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Text(
                              'Relación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Acciones',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      if (visiblePatients.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No hay pacientes registrados en esta clínica.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...visiblePatients.map((p) {
                          return Column(
                            children: [_buildPatientRow(p), const Divider()],
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPatient() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AddPatientDialog(clinicId: clinicId),
    );
    if (created == true) await _fetchPatients(showLoader: true);
  }

  Future<void> _editPatient(Map<String, dynamic> patient) async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditPatientDialog(clinicId: clinicId, patient: patient),
    );
    if (updated == true) await _fetchPatients(showLoader: true);
  }

  Future<void> _schedulePatient(Map<String, dynamic> patient) async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    await showDialog<bool>(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(
        clinicId: clinicId,
        initialPatientId: patient['id'] as String,
      ),
    );
  }

  Widget _buildPatientRow(Map<String, dynamic> patient) {
    final rawId = patient['id'].toString();
    final id = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    final name = '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'
        .trim();
    final profile = patient['profiles'];
    final phone = profile is Map
        ? (profile['phone']?.toString() ?? 'No registrado')
        : 'No registrado';
    final relationship = patient['relationship']?.toString() ?? 'self';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              id,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 250,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.lightBlueAccent,
                  child: Icon(
                    Icons.person,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(phone, style: const TextStyle(color: Colors.grey)),
          ),
          SizedBox(
            width: 150,
            child: Text(
              relationship,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Editar paciente',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editPatient(patient),
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                ),
                IconButton(
                  tooltip: 'Agendar cita',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _schedulePatient(patient),
                  icon: const Icon(
                    Icons.calendar_month,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditPatientDialog extends StatefulWidget {
  const EditPatientDialog({
    super.key,
    required this.clinicId,
    required this.patient,
  });

  final String clinicId;
  final Map<String, dynamic> patient;

  @override
  State<EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends State<EditPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late String _relationship;
  DateTime? _dateOfBirth;
  bool _isSaving = false;
  late bool _isSelf;

  @override
  void initState() {
    super.initState();
    _isSelf = (widget.patient['relationship']?.toString() == 'self');
    _firstNameController = TextEditingController(
      text: widget.patient['first_name']?.toString() ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.patient['last_name']?.toString() ?? '',
    );
    _relationship = widget.patient['relationship']?.toString() ?? 'self';
    _dateOfBirth = DateTime.tryParse(
      widget.patient['date_of_birth']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updateData = <String, dynamic>{
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T').first,
      };

      if (!_isSelf) {
        updateData['first_name'] = _firstNameController.text.trim();
        updateData['last_name'] = _lastNameController.text.trim();
        updateData['relationship'] = _relationship;
      }

      await Supabase.instance.client
          .from('patients')
          .update(updateData)
          .eq('id', widget.patient['id'])
          .eq('clinic_id', widget.clinicId);

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSelf ? 'Ficha del Cliente Titular' : 'Editar Paciente'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSelf)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'El nombre del cliente titular lo administra él mismo. Solo se puede especificar su fecha de nacimiento.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                TextFormField(
                  controller: _firstNameController,
                  enabled: !_isSelf,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    helperText: _isSelf ? '🔒 Cuenta del cliente' : null,
                  ),
                  validator: (value) =>
                      !_isSelf && (value == null || value.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  enabled: !_isSelf,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (value) =>
                      !_isSelf && (value == null || value.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                ),
                const SizedBox(height: 12),
                if (_isSelf)
                  TextFormField(
                    initialValue: 'Paciente Titular (Self)',
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Relación'),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: ['child', 'spouse', 'parent', 'other'].contains(_relationship)
                        ? _relationship
                        : 'other',
                    decoration: const InputDecoration(labelText: 'Relación'),
                    items: const [
                      DropdownMenuItem(value: 'child', child: Text('Hijo/a')),
                      DropdownMenuItem(value: 'spouse', child: Text('Cónyuge')),
                      DropdownMenuItem(
                        value: 'parent',
                        child: Text('Padre/Madre'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _relationship = value);
                    },
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _dateOfBirth == null
                        ? 'Fecha de nacimiento (Sin registrar)'
                        : 'Fecha de nac.: ${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
                              '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
                              '${_dateOfBirth!.year}',
                  ),
                  subtitle: _isSelf
                      ? const Text('✏️ Haz clic para agregar/editar fecha', style: TextStyle(fontSize: 11, color: AppColors.primaryBlue))
                      : null,
                  trailing: const Icon(Icons.cake_outlined, color: AppColors.primaryBlue),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) {
                      setState(() => _dateOfBirth = selected);
                    }
                  },
                ),
              ],
            ),
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
