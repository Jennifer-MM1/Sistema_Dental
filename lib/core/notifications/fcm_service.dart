import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Handler de mensajes en background (debe ser función top-level, no un método)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Los mensajes en background se manejan automáticamente por el sistema operativo.
  // Solo necesitamos este handler registrado para que FCM funcione en background.
  debugPrint('[FCM Background] Mensaje recibido: ${message.notification?.title}');
}

/// Servicio centralizado para notificaciones push con Firebase Cloud Messaging.
///
/// Flujo:
/// 1. [initialize] se llama una vez en main() después de Firebase.initializeApp().
/// 2. Solicita permisos al usuario.
/// 3. Obtiene el token FCM del dispositivo.
/// 4. Registra el token en la tabla `linked_devices` de Supabase.
/// 5. Configura handlers para notificaciones en foreground y background.
class FcmService {
  static final FcmService _instance = FcmService._();
  FcmService._();
  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal de notificaciones Android (nombre visible al usuario en Settings)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'dentalsync_high_importance',
    'DentalSync – Turnos',
    description: 'Notificaciones de turno y cola de la clínica DentalSync.',
    importance: Importance.max,
  );

  // ───────────────────────────────────────────────────────────────────────────
  //  INICIALIZACIÓN PRINCIPAL
  // ───────────────────────────────────────────────────────────────────────────

  /// Llamar una sola vez al inicio de la app (en main.dart).
  /// Solo activo en plataformas que soporten FCM (Android, iOS, macOS, Web).
  Future<void> initialize() async {
    // FCM no está disponible en Windows/Linux desktop
    if (!_isFcmSupported) {
      debugPrint('[FCM] Plataforma no soportada: ${Platform.operatingSystem}');
      return;
    }

    // 1. Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Solicitar permisos
    await _requestPermissions();

    // 3. Configurar notificaciones locales (para mostrar en foreground)
    await _setupLocalNotifications();

    // 4. Handlers de mensajes en foreground
    _setupForegroundHandler();

    // 5. Obtener token FCM y guardarlo en Supabase
    await _registerDeviceToken();

    // 6. Escuchar cambios de token (cuando FCM rota el token)
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

    debugPrint('[FCM] Servicio inicializado correctamente.');
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  PERMISOS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Estado de permiso: ${settings.authorizationStatus}');
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  NOTIFICACIONES LOCALES (app en foreground)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    // Crear el canal de alta importancia en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  HANDLER FOREGROUND
  // ───────────────────────────────────────────────────────────────────────────

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      debugPrint('[FCM Foreground] ${notification?.title}: ${notification?.body}');

      // Mostrar notificación local si la app está en primer plano
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: const Color(0xFF006C9C), // AppColors.primaryBlue
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  REGISTRO DE TOKEN FCM EN SUPABASE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _registerDeviceToken() async {
    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('[FCM] No se pudo obtener el token FCM.');
      return;
    }
    await _saveTokenToSupabase(token);
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final deviceType = _getDeviceType();

    try {
      final existing = await Supabase.instance.client
          .from('linked_devices')
          .select()
          .eq('user_id', user.id)
          .eq('device_type', deviceType)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('linked_devices')
            .update({'push_token': token, 'is_active': true})
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('linked_devices').insert({
          'user_id': user.id,
          'device_type': deviceType,
          'push_token': token,
          'is_active': true,
        });
      }
      debugPrint('[FCM] Token guardado en Supabase ($deviceType).');
    } catch (e) {
      debugPrint('[FCM] Error guardando token: $e');
    }
  }

  /// Desactiva el token del dispositivo actual (llamar al cerrar sesión).
  Future<void> deactivateToken() async {
    if (!_isFcmSupported) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final deviceType = _getDeviceType();
    try {
      await Supabase.instance.client
          .from('linked_devices')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('device_type', deviceType);
      debugPrint('[FCM] Token desactivado.');
    } catch (e) {
      debugPrint('[FCM] Error desactivando token: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  UTILIDADES
  // ───────────────────────────────────────────────────────────────────────────

  bool get _isFcmSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  String _getDeviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'watch_os'; // Placeholder para macOS
    return 'android';
  }
}
