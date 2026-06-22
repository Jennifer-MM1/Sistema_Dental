import 'package:flutter/material.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class DentistDashboard extends StatefulWidget {
  const DentistDashboard({super.key});

  @override
  State<DentistDashboard> createState() => _DentistDashboardState();
}

class _DentistDashboardState extends State<DentistDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
        title: const Text('DentalSync', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
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
      color: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('DentalSync', style: TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('City Dental Plaza', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(0, Icons.grid_view, 'Dashboard'),
          _buildSidebarItem(1, Icons.people_outline, 'Patient Queue'),
          _buildSidebarItem(2, Icons.folder_open, 'Clinical Records'),
          _buildSidebarItem(3, Icons.sync, 'Team Sync'),
          _buildSidebarItem(4, Icons.settings_outlined, 'Settings'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryBlue,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.emergency),
              label: const Text('Emergency Call'),
            ),
          ),
          const SizedBox(height: 16),
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
                    child: Icon(Icons.person, size: 20, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Clinic Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                        Text('Admin Profile', style: TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
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
          Navigator.of(context).pop(); // Cerrar drawer en móvil
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
                  hintText: 'Search...',
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
        return const DashboardView();
      case 1:
        return const QueueView();
      case 2:
        return const CalendarView();
      case 4:
        return const SettingsView();
      default:
        return const Center(child: Text('Vista en desarrollo...'));
    }
  }
}

// ----------------------------------------------------
// Vistas Individuales
// ----------------------------------------------------

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard Principal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Welcome back, Dr. Aris. Here is your practice status for today.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildQuickActions()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildStatsAndQueue(isDesktop)),
              ],
            )
          else
            Column(
              children: [
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildStatsAndQueue(isDesktop),
              ],
            ),
            
          const SizedBox(height: 24),
          // Efficiency Section
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: isDesktop ? Row(
              children: [
                Expanded(child: _buildEfficiencyContent()),
                Expanded(child: _buildEfficiencyImage()),
              ],
            ) : Column(
              children: [
                _buildEfficiencyContent(),
                const SizedBox(height: 16),
                _buildEfficiencyImage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
          const Text('Quick Actions', style: TextStyle(fontSize: 18, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildQuickActionButton(Icons.person_add, 'New Patient Check-in', isPrimary: true),
          const SizedBox(height: 12),
          _buildQuickActionButton(Icons.add_circle_outline, 'Schedule Appointment'),
          const SizedBox(height: 12),
          _buildQuickActionLightButton(Icons.upload_file, 'Upload X-Rays'),
          const SizedBox(height: 12),
          _buildQuickActionLightButton(Icons.receipt_long, 'Generate Invoice'),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Daily Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text('85%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryBlue)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.85,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndQueue(bool isDesktop) {
    return Column(
      children: [
        isDesktop ? Row(
          children: [
            Expanded(child: _buildStatCard('Today\'s Appointments', '24', '+ 12% vs last Monday', Icons.calendar_today)),
            const SizedBox(width: 24),
            Expanded(child: _buildStatCard('Average Wait', '14min', 'Live Updates', Icons.timer_outlined, isUp: false)),
          ],
        ) : Column(
          children: [
            _buildStatCard('Today\'s Appointments', '24', '+ 12% vs last Monday', Icons.calendar_today),
            const SizedBox(height: 16),
            _buildStatCard('Average Wait', '14min', 'Live Updates', Icons.timer_outlined, isUp: false),
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
                  Text('Upcoming Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('View All', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              _buildQueueItem('Eleanor Shellstrop', 'Routine Cleaning', '09:15 AM', 'Room 04', AppColors.lightBlueAccent),
              const Divider(),
              _buildQueueItem('Chidi Anagonye', 'Root Canal Follow-up', '09:45 AM', 'Waiting', Colors.grey.shade200),
              const Divider(),
              _buildQueueItem('Tahani Al-Jamil', 'Orthodontic Adjustment', '10:30 AM', 'Delayed', AppColors.error.withOpacity(0.1), isError: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Practice Efficiency', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        const Text('Clinical Room Utilization', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Your team is operating at 92% efficiency today. Room 02 will be available in approximately 8 minutes for the next patient.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('08', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                Text('Available Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('03', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                Text('Active Doctors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEfficiencyImage() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.lightBlueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Icon(Icons.chair_alt, size: 64, color: Colors.white)),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, {bool isPrimary = false}) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primaryBlue : AppColors.lightBlueAccent,
        foregroundColor: isPrimary ? Colors.white : AppColors.primaryBlue,
        minimumSize: const Size(double.infinity, 50),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildQuickActionLightButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(double.infinity, 50),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
      ),
      icon: Icon(icon, color: Colors.grey.shade600),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, {bool isUp = true}) {
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
              Expanded(child: Text(title, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward : Icons.circle, size: 12, color: isUp ? AppColors.primaryBlue : AppColors.primaryBlue),
              const SizedBox(width: 4),
              Expanded(child: Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(String name, String details, String time, String status, Color statusColor, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            child: Text(name.substring(0, 2), style: const TextStyle(color: AppColors.primaryBlue)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(details, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: TextStyle(color: isError ? AppColors.error : AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          children: [
             // "Próximo na fila" Card
             Container(
               width: double.infinity,
               padding: EdgeInsets.all(isDesktop ? 24 : 16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(16)),
                         child: const Text('Próximo en Fila', style: TextStyle(color: Colors.white, fontSize: 12)),
                       ),
                       const Flexible(child: Text('Cabina 04 Disponible', style: TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                     ],
                   ),
                   const SizedBox(height: 16),
                   const Text('Ricardo Oliveira', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                   const Text('Ticket #D-128 • Limpieza Periódica', style: TextStyle(color: AppColors.textSecondary)),
                   const SizedBox(height: 24),
                   isDesktop ? Row(
                     children: [
                       Expanded(
                         flex: 3,
                         child: ElevatedButton.icon(
                           onPressed: () {},
                           style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryBlue, padding: const EdgeInsets.symmetric(vertical: 16)),
                           icon: const Icon(Icons.call_made),
                           label: const Text('Llamar Próximo Paciente'),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         flex: 1,
                         child: OutlinedButton(
                           onPressed: () {},
                           style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                           child: const Text('Saltar'),
                         ),
                       ),
                     ],
                   ) : Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       ElevatedButton.icon(
                         onPressed: () {},
                         style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryBlue, padding: const EdgeInsets.symmetric(vertical: 16)),
                         icon: const Icon(Icons.call_made),
                         label: const Text('Llamar Próximo Paciente'),
                       ),
                       const SizedBox(height: 8),
                       OutlinedButton(
                         onPressed: () {},
                         style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                         child: const Text('Saltar'),
                       ),
                     ],
                   )
                 ],
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
                       const Text('Detalles de Cola', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_list, size: 16), label: const Text('Filter')),
                     ],
                   ),
                   const SizedBox(height: 16),
                   SingleChildScrollView(
                     scrollDirection: Axis.horizontal,
                     child: ConstrainedBox(
                       constraints: BoxConstraints(minWidth: isDesktop ? 600 : 700),
                       child: Column(
                         children: [
                           Row(
                             children: const [
                               SizedBox(width: 80, child: Text('Ticket', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                               SizedBox(width: 200, child: Text('Paciente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                               SizedBox(width: 150, child: Text('Servicio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                               SizedBox(width: 100, child: Text('Espera', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                               SizedBox(width: 150, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                             ],
                           ),
                           const Divider(),
                           _buildRow('#D-127', 'Marcos Andreotti', 'Endodoncia', '45 min', 'En Tratamiento', AppColors.primaryBlue),
                           const Divider(),
                           _buildRow('#D-128', 'Ricardo Oliveira', 'Limpieza', '22 min', 'Preparando', Colors.teal),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
             )
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

  Widget _buildRow(String ticket, String name, String service, String wait, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(ticket, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue))),
          SizedBox(width: 200, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 150, child: Text(service, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 100, child: Text(wait)),
          SizedBox(
            width: 150, 
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Expanded(child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            )
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
            const Text('Calendario e Historial', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Gestión centralizada de citas.', style: TextStyle(color: Colors.grey)),
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
              child: const Center(child: Text('Vista de Calendario Semanal (Componente Dinámico)')),
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

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ajustes - Tablet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          const Text('Configure y gestione el ecosistema DentalSync para su clínica.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          
          isDesktop ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildProfileCard()),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildSecurityCard()),
            ],
          ) : Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildSecurityCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const CircleAvatar(radius: 40, backgroundColor: AppColors.lightBlueAccent, child: Icon(Icons.person, size: 40, color: AppColors.primaryBlue)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dra. Elena Martínez', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text('Administradora Jefe de Clínica - City Dental Plaza', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBadge('Ortodoncia'),
                  const SizedBox(width: 8),
                  _buildBadge('Admin'),
                ],
              )
            ],
          ),
          OutlinedButton(onPressed: () {}, child: const Text('Ver Perfil Público'))
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.security, color: Colors.white),
              SizedBox(width: 8),
              Text('Seguridad', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tu cuenta está protegida con verificación en dos pasos.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryBlue, minimumSize: const Size(double.infinity, 40)), child: const Text('Cambiar Contraseña')),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.lightBlueAccent, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
