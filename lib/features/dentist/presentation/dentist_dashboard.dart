import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/quick_actions_dialogs.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/staff_management_view.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';
import 'package:sistema_dental/features/shared/presentation/user_profile_view.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/clinical_history_view.dart';
import 'package:intl/intl.dart';

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
                if (context.mounted) context.go('/login');
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
        return const CalendarView(); // Pacientes Clínicos
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
        return const Center(child: Text('Vista en desarrollo...'));
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

  Future<void> _showAddPatientDialog() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final membership = await client
        .from('clinic_memberships')
        .select('clinic_id')
        .eq('user_id', user.id)
        .limit(1)
        .single();
    final clinicId = membership['clinic_id'];

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
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final membership = await client
        .from('clinic_memberships')
        .select('clinic_id')
        .eq('user_id', user.id)
        .limit(1)
        .single();
    final clinicId = membership['clinic_id'];

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

  void _generateInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generador de Facturas en desarrollo...')),
    );
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
                  ? 4
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
                  SizedBox(
                    width: width,
                    child: _buildQuickActionLightButton(
                      Icons.receipt_long,
                      'Generar factura',
                      onPressed: _generateInvoice,
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

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                final nextAppt = queue
                    .where(
                      (a) => a.status == 'upcoming' || a.status == 'in_lobby',
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
                                    nextAppt.status == 'in_lobby'
                                        ? 'Esperando'
                                        : 'Próximo',
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
                                          onPressed: () {
                                            ref
                                                .read(
                                                  appointmentRepositoryProvider,
                                                )
                                                .updateAppointmentStatus(
                                                  nextAppt.id,
                                                  'in_treatment',
                                                );
                                          },
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
                                          onPressed: () {},
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
                                        onPressed: () {
                                          ref
                                              .read(
                                                appointmentRepositoryProvider,
                                              )
                                              .updateAppointmentStatus(
                                                nextAppt.id,
                                                'in_treatment',
                                              );
                                        },
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
                                        onPressed: () {},
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
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No hay pacientes en fila',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
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
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.filter_list, size: 16),
                                label: const Text('Filter'),
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
                                        width: 150,
                                        child: Text(
                                          'Estado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  ...queue.map((appt) {
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
        onPressed: () {},
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
            width: 150,
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
        ],
      ),
    );
  }
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

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
              'Calendario e Historial',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Gestión centralizada de citas.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Calendario simulado
            Container(
              height: 500,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Vista de Calendario Semanal (Componente Dinámico)',
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.secondaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
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

class CoworkersView extends StatefulWidget {
  const CoworkersView({super.key});

  @override
  State<CoworkersView> createState() => _CoworkersViewState();
}

class _CoworkersViewState extends State<CoworkersView> {
  late Future<List<Map<String, dynamic>>> _coworkersFuture;

  @override
  void initState() {
    super.initState();
    _fetchCoworkers();
  }

  void _fetchCoworkers() {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      _coworkersFuture = Future.value([]);
      return;
    }

    _coworkersFuture = client
        .from('clinic_memberships')
        .select('clinic_id, role_in_clinic, profiles(name)')
        .eq('user_id', user.id)
        .inFilter('role_in_clinic', ['owner', 'dentist'])
        .eq('is_active', true)
        .limit(1)
        .then((memberships) {
          if (memberships.isEmpty) return [];

          final clinicId = memberships[0]['clinic_id'];

          return client
              .from('clinic_memberships')
              .select('role_in_clinic, profiles(name)')
              .eq('clinic_id', clinicId)
              .inFilter('role_in_clinic', ['owner', 'dentist', 'secretary'])
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
              'Compañeros de Trabajo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const Text(
              'Gestiona al personal administrativo y médico de la clínica.',
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
                    'Personal Activo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _coworkersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error al cargar compañeros'),
                        );
                      }
                      final coworkers = snapshot.data ?? [];
                      if (coworkers.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay compañeros registrados.'),
                        );
                      }

                      return Column(
                        children: coworkers.map((cw) {
                          final role = cw['role_in_clinic'] as String;
                          final name = cw['profiles'] != null
                              ? cw['profiles']['name']
                              : 'Desconocido';
                          String roleDisplay = 'Secretaria';
                          IconData icon = Icons.support_agent;
                          if (role == 'owner') {
                            roleDisplay = 'Dentista Principal (Dueño)';
                            icon = Icons.medical_services;
                          } else if (role == 'dentist') {
                            roleDisplay = 'Dentista Ayudante';
                            icon = Icons.medical_services;
                          }

                          return Column(
                            children: [
                              _buildCoworkerRow(
                                name,
                                roleDisplay,
                                icon,
                                isAssistant:
                                    role == 'dentist' || role == 'secretary',
                              ),
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

  Widget _buildCoworkerRow(
    String name,
    String role,
    IconData icon, {
    bool isAssistant = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.lightBlueAccent,
                child: Icon(icon, color: AppColors.primaryBlue),
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
                    role,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (isAssistant)
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: 16,
              ),
              label: const Text(
                'Remover acceso',
                style: TextStyle(color: AppColors.error),
              ),
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
  String? _invitationCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrGenerateCode();
  }

  Future<void> _fetchOrGenerateCode() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      // Find clinic
      final memberships = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .inFilter('role_in_clinic', ['owner', 'dentist'])
          .eq('is_active', true)
          .limit(1);

      if (memberships.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final clinicId = memberships[0]['clinic_id'];

      // Check for existing valid code
      final existingCodes = await client
          .from('invitation_codes')
          .select('code')
          .eq('clinic_id', clinicId)
          .eq('is_used', false)
          .gte('expires_at', DateTime.now().toUtc().toIso8601String())
          .limit(1);

      if (existingCodes.isNotEmpty) {
        setState(() {
          _invitationCode = existingCodes[0]['code'];
          _isLoading = false;
        });
        return;
      }

      // Generate new code: e.g., DENT-XXXXXX
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      final codeSuffix = String.fromCharCodes(
        Iterable.generate(
          6,
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
        ),
      );
      final newCode = 'DENT-$codeSuffix';

      await client.from('invitation_codes').insert({
        'clinic_id': clinicId,
        'code': newCode,
        'created_by': user.id,
        'is_used': false,
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 1))
            .toIso8601String(),
      });

      setState(() {
        _invitationCode = newCode;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetch/generate code: $e');
      setState(() => _isLoading = false);
    }
  }

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
                  'Muestra este código a pacientes, secretarias o dentistas ayudantes. La aplicación detectará automáticamente su rol.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 40),
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_invitationCode == null)
                  const Text(
                    'No perteneces a ninguna clínica. Contacta al soporte o crea una nueva.',
                    style: TextStyle(color: Colors.red),
                  )
                else ...[
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_2,
                        size: 200,
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
