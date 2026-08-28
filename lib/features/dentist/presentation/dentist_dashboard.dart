import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/quick_actions_dialogs.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/staff_management_view.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/dentist_calendar_view.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/features/shared/presentation/widgets/patient_check_in_scanner.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';
import 'package:sistema_dental/core/models/appointment.dart';
import 'package:sistema_dental/features/shared/presentation/user_profile_view.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/clinical_history_view.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:sistema_dental/features/shared/presentation/widgets/floating_dock_nav_bar.dart';

class DentistDashboard extends ConsumerStatefulWidget {
  const DentistDashboard({super.key});

  @override
  ConsumerState<DentistDashboard> createState() => _DentistDashboardState();
}

class _DentistDashboardState extends ConsumerState<DentistDashboard> {
  int _selectedIndex = 0;
  String _userName = 'Usuario';
  String _clinicName = 'Clínica';
  String _roleLabel = 'Perfil clínico';

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
          .select('role_in_clinic, clinics(business_name)')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .limit(1)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _userName = profile?['name'] as String? ?? user.email ?? 'Usuario';
        _clinicName =
            membership?['clinics']?['business_name'] as String? ?? 'Clínica';
        final role = membership?['role_in_clinic'] as String?;
        _roleLabel = role == 'owner' ? 'Administrador de clínica' : 'Dentista';
      });
    } catch (e) {
      debugPrint('Error loading sidebar profile: $e');
    }
  }

  Future<String?> _getClinicId() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    final membership = await client
        .from('clinic_memberships')
        .select('clinic_id')
        .eq('user_id', user.id)
        .inFilter('role_in_clinic', ['owner', 'dentist'])
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
                'DentalSync',
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
              // Sidebar solo visible en escritorio
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
                if (index == 3) setState(() => _selectedIndex = 2);
                if (index == 4) setState(() => _selectedIndex = 7);
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
                  icon: Icons.people_alt_rounded,
                  label: 'Pacientes',
                ),
                const DockItemData(
                  icon: Icons.settings_rounded,
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
    if (_selectedIndex == 2) return 3;
    if (_selectedIndex == 7) return 4;
    return -1;
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFFF1F5F9),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(0, Icons.grid_view, 'Dashboard'),
          _buildSidebarItem(1, Icons.access_time, 'Citas Activas'),
          _buildSidebarItem(2, Icons.folder_open, 'Pacientes Clínicos'),
          _buildSidebarItem(3, Icons.people, 'Clientes Asociados'),
          _buildSidebarItem(4, Icons.badge, 'Personal y Consultorios'),
          _buildSidebarItem(5, Icons.qr_code_2, 'Código QR Clínica'),
          _buildSidebarItem(6, Icons.medical_information, 'Historial Clínico'),
          _buildSidebarItem(7, Icons.settings_outlined, 'Configuración'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                setState(() => _selectedIndex = 7);
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _roleLabel,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
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
          Navigator.of(context).pop(); // Cerrar drawer en móvil
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4)]
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

  Future<void> _handleGlobalSearch(String query) async {
    if (query.trim().isEmpty) return;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();
      if (membership == null) return;
      final clinicId = membership['clinic_id'] as String;

      final results = await client
          .from('patients')
          .select('id, first_name, last_name, relationship')
          .eq('clinic_id', clinicId)
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%')
          .limit(5);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text('Resultados para "$query"'),
          content: results.isEmpty
              ? const Text('No se encontraron pacientes con ese nombre.')
              : SizedBox(
                  width: 400,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final p = results[index];
                      final name = '${p['first_name']} ${p['last_name']}';
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.lightBlueAccent,
                          child: Icon(Icons.person, color: AppColors.primaryBlue),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Relación: ${p['relationship'] ?? 'Paciente'}'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogCtx);
                            await showDialog(
                              context: context,
                              builder: (_) => ScheduleAppointmentDialog(
                                clinicId: clinicId,
                                initialPatientId: p['id'] as String,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Agendar'),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error global search: $e');
    }
  }

  Future<void> _handleSync() async {
    ref.invalidate(clinicQueueProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Datos sincronizados en tiempo real con la nube.'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showNotificationsDialog() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();
      if (membership == null) return;
      final clinicId = membership['clinic_id'] as String;

      final countRes = await client
          .from('appointments')
          .select('id')
          .eq('clinic_id', clinicId)
          .inFilter('status', ['upcoming', 'in_lobby']);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text('Centro de Notificaciones'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.event, color: AppColors.primaryBlue),
                title: const Text('Citas activas en la clínica'),
                subtitle: Text('${countRes.length} cita(s) pendiente(s) o en recepción.'),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.check_circle_outline, color: AppColors.success),
                title: Text('Recordatorios automáticos'),
                subtitle: Text('Recordatorios por WhatsApp/Email activos.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
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
              child: TextField(
                onSubmitted: _handleGlobalSearch,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Buscar paciente y presionar Enter...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              'DentalSync Connect • $_clinicName',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Sincronizar datos',
            icon: const Icon(Icons.sync, color: AppColors.primaryBlue),
            onPressed: _handleSync,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Notificaciones',
            icon: const Icon(Icons.notifications_active, color: AppColors.warning),
            onPressed: _showNotificationsDialog,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.textSecondary,
              size: 28,
            ),
            onSelected: (value) async {
              if (value == 'mode') {
                context.go('/mode_selector');
              } else if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
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
        content = DashboardView(
          key: const ValueKey(0),
          onNavigateToQueue: () {
            if (mounted) setState(() => _selectedIndex = 1);
          },
        );
        break;
      case 1:
        content = const QueueView(key: ValueKey(1));
        break;
      case 2:
        content = const DentistCalendarView(key: ValueKey(2));
        break;
      case 3:
        content = const PatientsView(key: ValueKey(3));
        break;
      case 4:
        content = const StaffManagementView(key: ValueKey(4));
        break;
      case 5:
        content = const QRCodeView(key: ValueKey(5));
        break;
      case 6:
        content = const ClinicalHistoryView(key: ValueKey(6));
        break;
      case 7:
        content = const SettingsView(key: ValueKey(7));
        break;
      default:
        content = const SettingsView(key: ValueKey(99));
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

class DashboardView extends StatefulWidget {
  final VoidCallback? onNavigateToQueue;
  const DashboardView({super.key, this.onNavigateToQueue});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _clinicName = 'Cargando...';
  String _doctorName = '';
  int _totalPatientsCount = 0;
  int _activeDoctorsCount = 0;
  int _appointmentsToday = 0;
  int _completedAppointments = 0;
  int _totalAppointmentsAllTime = 0;
  int _pendingAppointmentsToday = 0;
  List<Map<String, dynamic>> _todayAppointmentsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      _doctorName = profile?['name'] ?? 'Doctor';

      final memberships = await client
          .from('clinic_memberships')
          .select('clinic_id, clinics(business_name)')
          .eq('user_id', user.id)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .eq('is_active', true)
          .limit(1);

      if (memberships.isNotEmpty) {
        _clinicName = memberships[0]['clinics'] != null
            ? memberships[0]['clinics']['business_name']
            : 'Clínica Desconocida';
        final clinicId = memberships[0]['clinic_id'] as String;

        // 1. Total real patient records
        final patientsRes = await client
            .from('patients')
            .select('id')
            .eq('clinic_id', clinicId);
        _totalPatientsCount = patientsRes.length;

        // 2. Active doctors count
        final doctorsRes = await client
            .from('clinic_memberships')
            .select('id')
            .eq('clinic_id', clinicId)
            .inFilter('role_in_clinic', ['dentist', 'owner'])
            .eq('is_active', true);
        _activeDoctorsCount = doctorsRes.length;

        // 3. All-time total appointments count
        final allApptsRes = await client
            .from('appointments')
            .select('id')
            .eq('clinic_id', clinicId);
        _totalAppointmentsAllTime = allApptsRes.length;

        // 4. Today's appointments with detailed patient & service info
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

        final todayApptsRes = await client
            .from('appointments')
            .select('''
              id, date_time, status,
              patients(first_name, last_name),
              services(service_name, duration_mins)
            ''')
            .eq('clinic_id', clinicId)
            .gte('date_time', startOfDay)
            .lte('date_time', endOfDay)
            .order('date_time', ascending: true);

        _todayAppointmentsList = List<Map<String, dynamic>>.from(todayApptsRes);
        _appointmentsToday = _todayAppointmentsList.length;
        _completedAppointments = _todayAppointmentsList
            .where((a) => a['status'] == 'completed')
            .length;
        _pendingAppointmentsToday = _todayAppointmentsList
            .where((a) => a['status'] == 'scheduled' || a['status'] == 'confirmed')
            .length;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDesktop = MediaQuery.of(context).size.width > 900;
    final progress = _appointmentsToday > 0
        ? _completedAppointments / _appointmentsToday
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 28 : 20),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withAlpha(35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _clinicName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _fetchDashboardData,
                            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                            tooltip: 'Actualizar datos',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hola, Dr. $_doctorName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Resumen clínico y métricas de atención.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 180,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meta Diaria Citas',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1100
                  ? 6
                  : (constraints.maxWidth > 700 ? 3 : 2);
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Total Citas',
                      '$_totalAppointmentsAllTime',
                      'Histórico clínico',
                      Icons.folder_shared_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Citas Hoy',
                      '$_appointmentsToday',
                      'Programadas hoy',
                      Icons.calendar_today_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Pacientes',
                      '$_totalPatientsCount',
                      'Expedientes reales',
                      Icons.people_alt_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Completadas',
                      '$_completedAppointments',
                      'Atendidas hoy',
                      Icons.check_circle_outline,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'En Espera',
                      '$_pendingAppointmentsToday',
                      'Siguiente turno',
                      Icons.hourglass_top_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Dentistas',
                      '$_activeDoctorsCount',
                      'Equipo activo',
                      Icons.medical_services_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildTodayAppointmentsView(),
        ],
      ),
    );
  }

  Future<String?> _activeDentistClinicId() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .limit(1)
          .maybeSingle();
      if (membership != null) return membership['clinic_id'] as String;
    } catch (error) {
      debugPrint('Error resolving active dentist clinic: $error');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu cuenta no tiene una membresía activa como dentista en una clínica. Reactiva el acceso o vuelve a vincular la cuenta con una invitación.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return null;
  }


  Widget _buildTodayAppointmentsView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Citas del Día (Fila de Atención)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () {
                  widget.onNavigateToQueue?.call(); // Ir a la vista de Cola de Citas
                },
                child: const Text(
                  'Ver Fila de Atención →',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (_todayAppointmentsList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No hay citas programadas para el día de hoy.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayAppointmentsList.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final appt = _todayAppointmentsList[index];
                final patientName = appt['patients'] != null
                    ? '${appt['patients']['first_name']} ${appt['patients']['last_name']}'
                    : 'Paciente General';
                final serviceName = appt['services'] != null
                    ? appt['services']['service_name']
                    : 'Consulta Odontológica';
                final timeStr = DateFormat('hh:mm a').format(DateTime.parse(appt['date_time']).toLocal());
                final status = appt['status'] as String? ?? 'scheduled';

                Color statusColor;
                String statusLabel;
                switch (status) {
                  case 'completed':
                    statusColor = Colors.green;
                    statusLabel = 'Completada';
                    break;
                  case 'in_progress':
                    statusColor = Colors.purple;
                    statusLabel = 'En Consulta';
                    break;
                  case 'confirmed':
                    statusColor = AppColors.primaryBlue;
                    statusLabel = 'Confirmada';
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    statusLabel = 'Cancelada';
                    break;
                  default:
                    statusColor = Colors.amber.shade800;
                    statusLabel = 'Programada';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              serviceName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withAlpha(80)),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }



  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon, {
    bool isUp = true,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.circle,
                size: 12,
                color: isUp ? AppColors.primaryBlue : AppColors.primaryBlue,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QueueView extends ConsumerStatefulWidget {
  const QueueView({super.key});

  @override
  ConsumerState<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends ConsumerState<QueueView> {
  String _statusFilter = 'all';
  final Set<String> _temporarilySkipped = {};
  final Set<String> _updatingAppointments = {};

  Future<void> _changeStatus(
    Appointment appointment,
    String newStatus,
    String successMessage, {
    bool confirm = false,
  }) async {
    if (_updatingAppointments.contains(appointment.id)) return;

    if (confirm) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmar acción'),
          content: Text(
            '¿Deseas continuar con ${appointment.patientName ?? 'este paciente'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }

    setState(() => _updatingAppointments.add(appointment.id));
    final success = await ref
        .read(appointmentRepositoryProvider)
        .updateAppointmentStatus(
          appointment.id,
          newStatus,
          expectedCurrentStatus: appointment.status,
        );

    if (!mounted) return;
    setState(() {
      _updatingAppointments.remove(appointment.id);
      _temporarilySkipped.remove(appointment.id);
    });

    if (success) ref.invalidate(clinicQueueProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : 'No se pudo actualizar la cita. Es posible que su estado haya cambiado.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _sendReminder(Appointment appointment) async {
    setState(() => _updatingAppointments.add(appointment.id));
    try {
      await Supabase.instance.client
          .from('appointments')
          .update({'reminder_sent': true})
          .eq('id', appointment.id);
      
      // Enviar notificación Push al teléfono
      try {
        await Supabase.instance.client.functions.invoke(
          'notify-patient-turn',
          body: {'appointmentId': appointment.id, 'newStatus': 'reminder'},
        );
      } catch (e) {
        debugPrint('Error invocando notify-patient-turn: $e');
      }

      ref.invalidate(clinicQueueProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordatorio enviado exitosamente.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar recordatorio: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingAppointments.remove(appointment.id));
    }
  }

  void _skipTemporarily(Appointment appointment) {
    setState(() => _temporarilySkipped.add(appointment.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Paciente pospuesto en esta vista. El reordenamiento permanente se añadirá con el orden de cola.',
        ),
      ),
    );
  }

  Future<void> _showScheduleDialog() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .limit(1)
          .single();
      if (!mounted) return;

      final saved = await showDialog<bool>(
        context: context,
        builder: (context) => ScheduleAppointmentDialog(
          clinicId: membership['clinic_id'] as String,
        ),
      );
      if (saved == true) ref.invalidate(clinicQueueProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el formulario de cita: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _scanCheckIn(List<Appointment> currentQueue) async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientCheckInScannerPage(),
      ),
    );
    if (scannedCode == null || !mounted) return;

    final code = scannedCode.trim();
    final appointment = currentQueue.where((a) => 
        (a.profileId == code || a.patientId == code) && a.status == 'upcoming').firstOrNull;

    if (appointment != null) {
      _changeStatus(appointment, 'in_lobby', 'Llegada registrada exitosamente.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró una cita pendiente para este paciente hoy.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final queueAsync = ref.watch(clinicQueueProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          children: [
            queueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (queue) {
                final visibleQueue = _statusFilter == 'all'
                    ? queue
                    : queue.where((a) => a.status == _statusFilter).toList();
                final nextAppt = queue
                    .where(
                      (a) =>
                          a.status == 'in_lobby' &&
                          !_temporarilySkipped.contains(a.id),
                    )
                    .firstOrNull;

                return Column(
                  children: [
                    // "Próximo na fila" Card
                    if (nextAppt != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isDesktop ? 24 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Próximo en Fila',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    'Esperando',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              nextAppt.patientName ?? 'Paciente',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ticket #${nextAppt.displayQueueCode} • ${nextAppt.serviceName ?? 'Consulta'}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            isDesktop
                                ? Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _updatingAppointments.contains(
                                                nextAppt.id,
                                              )
                                              ? null
                                              : () => _changeStatus(
                                                  nextAppt,
                                                  'in_treatment',
                                                  'Paciente llamado a consultorio.',
                                                ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.secondaryBlue,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          icon: const Icon(Icons.call_made),
                                          label: const Text(
                                            'Llamar Próximo Paciente',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _skipTemporarily(nextAppt),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                          child: const Text('Saltar'),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed:
                                            _updatingAppointments.contains(
                                              nextAppt.id,
                                            )
                                            ? null
                                            : () => _changeStatus(
                                                nextAppt,
                                                'in_treatment',
                                                'Paciente llamado a consultorio.',
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.secondaryBlue,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                        icon: const Icon(Icons.call_made),
                                        label: const Text(
                                          'Llamar Próximo Paciente',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton(
                                        onPressed: () =>
                                            _skipTemporarily(nextAppt),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                        child: const Text('Saltar'),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    if (nextAppt == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              const Text(
                                'No hay pacientes esperando en sala',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              if (_temporarilySkipped.isNotEmpty)
                                TextButton(
                                  onPressed: () => setState(
                                    () => _temporarilySkipped.clear(),
                                  ),
                                  child: const Text('Restablecer pospuestos'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Tabla con SingleChildScrollView para evitar desbordamiento
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isDesktop ? 24 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Detalles de Cola',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PopupMenuButton<String>(
                                initialValue: _statusFilter,
                                onSelected: (value) =>
                                    setState(() => _statusFilter = value),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'all',
                                    child: Text('Todos'),
                                  ),
                                  PopupMenuItem(
                                    value: 'upcoming',
                                    child: Text('Pendientes'),
                                  ),
                                  PopupMenuItem(
                                    value: 'in_lobby',
                                    child: Text('En sala'),
                                  ),
                                  PopupMenuItem(
                                    value: 'in_treatment',
                                    child: Text('En tratamiento'),
                                  ),
                                ],
                                child: const Chip(
                                  avatar: Icon(Icons.filter_list, size: 16),
                                  label: Text('Filtrar'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isDesktop ? 600 : 700,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: const [
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          'Ticket',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 200,
                                        child: Text(
                                          'Paciente',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          'Servicio',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          'Hora',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          'Estado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 190,
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
                                  const Divider(),
                                  ...visibleQueue.map((appt) {
                                    final statusStr =
                                        appt.status == 'in_treatment'
                                        ? 'En Tratamiento'
                                        : appt.status == 'in_lobby'
                                        ? 'En Sala'
                                        : 'Pendiente';
                                    final color = appt.status == 'in_treatment'
                                        ? AppColors.primaryBlue
                                        : appt.status == 'in_lobby'
                                        ? AppColors.warning
                                        : Colors.grey;
                                    return Column(
                                      children: [
                                        _buildRow(
                                          '#${appt.displayQueueCode}',
                                          appt.patientName ?? 'Paciente',
                                          appt.serviceName ?? 'Consulta',
                                          DateFormat(
                                            'hh:mm a',
                                          ).format(appt.dateTime),
                                          statusStr,
                                          color,
                                          appt,
                                        ),
                                        const Divider(),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scanCheckInBtn',
            onPressed: () {
              queueAsync.whenData((queue) => _scanCheckIn(queue));
            },
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'addApptBtn',
            onPressed: _showScheduleDialog,
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String ticket,
    String name,
    String service,
    String wait,
    String status,
    Color statusColor,
    Appointment appointment,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              ticket,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              service,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 100, child: Text(wait)),
          SizedBox(
            width: 150,
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 190,
            child: _updatingAppointments.contains(appointment.id)
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Wrap(
                    spacing: 4,
                    children: [
                      if (appointment.status == 'upcoming') ...[
                        IconButton(
                          tooltip: 'Enviar recordatorio',
                          onPressed: () => _sendReminder(appointment),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                          ),
                          icon: const Icon(
                            Icons.notifications_active,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Marcar llegada',
                          onPressed: () => _changeStatus(
                            appointment,
                            'in_lobby',
                            'Llegada registrada.',
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                          ),
                          icon: const Icon(
                            Icons.login,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                      if (appointment.status == 'in_lobby')
                        IconButton(
                          tooltip: 'Llamar a consultorio',
                          onPressed: () => _changeStatus(
                            appointment,
                            'in_treatment',
                            'Paciente llamado a consultorio.',
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                          ),
                          icon: const Icon(
                            Icons.campaign,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      if (appointment.status == 'in_treatment')
                        IconButton(
                          tooltip: 'Completar consulta',
                          onPressed: () => _changeStatus(
                            appointment,
                            'completed',
                            'Consulta completada.',
                            confirm: true,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                          ),
                          icon: const Icon(
                            Icons.check_circle,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Cancelar cita',
                        onPressed: () => _changeStatus(
                          appointment,
                          'cancelled',
                          'Cita cancelada.',
                          confirm: true,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        ),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error, // Keeping error color to be semantic, but styled consistently
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

class PatientsView extends StatefulWidget {
  const PatientsView({super.key});

  @override
  State<PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<PatientsView> {
  late Future<List<Map<String, dynamic>>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  void _fetchPatients() {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      _patientsFuture = Future.value([]);
      return;
    }

    _patientsFuture = client
        .from('clinic_memberships')
        .select('clinic_id, role_in_clinic')
        .eq('user_id', user.id)
        .inFilter('role_in_clinic', ['owner', 'dentist'])
        .eq('is_active', true)
        .limit(1)
        .then((memberships) {
          if (memberships.isEmpty) return [];

          final clinicId = memberships[0]['clinic_id'];

          return client
              .from('patients')
              .select('''
                id, first_name, last_name, relationship, date_of_birth, created_at,
                profiles:profiles(name)
              ''')
              .eq('clinic_id', clinicId)
              .order('first_name');
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pacientes de la Clínica',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Consulta los expedientes médicos de los pacientes registrados.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fichas Clínicas de Pacientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _patientsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error al cargar pacientes'),
                        );
                      }
                      final patients = snapshot.data ?? [];
                      if (patients.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No hay pacientes registrados en esta clínica.',
                          ),
                        );
                      }

                      return Column(
                        children: patients.map((patientData) {
                          final patientName = '${patientData['first_name']} ${patientData['last_name']}';
                          final id = (patientData['id'] as String).substring(0, 8);
                          final relStr = patientData['relationship'] == 'self'
                              ? 'Paciente Titular'
                              : (patientData['relationship'] == 'child'
                                  ? 'Hijo(a)'
                                  : (patientData['relationship'] == 'spouse'
                                      ? 'Cónyuge'
                                      : 'Familiar'));
                          final tutorName = patientData['profiles'] != null ? patientData['profiles']['name'] as String? : null;
                          final subtitleStr = '$relStr ${tutorName != null ? '• Tutor: $tutorName' : ''}';
                          
                          final dateStr = patientData['created_at'] != null
                              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(patientData['created_at']))
                              : '';

                          return Column(
                            children: [
                              _buildPatientRow(patientData, patientName, subtitleStr, id, dateStr),
                              const Divider(),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientRow(Map<String, dynamic> patientData, String name, String subtitle, String id, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.lightBlueAccent,
                  child: Icon(Icons.person, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$subtitle • ID: $id',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (date.isNotEmpty)
                Text(
                  'Registrado: $date',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_note, color: AppColors.primaryBlue),
                tooltip: 'Editar Ficha Clínica',
                onPressed: () async {
                  final updated = await showDialog<bool>(
                    context: context,
                    builder: (context) => EditPatientDetailsDialog(patientData: patientData),
                  );
                  if (updated == true) {
                    setState(() {
                      _fetchPatients();
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QRCodeView extends StatefulWidget {
  const QRCodeView({super.key});

  @override
  State<QRCodeView> createState() => _QRCodeViewState();
}

class _QRCodeViewState extends State<QRCodeView> {
  String? _clinicId;
  String? _invitationCode;
  DateTime? _expiresAt;
  String _targetRole = 'client';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinic();
  }

  Future<void> _loadClinic() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _clinicId = membership?['clinic_id'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading invitation clinic: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateInvitation() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    setState(() => _isLoading = true);

    try {
      final result = await Supabase.instance.client.rpc(
        'create_role_invitation',
        params: {'p_clinic_id': clinicId, 'p_target_role': _targetRole},
      );
      final data = Map<String, dynamic>.from(result as Map);
      if (!mounted) return;
      setState(() {
        _invitationCode = data['code'] as String;
        _expiresAt = DateTime.parse(data['expires_at'] as String).toLocal();
        _isLoading = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'PGRST202'
                ? 'Falta instalar la migración de invitaciones QR.'
                : 'No se pudo generar la invitación: ${error.message}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String get _roleLabel => switch (_targetRole) {
    'dentist' => 'Dentista',
    'secretary' => 'Secretaria',
    _ => 'Paciente / cliente',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Código de Invitación de la Clínica',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selecciona el rol antes de generar. El rol queda protegido dentro de la invitación y no puede cambiarse al escanear.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 40),
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_clinicId == null)
                  const Text(
                    'No perteneces a ninguna clínica. Contacta al soporte o crea una nueva.',
                    style: TextStyle(color: Colors.red),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _targetRole,
                    decoration: const InputDecoration(
                      labelText: 'Rol de la invitación',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'client',
                        child: Text('Paciente / cliente'),
                      ),
                      DropdownMenuItem(
                        value: 'dentist',
                        child: Text('Dentista'),
                      ),
                      DropdownMenuItem(
                        value: 'secretary',
                        child: Text('Secretaria'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _targetRole = value;
                        _invitationCode = null;
                        _expiresAt = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _generateInvitation,
                    icon: const Icon(Icons.qr_code_2),
                    label: Text(
                      _invitationCode == null
                          ? 'Generar código QR'
                          : 'Generar otro código QR',
                    ),
                  ),
                  if (_invitationCode != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Invitación para $_roleLabel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: QrImageView(
                        data:
                            'dentalsync://invite?code=${Uri.encodeQueryComponent(_invitationCode!)}',
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primaryBlue,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'O ingresa este código manualmente:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _invitationCode!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    if (_expiresAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Válido hasta ${DateFormat('dd/MM/yyyy HH:mm').format(_expiresAt!)} · Un solo uso',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserProfileView(
      roleLabel: 'Dentista / Administrador',
      avatarIcon: Icons.medical_services_outlined,
    );
  }
}
