import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_theme.dart';
import 'package:sistema_dental/core/router/app_router.dart';
import 'package:sistema_dental/core/notifications/fcm_service.dart';
import 'package:sistema_dental/core/wear/wear_link_service.dart';
// ignore: uri_does_not_exist
import 'firebase_options.dart'; // Generado por FlutterFire CLI

void main() async {
  debugPrint("=== INICIANDO APP ===");
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("[1/4] WidgetsFlutterBinding inicializado.");
  } catch (e) {
    debugPrint("ERROR en WidgetsFlutterBinding: $e");
  }

  // 1. Cargar variables de entorno
  try {
    await dotenv.load(fileName: '.env');
    debugPrint("[2/4] Variables de entorno (.env) cargadas.");
  } catch (e) {
    debugPrint('[Startup] No se pudo cargar .env: $e');
  }

  // 2. Inicializar Firebase
  var firebaseReady = false;
  try {
    debugPrint("Inicializando Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    firebaseReady = true;
    debugPrint("[3/4] Firebase inicializado con éxito.");
  } catch (e) {
    debugPrint('[Startup] Firebase no inició: $e');
  }

  // 3. Inicializar Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint("ERROR: SUPABASE_URL o SUPABASE_ANON_KEY vacíos en .env");
    runApp(const StartupErrorApp());
    return;
  }

  try {
    debugPrint("Inicializando Supabase...");
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    ).timeout(const Duration(seconds: 8));
    debugPrint("[4/4] Supabase inicializado con éxito.");
  } catch (e) {
    debugPrint('[Startup] Supabase no inició: $e');
    runApp(const StartupErrorApp());
    return;
  }

  debugPrint("=== INICIALIZACIÓN COMPLETA - Lanzando MaterialApp ===");
  runApp(const ProviderScope(child: MyApp()));

  unawaited(WearLinkService.instance.startPhoneCompanion());

  if (firebaseReady) {
    unawaited(_initializeNotifications());
  }
}

Future<void> _initializeNotifications() async {
  try {
    await FcmService.instance.initialize().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Startup] FCM se omitió para no bloquear la app: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DentalSync Connect',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo iniciar DentalSync. Revisa la configuración de Supabase en el archivo .env.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
