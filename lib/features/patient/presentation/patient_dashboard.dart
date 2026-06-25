import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/patient/data/notification_repository.dart';

class PatientDashboard extends ConsumerStatefulWidget {
  const PatientDashboard({super.key});

  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _selectedIndex == 3 
            ? const Icon(Icons.medical_services_outlined, color: AppColors.primaryBlue) 
            : IconButton(
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () {},
              ),
        title: Text(
          _selectedIndex == 3 ? 'DentalSync Connect' : 'DentalSync',
          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
              onPressed: () {},
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: AppColors.secondaryBlue,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.value?.name ?? 'Paciente';

    if (_selectedIndex == 1) {
      return const PatientScheduleView();
    } else if (_selectedIndex == 3) {
      return const PatientProfileView();
    }
    
    // Vista Home
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, $userName!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu salud dental es nuestra prioridad hoy.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Tarjeta de Próxima Cita
          Container(
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PRÓXIMA CITA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.circle, color: AppColors.success, size: 10),
                              SizedBox(width: 4),
                              Text('EN SALA DE ESPERA', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Limpieza General', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Dr. Roberto Valenzuela', style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('14 Oct, 2023', style: TextStyle(color: Colors.white)),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('10:30 AM', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Grid de Acciones (Reemplazado Pagos por Tratamientos)
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.folder_open,
                  title: 'Mis Registros',
                  subtitle: 'Ver historial clínico',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.medical_information,
                  title: 'Mis Tratamientos',
                  subtitle: 'Planes activos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFullWidthCard(
            icon: Icons.chat_bubble_outline,
            title: 'Contactar Clínica',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Salud Bucal',
                  subtitle: 'Progreso de Tratamiento',
                  value: '75%',
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Alertas',
                  subtitle: 'Revisión pendiente',
                  icon: Icons.notifications_active,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String subtitle, String? value, IconData? icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: value != null 
                  ? Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold))
                  : Icon(icon, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Vista de Schedule (Segunda pestaña)
class PatientScheduleView extends StatelessWidget {
  const PatientScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de búsqueda simulado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                Text('Search appointments or dentists', style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Tabs
          Row(
            children: [
              const Text('Upcoming', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 24),
              Text('Past', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              const SizedBox(width: 24),
              Text('Cancelled', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 70,
            height: 3,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 24),
          
          const Text('Your Current Turn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Tarjeta de Turno
          Container(
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
                    const Text('QUEUE NUMBER', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                    const Text('ESTIMATED: 12 MIN', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('B-42', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text('IN QUEUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Dr. Sarah Jenkins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Root Canal Consultation', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('View Calendar', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Lista de citas
          _buildAppointmentListCard('OCT', '24', 'Michael Chen', 'Annual Cleaning • 09:30 AM'),
          const SizedBox(height: 12),
          _buildAppointmentListCard('OCT', '24', 'Elena Rodriguez', 'Orthodontics Checkup • 02:15 PM'),
        ],
      ),
    );
  }

  Widget _buildAppointmentListCard(String month, String day, String patientOrDoctor, String details) {
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
                Text(month, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(day, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patientOrDoctor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(details, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
class PatientProfileView extends ConsumerWidget {
  const PatientProfileView({super.key});

  void _showLinkWatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vincular Smartwatch'),
          content: const Text(
            'Elige la plataforma de tu reloj inteligente para conectarlo con DentalSync y recibir notificaciones en tiempo real.',
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.watch, color: AppColors.primaryBlue),
                  label: const Text('Apple Watch (watchOS)'),
                  onPressed: () async {
                    final repo = ref.read(notificationRepositoryProvider);
                    await repo.registerDevice(
                      deviceType: 'watch_os',
                      pushToken: 'mock_apple_watch_token_${ref.read(authRepositoryProvider).currentAuthUser?.id ?? ""}',
                    );
                    ref.invalidate(linkedDevicesProvider);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Apple Watch vinculado correctamente!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.watch_rounded, color: AppColors.secondaryBlue),
                  label: const Text('Wear OS (Android)'),
                  onPressed: () async {
                    final repo = ref.read(notificationRepositoryProvider);
                    await repo.registerDevice(
                      deviceType: 'wear_os',
                      pushToken: 'mock_wear_os_token_${ref.read(authRepositoryProvider).currentAuthUser?.id ?? ""}',
                    );
                    ref.invalidate(linkedDevicesProvider);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Smartwatch Wear OS vinculado correctamente!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showUnlinkWatchDialog(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> devices) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desvincular Smartwatch'),
          content: const Text('¿Estás seguro de que deseas desvincular tus relojes inteligentes de DentalSync? Dejarás de recibir notificaciones de tu turno.'),
          actions: [
            TextButton(
              onPressed: () async {
                final repo = ref.read(notificationRepositoryProvider);
                for (final d in devices) {
                  await repo.deactivateDevice(d['device_type'] as String);
                }
                ref.invalidate(linkedDevicesProvider);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dispositivos desvinculados.'),
                    ),
                  );
                }
              },
              child: const Text('Sí, Desvincular', style: TextStyle(color: AppColors.error)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
    final userEmail = user?.email ?? 'correo@email.com';
    final userId = user?.id != null ? (user!.id.length > 8 ? user.id.substring(0, 8) : user.id) : 'DS-2026-PEND';

    final linkedDevices = devicesAsync.value ?? [];
    final isWatchLinked = linkedDevices.any((d) => d['device_type'] == 'watch_os' || d['device_type'] == 'wear_os');
    
    // Descripción del smartwatch conectado
    String watchSubtitle = 'Sincronización con dispositivos';
    if (isWatchLinked) {
      final types = linkedDevices.map((d) {
        final dt = d['device_type'] as String;
        return dt == 'watch_os' ? 'Apple Watch' : 'Wear OS';
      }).join(', ');
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
                child: Icon(Icons.person, size: 60, color: AppColors.primaryBlue),
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
          Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Paciente ID: $userId', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(userEmail, style: const TextStyle(color: AppColors.primaryBlue)),
          
          const SizedBox(height: 32),
          
          // Secciones de Configuración
          _buildSectionTitle('PERFIL'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Información Personal',
            subtitle: 'Nombre, ID y Contacto',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('NOTIFICACIONES'),
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: 'Recordatorios',
            subtitle: 'Próximas citas y tratamientos',
            trailing: Switch(
              value: true,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) {},
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.watch_outlined,
            title: 'Alertas de Smartwatch',
            subtitle: watchSubtitle,
            trailing: Switch(
              value: isWatchLinked,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) {
                if (val) {
                  _showLinkWatchDialog(context, ref);
                } else {
                  _showUnlinkWatchDialog(context, ref, linkedDevices);
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
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.lock_reset,
            title: 'Cambiar Contraseña',
            subtitle: 'Última actualización hace 3 meses',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
                backgroundColor: AppColors.error.withOpacity(0.1),
                foregroundColor: AppColors.error,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('Versión 2.4.0 (Build 882)', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
