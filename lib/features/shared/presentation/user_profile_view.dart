import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sistema_dental/core/notifications/fcm_service.dart';
import 'package:sistema_dental/core/theme/app_colors.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';
import 'package:sistema_dental/features/client/data/notification_repository.dart';
import 'package:sistema_dental/features/shared/data/settings_repository.dart';

final wearCompanionLinkedProvider = FutureProvider<bool>((ref) async {
  return WearLinkService.instance.isCurrentSessionLinked();
});

class UserProfileView extends ConsumerWidget {
  final String roleLabel;
  final IconData avatarIcon;

  const UserProfileView({
    super.key,
    required this.roleLabel,
    this.avatarIcon = Icons.person,
  });

  Future<void> _setMobileNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final override = ref.read(mobileNotificationsOverrideProvider.notifier);
    enabled ? override.markEnabled() : override.markDisabled();

    final success = enabled
        ? await FcmService.instance.activateToken()
        : await FcmService.instance.deactivateToken();

    await ref.refresh(currentDeviceNotificationsProvider.future).then((_) {});
    if (!success) override.clear();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? enabled
                      ? 'Recordatorios activados.'
                      : 'Recordatorios desactivados.'
                : 'No se pudo actualizar recordatorios.',
          ),
          backgroundColor: success ? null : AppColors.error,
        ),
      );
    }
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref, {
    required String name,
    required String phone,
  }) {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información personal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await ref
                  .read(settingsRepositoryProvider)
                  .updateCurrentProfile(
                    name: nameController.text,
                    phone: phoneController.text,
                  );
              ref.invalidate(currentUserProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Perfil actualizado.'
                          : 'No se pudo actualizar el perfil.',
                    ),
                    backgroundColor: success ? null : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              final matches = password == confirmController.text.trim();
              final success =
                  matches &&
                  await ref
                      .read(settingsRepositoryProvider)
                      .changePassword(password);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Contraseña actualizada.'
                          : matches
                              ? 'No se pudo actualizar la contraseña.'
                              : 'Las contraseñas no coinciden.',
                    ),
                    backgroundColor: success ? null : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showLinkWatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vincular reloj inteligente'),
        content: const Text(
          'DentalSync buscará relojes Wear OS emparejados con este teléfono y enviará la sesión de forma automática.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final link = await WearLinkService.instance.linkCurrentSession(
                role: roleLabel,
              );
              ref.read(smartwatchLinkedOverrideProvider.notifier).markLinked();
              await ref.refresh(linkedDevicesProvider.future).then((_) {});
              ref.invalidate(wearCompanionLinkedProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      link.success
                          ? 'Reloj vinculado. Toca reintentar en el reloj.'
                          : link.message,
                    ),
                    backgroundColor: link.success ? null : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkWatchDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular reloj inteligente'),
        content: const Text(
          '¿Deseas desvincular los relojes inteligentes de esta cuenta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(notificationRepositoryProvider);
              ref
                  .read(smartwatchLinkedOverrideProvider.notifier)
                  .markUnlinked();
              final success = await repo.deactivateSmartwatchDevices();
              final unlinkNotice = await WearLinkService.instance
                  .unlinkCurrentSession();
              await ref.refresh(linkedDevicesProvider.future).then((_) {});
              ref.invalidate(wearCompanionLinkedProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? unlinkNotice.success
                                ? 'Reloj inteligente desvinculado. Actualiza el reloj.'
                                : 'Reloj inteligente desvinculado en la aplicación. Actualiza o reinicia el reloj si sigue conectado.'
                          : 'No se pudo desvincular el reloj inteligente.',
                    ),
                    backgroundColor: success ? null : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final devicesAsync = ref.watch(linkedDevicesProvider);
    final companionLinkedAsync = ref.watch(wearCompanionLinkedProvider);
    final mobileNotificationsAsync = ref.watch(
      currentDeviceNotificationsProvider,
    );

    final user = userAsync.value;
    final linkedDevices = devicesAsync.value ?? [];
    final smartwatchOverride = ref.watch(smartwatchLinkedOverrideProvider);
    final mobileNotificationsOverride = ref.watch(
      mobileNotificationsOverrideProvider,
    );

    final watchDevices = linkedDevices.where(
      (device) =>
          device['device_type'] == 'watch_os' ||
          device['device_type'] == 'wear_os',
    );
    final isWatchLinked =
        smartwatchOverride ??
        ((companionLinkedAsync.value ?? false) || watchDevices.isNotEmpty);
    final areMobileNotificationsOn =
        mobileNotificationsOverride ??
        (mobileNotificationsAsync.value ?? false);

    final userName = user?.name ?? 'Usuario';
    final userEmail = user?.email ?? 'correo@email.com';
    final userPhone = user?.phone ?? '';
    final userId = user?.id != null
        ? (user!.id.length > 8 ? user.id.substring(0, 8) : user.id)
        : 'DS-PEND';

    var watchSubtitle = 'Sincronización con dispositivos';
    if (isWatchLinked) {
      watchSubtitle = 'Conectado: Wear OS mediante el teléfono';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.lightBlueAccent,
            child: Icon(avatarIcon, size: 58, color: AppColors.primaryBlue),
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
            'Identificador: $userId',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(userEmail, style: const TextStyle(color: AppColors.primaryBlue)),
          const SizedBox(height: 32),
          _buildSectionTitle('PERFIL'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Información personal',
            subtitle: userPhone.isEmpty
                ? 'Nombre, identificador y contacto'
                : userPhone,
            onTap: () => _showEditProfileDialog(
              context,
              ref,
              name: userName,
              phone: userPhone,
            ),
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
              value: areMobileNotificationsOn,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (value) =>
                  _setMobileNotifications(context, ref, value),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.watch_outlined,
            title: 'Alertas del reloj inteligente',
            subtitle: watchSubtitle,
            trailing: Switch(
              value: isWatchLinked,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (value) {
                if (value) {
                  _showLinkWatchDialog(context, ref);
                } else {
                  _showUnlinkWatchDialog(context, ref);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('SEGURIDAD'),
          _buildSettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometría',
            subtitle: 'Acceso con seguridad del dispositivo',
            onTap: () => _showBiometricInfo(context),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.lock_reset,
            title: 'Cambiar contraseña',
            subtitle: 'Gestiona tus credenciales',
            onTap: () => _showChangePasswordDialog(context, ref),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                'Cambiar modo / rol',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(loginProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBiometricInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceso biométrico'),
        content: const Text(
          'La autenticación biométrica (Huella / Face ID) está sincronizada automáticamente con la seguridad de tu dispositivo.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.lightBlueAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}
