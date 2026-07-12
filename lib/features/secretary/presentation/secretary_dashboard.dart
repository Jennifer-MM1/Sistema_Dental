import 'package:flutter/material.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
        title: const Text('DentalSync Admin', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Row(
        children: [
          // Sidebar
          if (isDesktop) _buildSidebar(),
          // Main Content
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildTopBar(),
                Expanded(
                  child: _buildMainContent(),
                ),
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
      color: const Color(0xFFF1F5F9), // Color grisáceo claro
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('DentalSync', style: TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Administración Central', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(0, Icons.dashboard_outlined, 'Panel General'),
          _buildSidebarItem(1, Icons.people_outline, 'Gestión Pacientes'),
          _buildSidebarItem(2, Icons.medical_services_outlined, 'Gestión Dentistas'),
          _buildSidebarItem(3, Icons.calendar_month_outlined, 'Agenda Global'),
          _buildSidebarItem(4, Icons.receipt_long_outlined, 'Facturación'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                    child: Icon(Icons.support_agent, size: 20, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Recepción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                        Text('Secretaría', style: TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
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
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
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
            child: Text('DentalSync Connect', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.sync, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none, color: AppColors.error),
          const SizedBox(width: 16),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.textSecondary),
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
                    Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
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
        return const SecretaryDashboardView();
      case 1:
        return const PatientsManagementView();
      case 2:
        return const DentistsManagementView();
      default:
        return const Center(child: Text('Vista en desarrollo...'));
    }
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
  double _dailyIncome = 0;
  List<dynamic> _upcomingAppts = [];

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
      
      final clinicId = membership['clinic_id'];

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
      final startOfDay = DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toUtc().toIso8601String();

      final appts = await client
          .from('appointments')
          .select('*, patients(first_name, last_name), doctors(profiles(name)), services(service_name, price)')
          .eq('clinic_id', clinicId)
          .gte('date_time', startOfDay)
          .lte('date_time', endOfDay)
          .order('date_time', ascending: true);

      _appointmentsToday = appts.length;
      
      double income = 0;
      for (var appt in appts) {
        if (appt['status'] == 'completed') {
          income += (appt['services']?['price'] ?? 0).toDouble();
        }
      }
      _dailyIncome = income;
      
      _upcomingAppts = appts.where((a) => a['status'] != 'completed' && a['status'] != 'cancelled').take(3).toList();

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
          const Text('Panel de Administración', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Resumen general de la clínica para el día de hoy.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              double width = (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: width, child: _buildStatCard('Citas Hoy', '$_appointmentsToday', 'Citas programadas', Icons.calendar_today)),
                  SizedBox(width: width, child: _buildStatCard('Clientes', '$_newPatients', 'En la clínica', Icons.person_add_alt_1)),
                  SizedBox(width: width, child: _buildStatCard('Dentistas', '$_activeDentists', 'Activos', Icons.medical_services)),
                  SizedBox(width: width, child: _buildStatCard('Ingresos Diarios', '\$${_dailyIncome.toStringAsFixed(2)}', 'En citas completadas', Icons.attach_money)),
                ],
              );
            }
          ),
          
          const SizedBox(height: 32),
          
          isDesktop ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildQuickActions()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildUpcomingAppointments()),
            ],
          ) : Column(
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Acciones Frecuentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Registrar Paciente', style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryBlue,
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            label: const Text('Agendar Cita Manual', style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightBlueAccent,
              foregroundColor: AppColors.primaryBlue,
              minimumSize: const Size(double.infinity, 50),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              elevation: 0,
            ),
            icon: const Icon(Icons.payment),
            label: const Text('Registrar Pago', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Citas Inminentes (Global)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Divider(),
          if (_upcomingAppts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay citas pendientes para hoy.', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._upcomingAppts.map((appt) {
              final date = DateTime.parse(appt['date_time']).toLocal();
              final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              final patientName = '${appt['patients']?['first_name'] ?? 'Paciente'} ${appt['patients']?['last_name'] ?? ''}';
              final doctorName = appt['doctors']?['profiles']?['name'] ?? 'Doctor';
              final reason = appt['services']?['service_name'] ?? 'Consulta';
              return Column(
                children: [
                  _buildAppointmentRow(time, patientName, 'Dr. $doctorName', reason),
                  const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {
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
              Expanded(child: Text(title, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAppointmentRow(String time, String patient, String doctor, String reason) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          SizedBox(width: 120, child: Text(patient, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 100, child: Text(doctor, style: const TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Text(reason, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
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
      
      final clinicId = membership['clinic_id'];

      final patientsRes = await client
          .from('patients')
          .select('*, profiles(phone)')
          .eq('clinic_id', clinicId);

      setState(() {
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
                     Text('Gestión de Pacientes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                     Text('Directorio completo de pacientes', style: TextStyle(color: Colors.grey)),
                   ],
                 ),
                 ElevatedButton.icon(
                   onPressed: () {},
                   style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                   icon: const Icon(Icons.person_add, color: Colors.white),
                   label: const Text('Añadir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ],
             ),
             const SizedBox(height: 24),
             Container(
               width: double.infinity,
               padding: EdgeInsets.all(isDesktop ? 24 : 16),
               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
               child: SingleChildScrollView(
                 scrollDirection: Axis.horizontal,
                 child: ConstrainedBox(
                   constraints: const BoxConstraints(minWidth: 800),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: const [
                           SizedBox(width: 100, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                           SizedBox(width: 250, child: Text('Nombre del Paciente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                           SizedBox(width: 150, child: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                           SizedBox(width: 150, child: Text('Relación', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                           SizedBox(width: 100, child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                         ],
                       ),
                       const Divider(height: 32),
                       if (_patients.isEmpty)
                         const Padding(
                           padding: EdgeInsets.all(16.0),
                           child: Text('No hay pacientes registrados en esta clínica.', style: TextStyle(color: Colors.grey)),
                         )
                       else
                         ..._patients.map((p) {
                           final id = p['id'].toString().substring(0, 8);
                           final name = '${p['first_name']} ${p['last_name']}';
                           final phone = p['profiles']?['phone'] ?? 'No registrado';
                           final relation = p['relationship'] ?? 'self';
                           
                           return Column(
                             children: [
                               _buildPatientRow(id, name, phone, relation),
                               const Divider(),
                             ],
                           );
                         }),
                     ],
                   ),
                 ),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildPatientRow(String id, String name, String phone, String lastVisit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 12))),
          SizedBox(width: 250, child: Row(
            children: [
              const CircleAvatar(radius: 12, backgroundColor: AppColors.lightBlueAccent, child: Icon(Icons.person, size: 14, color: AppColors.primaryBlue)),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          )),
          SizedBox(width: 150, child: Text(phone, style: const TextStyle(color: Colors.grey))),
          SizedBox(width: 150, child: Text(lastVisit, style: const TextStyle(color: Colors.grey))),
          SizedBox(width: 100, child: Row(
            children: const [
              Icon(Icons.edit, color: Colors.grey, size: 20),
              SizedBox(width: 16),
              Icon(Icons.calendar_month, color: AppColors.primaryBlue, size: 20),
            ],
          )),
        ],
      ),
    );
  }
}

class DentistsManagementView extends StatefulWidget {
  const DentistsManagementView({super.key});

  @override
  State<DentistsManagementView> createState() => _DentistsManagementViewState();
}

class _DentistsManagementViewState extends State<DentistsManagementView> {
  bool _isLoading = true;
  List<dynamic> _dentists = [];

  @override
  void initState() {
    super.initState();
    _fetchDentists();
  }

  Future<void> _fetchDentists() async {
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
      
      final clinicId = membership['clinic_id'];

      final dentistsRes = await client
          .from('clinic_memberships')
          .select('*, profiles(name)')
          .eq('clinic_id', clinicId)
          .inFilter('role_in_clinic', ['owner', 'dentist']);

      setState(() {
        _dentists = dentistsRes;
      });
    } catch (e) {
      debugPrint('Error fetch dentists: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDesktop = MediaQuery.of(context).size.width > 900;
    
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
                     Text('Gestión de Dentistas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                     Text('Administración del personal médico', style: TextStyle(color: Colors.grey)),
                   ],
                 ),
                 ElevatedButton.icon(
                   onPressed: () {},
                   style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                   icon: const Icon(Icons.medical_services, color: Colors.white),
                   label: const Text('Registrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ],
             ),
             const SizedBox(height: 24),
             if (_dentists.isEmpty)
               const Text('No hay dentistas registrados.', style: TextStyle(color: Colors.grey))
             else
               LayoutBuilder(
                 builder: (context, constraints) {
                   int columns = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                   double width = (constraints.maxWidth - (columns - 1) * 24) / columns;
                   return Wrap(
                     spacing: 24,
                     runSpacing: 24,
                     children: _dentists.map((doc) {
                       final name = doc['profiles']?['name'] ?? 'Doctor';
                       final specialty = doc['role_in_clinic'] == 'owner' ? 'Director/General' : 'General';
                       final isOnline = doc['is_active'] == true;
                       return SizedBox(
                         width: width,
                         child: _buildDentistCard(name, specialty, 'Consultorio', isOnline),
                       );
                     }).toList(),
                   );
                 }
               )
          ],
        ),
      ),
    );
  }

  Widget _buildDentistCard(String name, String specialty, String room, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(radius: 30, backgroundColor: AppColors.lightBlueAccent, child: Icon(Icons.person, size: 30, color: AppColors.primaryBlue)),
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(specialty, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Text(room, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
