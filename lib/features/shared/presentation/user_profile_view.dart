import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/client/data/notification_repository.dart';

class UserProfileView extends ConsumerWidget {
  final String roleLabel;
  final IconData avatarIcon;

  const UserProfileView({
    super.key,
    required this.roleLabel,
    this.avatarIcon = Icons.person,
  });

  void _showLinkWatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vincular Smartwatch'),
        content: const Text(
          'Elige la plataforma de tu reloj inteligente para recibir notificaciones de DentalSync.',
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
                    pushToken:
                        'mock_apple_watch_token_${ref.read(authRepositoryProvider).currentAuthUser?.id ?? ""}',
                  );
                  ref.invalidate(linkedDevicesProvider);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Apple Watch vinculado correctamente.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.watch_rounded,
                  color: AppColors.secondaryBlue,
                ),
                label: const Text('Wear OS (Android)'),
                onPressed: () async {
                  final repo = ref.read(notificationRepositoryProvider);
                  await repo.registerDevice(
                    deviceType: 'wear_os',
                    pushToken:
                        'mock_wear_os_token_${ref.read(authRepositoryProvider).currentAuthUser?.id ?? ""}',
                  );
                  ref.invalidate(linkedDevicesProvider);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wear OS vinculado correctamente.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUnlinkWatchDialog(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> devices,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular Smartwatch'),
        content: const Text(
          '¿Deseas desvincular los relojes inteligentes de esta cuenta?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final repo = ref.read(notificationRepositoryProvider);
              for (final device in devices) {
                await repo.deactivateDevice(device['device_type'] as String);
              }
              ref.invalidate(linkedDevicesProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispositivos desvinculados.')),
                );
              }
            },
            child: const Text(
              'Sí, desvincular',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final devicesAsync = ref.watch(linkedDevicesProvider);
    final user = userAsync.value;
    final linkedDevices = devicesAsync.value ?? [];
    final isWatchLinked = linkedDevices.any(
      (device) =>
          device['device_type'] == 'watch_os' ||
          device['device_type'] == 'wear_os',
    );

    final userName = user?.name ?? 'Usuario';
    final userEmail = user?.email ?? 'correo@email.com';
    final userId = user?.id != null
        ? (user!.id.length > 8 ? user.id.substring(0, 8) : user.id)
        : 'DS-PEND';

    var watchSubtitle = 'Sincronización con dispositivos';
    if (isWatchLinked) {
      final types = linkedDevices
          .map((device) {
            final type = device['device_type'] as String;
            return type == 'watch_os' ? 'Apple Watch' : 'Wear OS';
          })
          .join(', ');
      watchSubtitle = 'Conectado: $types';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.lightBlueAccent,
                child: Icon(avatarIcon, size: 58, color: AppColors.primaryBlue),
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
          Text(
            userName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            roleLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: $userId',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(userEmail, style: const TextStyle(color: AppColors.primaryBlue)),
          const SizedBox(height: 32),
          _buildSectionTitle('PERFIL'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Información Personal',
            subtitle: 'Nombre, ID y contacto',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('NOTIFICACIONES'),
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: 'Recordatorios',
            subtitle: 'Próximas citas y avisos internos',
            trailing: Switch(
              value: true,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.watch_outlined,
            title: 'Alertas de Smartwatch',
            subtitle: watchSubtitle,
            trailing: Switch(
              value: isWatchLinked,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (value) {
                if (value) {
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
            subtitle: 'Acceso con huella o rostro',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.lock_reset,
            title: 'Cambiar Contraseña',
            subtitle: 'Gestiona tus credenciales',
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/mode_selector'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                'Cambiar Modo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Versión 2.4.0',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
