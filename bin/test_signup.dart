import 'package:supabase/supabase.dart';
import 'dart:io';

Future<void> main() async {
  final supabase = SupabaseClient(
    'https://yeolgeheuycvgprycvls.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inllb2xnZWhldXljdmdwcnljdmxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0MTI3MTAsImV4cCI6MjA5Nzk4ODcxMH0.xycDWYIqOlMVxYZuXEh-UWQ4bWc3JCIZi0gtbnJO48w',
  );

  print('Intentando registrar usuario...');
  try {
    final res = await supabase.auth.signUp(
      email: 'test_register_user_99@test.com',
      password: 'password123',
      data: {
        'name': 'Test User 99',
        'role': 'client',
      },
    );
    print('Exito! User: ${res.user?.id}');
  } on AuthException catch (e) {
    print('AuthException: ${e.message}');
  } catch (e, stack) {
    print('Exception: $e');
    print(stack);
  }
  exit(0);
}
