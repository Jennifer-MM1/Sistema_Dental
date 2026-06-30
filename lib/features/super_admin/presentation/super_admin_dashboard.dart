import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/dentist/presentation/dentist_dashboard.dart';
import 'package:sistema_dental/features/super_admin/presentation/widgets/qr_invitation_view.dart';

/// Dashboard del Super Administrador (Dentista Principal).
/// Permite navegar entre el panel clínico y las herramientas de gestión.
class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  int _selectedIndex = 0;

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
                'DentalSync Super Admin',
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
      width: 260,
      color: const Color(0xFF0A1628),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medical_services, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DentalSync',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Super Administrador',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sección Clínica
          _buildSectionLabel('CLÍNICA'),
          _buildSidebarItem(0, Icons.dashboard_outlined, 'Dashboard Principal'),
          _buildSidebarItem(1, Icons.people_outline, 'Fila de Espera'),
          _buildSidebarItem(2, Icons.folder_open, 'Historial Clínico'),

          const SizedBox(height: 16),

          // Directorio
          _buildSectionLabel('DIRECTORIO'),
          _buildSidebarItem(3, Icons.person, 'Clientes'),
          _buildSidebarItem(4, Icons.family_restroom, 'Pacientes'),
          _buildSidebarItem(5, Icons.badge_outlined, 'Compañeros de Trabajo'),

          const SizedBox(height: 16),

          // Vinculación
          _buildSectionLabel('VINCULACIÓN'),
          _buildSidebarItem(6, Icons.qr_code_scanner, 'QR de Invitación'),

          const SizedBox(height: 16),

          // Sección Sistema
          _buildSectionLabel('SISTEMA'),
          _buildSidebarItem(7, Icons.settings_outlined, 'Configuración'),

          const Spacer(),

          // Botón Cerrar Sesión
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) context.go('/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Cerrar Sesión'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primaryBlue : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getTitle(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return 'Dashboard Principal';
      case 1: return 'Fila de Espera';
      case 2: return 'Historial Clínico';
      case 3: return 'Directorio: Clientes';
      case 4: return 'Directorio: Pacientes';
      case 5: return 'Compañeros de Trabajo';
      case 6: return 'Generar QR Universal';
      case 7: return 'Configuración';
      default: return 'DentalSync';
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardView();
      case 1:
        return const QueueView();
      case 2:
        return const CalendarView();
      case 3:
        return _buildClientsPanel();
      case 4:
        return _buildPatientsPanel();
      case 5:
        return _buildCoworkersPanel();
      case 6:
        return const QRInvitationView();
      case 7:
        return _buildSettingsPanel();
      default:
        return const DashboardView();
    }
  }

  // ──────── Auxiliares de Supabase ────────
  Future<Map<String, int>> _fetchStats() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final profiles = await client.from('profiles').select('id, role');
      final totalUsers = profiles.length;
      final dentists = profiles.where((p) => p['role'] == 'admin_dentist').length;
      final patients = profiles.where((p) => p['role'] == 'patient').length;
      
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final appointments = await client
          .from('appointments')
          .select('id')
          .gte('date_time', '${todayStr}T00:00:00Z')
          .lte('date_time', '${todayStr}T23:59:59Z');
      final todayAppointments = appointments.length;

      return {
        'totalUsers': totalUsers,
        'dentists': dentists,
        'patients': patients,
        'todayAppointments': todayAppointments,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'dentists': 0,
        'patients': 0,
        'todayAppointments': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProfiles() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final response = await client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }







  Future<void> _toggleUserActive(String userId, bool currentStatus) async {
    final client = ref.read(supabaseClientProvider);
    try {
      await client.from('profiles').update({'is_active': !currentStatus}).eq('id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? 'Usuario desactivado' : 'Usuario activado'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar el estado del usuario'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }



  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String actor, String message, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

    // ──────── Gestión de Usuarios ────────
  Widget _buildClientsPanel() {
    return _buildFilteredProfilesPanel('Directorio de Clientes', 'Usuarios dueños de cuenta que han instalado la app', ['patient']);
  }

  Widget _buildCoworkersPanel() {
    return _buildFilteredProfilesPanel('Compañeros de Trabajo', 'Secretarias y dentistas asociados a la clínica', ['admin_dentist', 'admin_secretary', 'super_admin']);
  }

  Widget _buildFilteredProfilesPanel(String title, String subtitle, List<String> validRoles) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchProfiles(),
      builder: (context, snapshot) {
        var profiles = snapshot.data ?? [];
        profiles = profiles.where((p) => validRoles.contains(p['role'] as String? ?? '')).toList();
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (profiles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text('No hay usuarios en esta categoría', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Rol')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Desactivar')),
                      ],
                      rows: profiles.map((p) {
                        final userId = p['id'] as String;
                        final name = p['name'] as String? ?? 'Sin nombre';
                        final email = p['email'] as String? ?? '';
                        final role = p['role'] as String? ?? 'patient';
                        final isActive = p['is_active'] as bool? ?? true;

                        return DataRow(cells: [
                          DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(email)),
                          DataCell(Text(role.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue))),
                          DataCell(
                            Switch(
                              value: isActive,
                              activeColor: AppColors.success,
                              onChanged: (val) {
                                _toggleUserActive(userId, isActive);
                              },
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Por seguridad, la eliminación completa de usuarios se realiza desde Supabase Auth.')),
                                );
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ──────── Pacientes (Familiares) ────────
  Widget _buildPatientsPanel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPatients(),
      builder: (context, snapshot) {
        final patients = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Directorio de Pacientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Familiares y dependientes registrados por los clientes', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (patients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.family_restroom, size: 64, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text('No hay pacientes registrados', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Fecha Nac.')),
                        DataColumn(label: Text('Relación')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: patients.map((p) {
                        final name = "${p['first_name']} ${p['last_name']}";
                        final dob = p['date_of_birth'] as String? ?? 'Desconocida';
                        final relationship = p['relationship'] as String? ?? 'self';

                        return DataRow(cells: [
                          DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(dob)),
                          DataCell(Text(relationship.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.folder_open, color: AppColors.primaryBlue),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Abrir expediente (Próximamente)')),
                                );
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPatients() async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final membership = await client
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .single();
          
      final clinicId = membership['clinic_id'];
      
      // We fetch all profiles linked to this clinic
      final clinicMembers = await client
          .from('clinic_memberships')
          .select('user_id')
          .eq('clinic_id', clinicId);
          
      final userIds = clinicMembers.map((m) => m['user_id']).toList();
      
      if (userIds.isEmpty) return [];

      final patients = await client
          .from('patients')
          .select()
          .inFilter('profile_id', userIds);
          
      return List<Map<String, dynamic>>.from(patients);
    } catch (e) {
      return [];
    }
  }


  // ──────── Configuración ────────
  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuración', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Información de la Clínica', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSettingRow('Nombre', 'DentalSync Connect'),
                _buildSettingRow('Base de Datos', 'Supabase (PostgreSQL)'),
                _buildSettingRow('Autenticación', 'Supabase Auth'),
                _buildSettingRow('Tiempo Real', 'Supabase Realtime (WebSockets)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
