import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/quick_actions_dialogs.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/staff_management_view.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/dentist_calendar_view.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';
import 'package:sistema_dental/core/models/appointment.dart';
import 'package:sistema_dental/features/shared/presentation/user_profile_view.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/clinical_history_view.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DentistDashboard extends StatefulWidget {
  const DentistDashboard({super.key});

  @override
  State<DentistDashboard> createState() => _DentistDashboardState();
}

class _DentistDashboardState extends State<DentistDashboard> {
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
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showEmergencyDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.priority_high),
              label: const Text(
                'Alerta urgente',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 16),
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

  Future<void> _showEmergencyDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alerta urgente'),
        content: Text(
          '¿Quieres marcar una alerta interna para $_clinicName? Esto puede usarse para avisar a recepción sobre una urgencia en consultorio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            label: const Text(
              'Activar alerta',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerta urgente registrada para recepción.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
                  hintText: 'Search...',
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
    switch (_selectedIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return const QueueView();
      case 2:
        return const DentistCalendarView();
      case 3:
        return const PatientsView(); // Clientes Asociados
      case 4:
        return const StaffManagementView(); // Gestión de Personal y Consultorios
      case 5:
        return const QRCodeView(); // Código QR Único
      case 6:
        return const ClinicalHistoryView(); // Historial Clínico
      case 7:
        return const SettingsView();
      default:
        return const SettingsView();
    }
  }
}

// ----------------------------------------------------
// Vistas Individuales
// ----------------------------------------------------

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _clinicName = 'Cargando...';
  String _doctorName = '';
  int _patientCount = 0;
  int _activeDoctorsCount = 0;
  int _appointmentsToday = 0;
  int _completedAppointments = 0;
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
          .single();
      _doctorName = profile['name'] ?? 'Doctor';

      final memberships = await client
          .from('clinic_memberships')
          .select('clinic_id, clinics(business_name)')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .limit(1);

      if (memberships.isNotEmpty) {
        _clinicName = memberships[0]['clinics'] != null
            ? memberships[0]['clinics']['business_name']
            : 'Clínica Desconocida';
        final clinicId = memberships[0]['clinic_id'];

        final patients = await client
            .from('clinic_memberships')
            .select('id')
            .eq('clinic_id', clinicId)
            .eq('role_in_clinic', 'client')
            .eq('is_active', true);
        _patientCount = patients.length;

        // Fetch active doctors
        final doctors = await client
            .from('clinic_memberships')
            .select('id')
            .eq('clinic_id', clinicId)
            .inFilter('role_in_clinic', ['dentist', 'owner'])
            .eq('is_active', true);
        _activeDoctorsCount = doctors.length;

        // Fetch today's appointments for goal
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
            .select('id, status')
            .eq('clinic_id', clinicId)
            .gte('date_time', startOfDay)
            .lte('date_time', endOfDay);

        _appointmentsToday = appts.length;
        _completedAppointments = appts
            .where((a) => a['status'] == 'completed')
            .length;
      }

      setState(() {
        _isLoading = false;
      });
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
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clinicName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hola, Dr. $_doctorName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Resumen operativo de la clínica para el día de hoy.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
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
                        'Progreso diario',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
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
              final columns = constraints.maxWidth > 1000
                  ? 4
                  : (constraints.maxWidth > 640 ? 2 : 1);
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Clientes',
                      '$_patientCount',
                      'Cuentas vinculadas',
                      Icons.people_alt_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Dentistas',
                      '$_activeDoctorsCount',
                      'Activos en clínica',
                      Icons.medical_services_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Citas hoy',
                      '$_appointmentsToday',
                      'Programadas',
                      Icons.calendar_today_outlined,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildStatCard(
                      'Completadas',
                      '$_completedAppointments',
                      'Finalizadas hoy',
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildStatsAndQueue(isDesktop),
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

  Future<void> _showAddPatientDialog() async {
    final clinicId = await _activeDentistClinicId();
    if (clinicId == null) return;

    if (mounted) {
      final bool? added = await showDialog(
        context: context,
        builder: (context) => AddPatientDialog(clinicId: clinicId),
      );
      if (added == true) {
        _fetchDashboardData();
      }
    }
  }

  Future<void> _showScheduleDialog() async {
    final clinicId = await _activeDentistClinicId();
    if (clinicId == null) return;

    if (mounted) {
      final bool? scheduled = await showDialog(
        context: context,
        builder: (context) => ScheduleAppointmentDialog(clinicId: clinicId),
      );
      if (scheduled == true) {
        _fetchDashboardData();
      }
    }
  }

  Future<void> _uploadXRay() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.image,
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result != null) {
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Radiografía seleccionada: $fileName. Subiendo a la nube...',
            ),
          ),
        );

        if (fileBytes != null) {
          // Attempt upload
          final supabase = Supabase.instance.client;
          final path =
              'xrays/${DateTime.now().millisecondsSinceEpoch}_$fileName';
          await supabase.storage.from('xrays').uploadBinary(path, fileBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Radiografía subida exitosamente.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error uploading xray: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al subir: $e (Asegúrate de que el bucket "xrays" exista en Supabase)',
            ),
          ),
        );
      }
    }
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Atajos principales para la operación diaria.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 3
                  : (constraints.maxWidth > 560 ? 2 : 1);
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildQuickActionButton(
                      Icons.person_add_alt_1,
                      'Registrar paciente',
                      isPrimary: true,
                      onPressed: _showAddPatientDialog,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildQuickActionButton(
                      Icons.event_available,
                      'Agendar cita',
                      onPressed: _showScheduleDialog,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildQuickActionLightButton(
                      Icons.upload_file,
                      'Subir radiografía',
                      onPressed: _uploadXRay,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndQueue(bool isDesktop) {
    return Column(
      children: [
        isDesktop
            ? Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Clientes Totales',
                      '$_patientCount',
                      'Registrados en la clínica',
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildStatCard(
                      'Próximas Citas',
                      '0',
                      'Sin citas programadas',
                      Icons.calendar_today,
                      isUp: false,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildStatCard(
                    'Clientes Totales',
                    '$_patientCount',
                    'Registrados en la clínica',
                    Icons.people,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    'Próximas Citas',
                    '0',
                    'Sin citas programadas',
                    Icons.calendar_today,
                    isUp: false,
                  ),
                ],
              ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Citas del Día',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Ver Todo',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No hay citas para mostrar hoy.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label, {
    bool isPrimary = false,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryBlue : AppColors.lightBlueAccent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? AppColors.primaryBlue
                : AppColors.primaryBlue.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.primaryBlue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionLightButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
                              'Ticket #${nextAppt.queueCode ?? 'N/A'} • ${nextAppt.serviceName ?? 'Consulta'}',
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
                                          '#${appt.queueCode ?? 'N/A'}',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showScheduleDialog,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
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
                      if (appointment.status == 'upcoming')
                        IconButton(
                          tooltip: 'Marcar llegada',
                          onPressed: () => _changeStatus(
                            appointment,
                            'in_lobby',
                            'Llegada registrada.',
                          ),
                          icon: const Icon(
                            Icons.login,
                            color: AppColors.warning,
                          ),
                        ),
                      if (appointment.status == 'in_lobby')
                        IconButton(
                          tooltip: 'Llamar a consultorio',
                          onPressed: () => _changeStatus(
                            appointment,
                            'in_treatment',
                            'Paciente llamado a consultorio.',
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
                          icon: const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
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
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
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
              .from('clinic_memberships')
              .select('user_id, created_at, profiles(name)')
              .eq('clinic_id', clinicId)
              .eq('role_in_clinic', 'client')
              .eq('is_active', true);
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
              'Clientes Asociados',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Gestiona las cuentas de los clientes vinculados a la clínica.',
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
                    'Clientes Registrados',
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
                          child: Text('Error al cargar clientes'),
                        );
                      }
                      final clients = snapshot.data ?? [];
                      if (clients.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No hay clientes vinculados a esta clínica.',
                          ),
                        );
                      }

                      return Column(
                        children: clients.map((clientData) {
                          final name = clientData['profiles'] != null
                              ? clientData['profiles']['name']
                              : 'Desconocido';
                          final id = (clientData['user_id'] as String)
                              .substring(0, 8); // Short ID for display
                          final dateStr = clientData['created_at'] as String;
                          final date = DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.parse(dateStr));

                          return Column(
                            children: [
                              _buildPatientRow(name, id, date),
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

  Widget _buildPatientRow(String name, String id, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.lightBlueAccent,
                child: Icon(Icons.person, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ID: $id',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Text(
            'Se unió: $date',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
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
