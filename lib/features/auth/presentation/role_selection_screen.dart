import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _handleRoleSelection(String role) async {
    setState(() => _isLoading = true);
    
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    
    if (user == null) {
      context.go('/login');
      return;
    }

    try {
      // 1. Check if the user has any clinic_memberships with this role
      // For dentists, they could be 'super_admin' or 'admin_dentist'
      // But 'Dentista Titular' means 'super_admin' or owner.
      // We will check for memberships.
      
      List<String> validRoles = [];
      if (role == 'dentist') {
        validRoles = ['owner', 'dentist']; // Dueño o dentista ayudante
      } else if (role == 'staff') {
        validRoles = ['secretary'];
      } else {
        validRoles = ['client'];
      }

      final memberships = await client
          .from('clinic_memberships')
          .select('clinic_id, role_in_clinic, clinics(business_name)')
          .eq('user_id', user.id)
          .inFilter('role_in_clinic', validRoles)
          .eq('is_active', true);

      if (!mounted) return;

      if (memberships.isEmpty) {
        // No clinics found for this role.
        if (role == 'dentist') {
          try {
            // Update profile role
            await client.from('profiles').update({'role': 'dentist'}).eq('id', user.id);
            // Create a clinic
            final clinicRes = await client.from('clinics').insert({'business_name': 'Clínica de ${user.userMetadata?['name'] ?? 'Doctor'}'}).select().single();
            // Create membership
            await client.from('clinic_memberships').insert({
              'clinic_id': clinicRes['id'],
              'user_id': user.id,
              'role_in_clinic': 'owner'
            });
            if (mounted) context.go('/dentist');
          } catch (e) {
            debugPrint('Error creating clinic: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al crear clínica. Falta permiso SQL.')),
              );
            }
          }
        } else {
          // If Client or Staff and no clinic, they must scan QR to link.
          final dbRole = role == 'staff' ? 'secretary' : 'client';
          context.go('/link-clinic?role=$dbRole');
        }
      } else if (memberships.length == 1) {
        // Exactly one clinic, route directly
        _routeToDashboard(memberships.first['role_in_clinic'] as String);
      } else {
        // Multiple clinics: Show a selector dialog
        await _showClinicSelectorDialog(List<Map<String, dynamic>>.from(memberships));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar perfiles')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showClinicSelectorDialog(List<Map<String, dynamic>> memberships) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona una Clínica'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: memberships.length,
              itemBuilder: (context, index) {
                final membership = memberships[index];
                final clinicName = membership['clinics'] != null ? membership['clinics']['business_name'] : 'Clínica Desconocida';
                final roleInClinic = membership['role_in_clinic'] as String;

                return ListTile(
                  leading: const Icon(Icons.local_hospital, color: AppColors.primaryBlue),
                  title: Text(clinicName),
                  subtitle: Text('Rol: $roleInClinic'),
                  onTap: () {
                    Navigator.pop(context);
                    // Set active clinic in state here if we had a provider
                    _routeToDashboard(roleInClinic);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _routeToDashboard(String dbRole) {
    if (dbRole == 'owner' || dbRole == 'dentist') {
      context.go('/dentist');
    } else if (dbRole == 'secretary') {
      context.go('/secretary');
    } else {
      context.go('/client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await ref.read(supabaseClientProvider).auth.signOut();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_circle, size: 80, color: AppColors.primaryBlue),
                    const SizedBox(height: 24),
                    const Text(
                      '¿Cómo deseas ingresar hoy?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona tu modo de uso. Podrás cambiarlo más tarde.',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 48),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildModeCard(
                          title: 'Dentista',
                          subtitle: 'Administra tu clínica o ayuda a otro colega',
                          icon: Icons.health_and_safety,
                          color: AppColors.primaryBlue,
                          onTap: () => _handleRoleSelection('dentist'),
                        ),
                        _buildModeCard(
                          title: 'Secretaria',
                          subtitle: 'Gestiona la clínica en la que trabajas',
                          icon: Icons.support_agent,
                          color: AppColors.warning,
                          onTap: () => _handleRoleSelection('staff'),
                        ),
                        _buildModeCard(
                          title: 'Cliente',
                          subtitle: 'Revisa tus citas y expediente',
                          icon: Icons.person,
                          color: AppColors.success,
                          onTap: () => _handleRoleSelection('client'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
