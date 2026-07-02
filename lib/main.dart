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

  // 1. Cargar variables de entorno
  await dotenv.load(fileName: '.env');

  // 2. Inicializar Firebase (requiere firebase_options.dart generado por FlutterFire CLI)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 4. Inicializar servicio de notificaciones push
  // Solo se activa en Android/iOS/macOS; en Windows/Web se omite silenciosamente
  await FcmService.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
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
