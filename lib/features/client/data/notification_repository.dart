import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/notifications/fcm_service.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationRepository(client);
});

class SmartwatchLinkedOverrideNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void markLinked() => state = true;

  void markUnlinked() => state = false;

  void clear() => state = null;
}

final smartwatchLinkedOverrideProvider =
    NotifierProvider<SmartwatchLinkedOverrideNotifier, bool?>(() {
      return SmartwatchLinkedOverrideNotifier();
    });

class MobileNotificationsOverrideNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void markEnabled() => state = true;

  void markDisabled() => state = false;

  void clear() => state = null;
}

final mobileNotificationsOverrideProvider =
    NotifierProvider<MobileNotificationsOverrideNotifier, bool?>(() {
      return MobileNotificationsOverrideNotifier();
    });

/// Repositorio para gestionar la vinculación de dispositivos
/// y las notificaciones push hacia smartwatches (RF-09).
///
/// Registra los tokens push en la tabla `linked_devices` de Supabase
/// para que la Edge Function `notify-patient-turn` pueda enviar
/// alertas hápticas al reloj cuando el dentista presiona "Call Next Patient".
class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  /// Registra el token push del dispositivo actual en la tabla `linked_devices`.
  /// [deviceType] puede ser: 'watch_os', 'wear_os', 'ios', 'android', 'web'.
  /// [pushToken] es el token FCM (Android/Wear OS) o APNs (iOS/watchOS).
  Future<bool> registerDevice({
    required String deviceType,
    required String pushToken,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // Verificar si ya existe un registro para este dispositivo
      final existing = await _client
          .from('linked_devices')
          .select()
          .eq('user_id', user.id)
          .eq('device_type', deviceType)
          .maybeSingle();

      if (existing != null) {
        // Actualizar el token existente
        await _client
            .from('linked_devices')
            .update({'push_token': pushToken, 'is_active': true})
            .eq('id', existing['id']);
      } else {
        // Crear nuevo registro de dispositivo
        await _client.from('linked_devices').insert({
          'user_id': user.id,
          'device_type': deviceType,
          'push_token': pushToken,
          'is_active': true,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error registrando dispositivo $deviceType: $e');
      return false;
    }
  }

  /// Desactiva un dispositivo vinculado (al cerrar sesión, por ejemplo).
  Future<void> deactivateDevice(String deviceType) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('linked_devices')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('device_type', deviceType);
    } catch (e) {
      debugPrint('Error desactivando dispositivo $deviceType: $e');
    }
  }

  /// Desactiva solo los smartwatches vinculados a la cuenta actual.
  Future<bool> deactivateSmartwatchDevices() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final smartwatchTypes = ['watch_os', 'wear_os'];
      await _client
          .from('linked_devices')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .inFilter('device_type', smartwatchTypes);

      final remaining = await _client
          .from('linked_devices')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .inFilter('device_type', smartwatchTypes);

      return List.from(remaining).isEmpty;
    } catch (e) {
      debugPrint('Error desvinculando smartwatch: $e');
      return false;
    }
  }

  Future<bool> hasActiveSmartwatchDevice() async {
    final devices = await getLinkedSmartwatchDevices();
    return devices.isNotEmpty;
  }

  /// Obtiene todos los dispositivos vinculados del usuario actual.
  Future<List<Map<String, dynamic>>> getLinkedDevices() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('linked_devices')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLinkedSmartwatchDevices() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('linked_devices')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .inFilter('device_type', ['watch_os', 'wear_os']);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error obteniendo smartwatches vinculados: $e');
      return [];
    }
  }

  Future<bool> isDeviceTypeActive(String deviceType) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('linked_devices')
          .select('id')
          .eq('user_id', user.id)
          .eq('device_type', deviceType)
          .eq('is_active', true)
          .limit(1);

      return List.from(response).isNotEmpty;
    } catch (e) {
      debugPrint('Error consultando dispositivo $deviceType: $e');
      return false;
    }
  }

  /// Escucha cambios en la cita del paciente actual en tiempo real.
  /// Esto permite que la app del paciente muestre actualizaciones
  /// de su posición en la cola y su estado (in_lobby, in_treatment).
  RealtimeChannel subscribeToAppointmentChanges({
    required String patientId,
    required void Function(Map<String, dynamic> payload) onUpdate,
  }) {
    return _client
        .channel('appointment_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }
}

final linkedDevicesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getLinkedSmartwatchDevices();
});

final currentDeviceNotificationsProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final deviceType = ref.watch(currentNotificationDeviceTypeProvider);
  if (deviceType == null) return false;
  return repo.isDeviceTypeActive(deviceType);
});

final currentNotificationDeviceTypeProvider = Provider<String?>(
  (ref) => FcmService.instance.currentDeviceType,
);
