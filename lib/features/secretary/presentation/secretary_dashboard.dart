import 'package:flutter/material.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

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
          InkWell(
            onTap: () => context.go('/login'),
            child: const Icon(Icons.account_circle_outlined, color: AppColors.textSecondary),
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

class SecretaryDashboardView extends StatelessWidget {
  const SecretaryDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
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
          
          // LayoutBuilder para KPIs en lugar de GridView que fallaba en alturas
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              double width = (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: width, child: _buildStatCard('Citas Hoy', '42', 'En 3 consultorios', Icons.calendar_today)),
                  SizedBox(width: width, child: _buildStatCard('Nuevos Pacientes', '5', 'Esta semana', Icons.person_add_alt_1)),
                  SizedBox(width: width, child: _buildStatCard('Dentistas Activos', '4', 'En turno', Icons.medical_services)),
                  SizedBox(width: width, child: _buildStatCard('Ingresos Diarios', '\$1,240', '+15% vs ayer', Icons.attach_money)),
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
          _buildAppointmentRow('10:00 AM', 'Carlos Mendoza', 'Dr. Aris', 'Extracción'),
          const Divider(),
          _buildAppointmentRow('10:15 AM', 'Lucía Fernández', 'Dra. Elena', 'Consulta General'),
          const Divider(),
          _buildAppointmentRow('10:30 AM', 'Mateo Ruiz', 'Dr. Roberto', 'Ortodoncia'),
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

class PatientsManagementView extends StatelessWidget {
  const PatientsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
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
                           SizedBox(width: 150, child: Text('Última Visita', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                           SizedBox(width: 100, child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                         ],
                       ),
                       const Divider(height: 32),
                       _buildPatientRow('DS-2024-9912', 'Ana Martínez', '+34 612 345 678', '14 Oct, 2023'),
                       const Divider(),
                       _buildPatientRow('DS-2024-9913', 'Carlos Mendoza', '+34 699 888 777', '12 Oct, 2023'),
                       const Divider(),
                       _buildPatientRow('DS-2024-9914', 'Lucía Fernández', '+34 655 444 333', '10 Sep, 2023'),
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

class DentistsManagementView extends StatelessWidget {
  const DentistsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
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
             LayoutBuilder(
               builder: (context, constraints) {
                 int columns = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                 double width = (constraints.maxWidth - (columns - 1) * 24) / columns;
                 final dentists = [
                   {'name': 'Dra. Elena Martínez', 'specialty': 'Ortodoncia', 'room': 'Consultorio 1', 'isOnline': true},
                   {'name': 'Dr. Roberto Valenzuela', 'specialty': 'General', 'room': 'Consultorio 2', 'isOnline': true},
                   {'name': 'Dr. Aris', 'specialty': 'Cirugía', 'room': 'Consultorio 3', 'isOnline': false},
                 ];
                 return Wrap(
                   spacing: 24,
                   runSpacing: 24,
                   children: dentists.map((doc) => SizedBox(
                     width: width,
                     child: _buildDentistCard(doc['name'] as String, doc['specialty'] as String, doc['room'] as String, doc['isOnline'] as bool),
                   )).toList(),
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
