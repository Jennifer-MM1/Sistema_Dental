
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sistema_dental/features/wear/presentation/wear_app.dart';

/// Punto de entrada exclusivo para dispositivos y emuladores Wear OS (Smartwatch).
/// Se ejecuta con: `flutter run -d <emulator_id> --target=lib/main_wear.dart`
void main() async {
  debugPrint("=== INICIANDO DENTALSYNC WEAR OS APP ===");
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('es_MX', null);
    debugPrint("[1/3] Binding e intl inicializados.");
  } catch (e) {
    debugPrint("Error en binding inicial: $e");
  }

  // 1. Cargar variables de entorno
  try {
    await dotenv.load(fileName: '.env');
    debugPrint("[2/3] Variables de entorno (.env) cargadas.");
  } catch (e) {
    debugPrint('[Startup Wear] No se pudo cargar .env: $e');
  }

  // 2. Inicializar Supabase para sincronización Realtime
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      ).timeout(const Duration(seconds: 8));
      debugPrint("[3/3] Supabase inicializado para el reloj.");
    } catch (e) {
      debugPrint('[Startup Wear] Error al iniciar Supabase: $e');
    }
  }

  runApp(const WearDentalSyncApp());
}
