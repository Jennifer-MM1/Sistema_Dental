import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/dentist/presentation/dentist_dashboard.dart';

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
          _buildSidebarItem(3, Icons.qr_code_scanner, 'Pacientes y QR'),

          const SizedBox(height: 16),

          // Sección Sistema
          _buildSectionLabel('SISTEMA'),
          _buildSidebarItem(4, Icons.manage_accounts, 'Gestión de Usuarios'),
          _buildSidebarItem(5, Icons.qr_code, 'Códigos de Invitación'),
          _buildSidebarItem(6, Icons.settings_outlined, 'Configuración'),

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
      case 3: return 'Pacientes y QR';
      case 4: return 'Gestión de Usuarios';
      case 5: return 'Códigos de Invitación';
      case 6: return 'Configuración';
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
        return const PatientsView();
      case 4:
        return _buildUsersManagementPanel();
      case 5:
        return _buildInvitationCodesPanel();
      case 6:
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

  Future<List<Map<String, dynamic>>> _fetchInvitationCodes() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final response = await client
          .from('invitation_codes')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> _generateCode() async {
    final client = ref.read(supabaseClientProvider);
    final authRepo = ref.read(authRepositoryProvider);
    try {
      final clinicRes = await client.from('clinics').select('id').limit(1).maybeSingle();
      final clinicId = clinicRes?['id'] ?? 'a0000000-0000-0000-0000-000000000001';
      
      final code = await authRepo.generateInvitationCode(clinicId as String);
      if (code != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código generado con éxito: $code'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {}); // Recargar panel
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al generar el código'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    final client = ref.read(supabaseClientProvider);
    try {
      await client.from('profiles').update({'role': newRole}).eq('id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol de usuario actualizado a: $newRole'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el rol'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

  // ──────── Panel General ────────
  Widget _buildOverviewPanel() {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'totalUsers': 0,
          'dentists': 0,
          'patients': 0,
          'todayAppointments': 0,
        };
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(color: AppColors.primaryBlue),
                ),
              // Tarjetas de estadísticas
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.8,
                    children: [
                      _buildStatCard('Usuarios Totales', stats['totalUsers'].toString(), Icons.people, AppColors.primaryBlue),
                      _buildStatCard('Dentistas', stats['dentists'].toString(), Icons.medical_services, const Color(0xFF10B981)),
                      _buildStatCard('Pacientes', stats['patients'].toString(), Icons.person_outline, const Color(0xFFF59E0B)),
                      _buildStatCard('Citas Hoy', stats['todayAppointments'].toString(), Icons.calendar_today, const Color(0xFF8B5CF6)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Actividad reciente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                  children: [
                    const Text(
                      'Actividad Reciente',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildActivityItem('Sistema', 'Base de datos conectada correctamente', Icons.check_circle, AppColors.success),
                    const Divider(),
                    _buildActivityItem('Sistema', 'Supabase inicializado', Icons.cloud_done, AppColors.primaryBlue),
                    const Divider(),
                    _buildActivityItem('Info', 'Modo Super Admin activo con permisos completos', Icons.info_outline, const Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
  Widget _buildUsersManagementPanel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchProfiles(),
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gestión de Usuarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Administra las cuentas y roles del sistema', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Para crear nuevos usuarios, utilicen el registro general o un código de invitación paciente.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('Crear Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
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
                      Text(
                        'Los usuarios aparecerán aquí',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
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
                        DataColumn(label: Text('Acciones')),
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
                          DataCell(
                            DropdownButton<String>(
                              value: role,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                                DropdownMenuItem(value: 'admin_dentist', child: Text('Dentista')),
                                DropdownMenuItem(value: 'admin_secretary', child: Text('Secretaria')),
                                DropdownMenuItem(value: 'patient', child: Text('Paciente')),
                              ],
                              onChanged: (newRole) {
                                if (newRole != null && newRole != role) {
                                  _updateUserRole(userId, newRole);
                                }
                              },
                            ),
                          ),
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

  // ──────── Códigos de Invitación ────────
  Widget _buildInvitationCodesPanel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchInvitationCodes(),
      builder: (context, snapshot) {
        final codes = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Códigos de Invitación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Genera IDs para vincular pacientes a la clínica (RF-03)', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _generateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Generar Código', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (codes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.qr_code, size: 64, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text(
                        'Los códigos de invitación aparecerán aquí',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Genera un código y entrégaselo al paciente para que pueda vincularse a la clínica desde su app.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
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
                        DataColumn(label: Text('Código ID')),
                        DataColumn(label: Text('Creado el')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Usado por ID')),
                      ],
                      rows: codes.map((c) {
                        final code = c['code'] as String;
                        final createdAt = c['created_at'] != null 
                            ? DateTime.parse(c['created_at'] as String).toLocal().toString().substring(0, 16)
                            : '';
                        final isUsed = c['is_used'] as bool? ?? false;
                        final usedBy = c['used_by'] as String? ?? 'N/A';

                        return DataRow(cells: [
                          DataCell(Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 16))),
                          DataCell(Text(createdAt)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUsed ? Colors.grey[200] : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isUsed ? 'Usado' : 'Disponible',
                                style: TextStyle(
                                  color: isUsed ? Colors.grey : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(usedBy)),
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
