import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/theme/app_theme.dart';
import 'package:sistema_dental/core/router/app_router.dart';
import 'package:sistema_dental/core/notifications/fcm_service.dart';
// ignore: uri_does_not_exist
import 'firebase_options.dart'; // Generado por FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[Startup] No se pudo cargar .env: $e');
  }

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    firebaseReady = true;
  } catch (e) {
    debugPrint('[Startup] Firebase no inició: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const StartupErrorApp());
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    ).timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('[Startup] Supabase no inició: $e');
    runApp(const StartupErrorApp());
    return;
  }

  runApp(const ProviderScope(child: MyApp()));

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
