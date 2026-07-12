import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/client/data/notification_repository.dart';
import 'package:sistema_dental/features/client/data/patient_repository.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';
import 'package:sistema_dental/features/client/presentation/widgets/patient_selector.dart';
import 'package:sistema_dental/core/models/appointment.dart';
import 'package:intl/intl.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
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
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                icon: const CircleAvatar(
                  backgroundColor: AppColors.secondaryBlue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                onSelected: (value) async {
                  if (value == 'mode') {
                    context.go('/mode_selector');
                  } else if (value == 'logout') {
                    await ref.read(loginProvider.notifier).logout();
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
                        Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
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
    if (_selectedIndex == 1) {
      return const ClientScheduleView();
    } else if (_selectedIndex == 2) {
      return const ClientRecordsView();
    } else if (_selectedIndex == 3) {
      return const ClientProfileView();
    }
    
    // Vista Home
    return const ClientHomeView();
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
      final patientRes = await client.from('patients').select('id').eq('profile_id', user.id);
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
    final displayFirstName = selectedPatient?.firstName ?? userName.split(' ').first;

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
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
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
                child: Text('No tienes citas próximas.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(Map<String, dynamic> appt) {
    final date = DateTime.parse(appt['date_time']).toLocal();
    final dateStr = DateFormat('dd MMM, yyyy').format(date);
    final timeStr = DateFormat('hh:mm a').format(date);
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PRÓXIMA CITA', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(serviceName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Dr. $doctorName', style: const TextStyle(color: Colors.white, fontSize: 16)),
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
      final patientRes = await client.from('patients').select('id').eq('profile_id', user.id);
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
        const Text('Historial Médico', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 16),
        if (_completedAppointments.isEmpty)
          const Text('No hay registros médicos disponibles.', style: TextStyle(color: Colors.grey))
        else
          ..._completedAppointments.map((appt) {
            final date = DateTime.parse(appt['date_time']).toLocal();
            final doctorName = appt['doctors']?['profiles']?['name'] ?? 'Doctor';
            final serviceName = appt['services']?['service_name'] ?? 'Consulta';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lightBlueAccent,
                  child: Icon(Icons.check_circle, color: AppColors.primaryBlue),
                ),
                title: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Dr. $doctorName - ${DateFormat('dd MMM yyyy').format(date)}'),
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
  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(clientAppointmentsProvider);

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
          
          appointmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (appointments) {
              if (appointments.isEmpty) {
                return const Center(child: Text('No appointments found.'));
              }

              final activeAppts = appointments.where((a) => a.status == 'in_lobby' || a.status == 'in_treatment').toList();
              final activeAppt = activeAppts.isNotEmpty ? activeAppts.first : null;
              final otherAppts = appointments.where((a) => a.id != (activeAppt?.id)).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeAppt != null) ...[
                    const Text('Your Current Turn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildCurrentTurnCard(activeAppt),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('All Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('View Calendar', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...otherAppts.map((appt) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAppointmentListCard(appt),
                      )),
                ],
              );
            },
          ),
        ],
      ),
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
              Text(appointment.queueCode ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Text(appointment.status == 'in_lobby' ? 'IN QUEUE' : 'IN TREATMENT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  Text('Dr. ${appointment.doctorName ?? 'Dentist'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(appointment.serviceName ?? 'Consultation', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentListCard(Appointment appointment) {
    final month = DateFormat('MMM').format(appointment.dateTime).toUpperCase();
    final day = DateFormat('dd').format(appointment.dateTime);
    final time = DateFormat('hh:mm a').format(appointment.dateTime);
    final doctor = appointment.doctorName ?? 'Doctor';
    final details = '${appointment.serviceName ?? 'Consultation'} • $time';
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
                Text(doctor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
class ClientProfileView extends ConsumerWidget {
  const ClientProfileView({super.key});

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
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
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
