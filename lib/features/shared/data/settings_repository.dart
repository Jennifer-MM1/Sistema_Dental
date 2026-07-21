import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SettingsRepository(client);
});

class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository(this._client);

  Future<bool> updateCurrentProfile({
    required String name,
    required String phone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('profiles')
          .update({'name': name.trim(), 'phone': phone.trim()})
          .eq('id', user.id);
      await _client.auth.updateUser(
        UserAttributes(data: {'name': name.trim()}),
      );
      return true;
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      return false;
    }
  }

  Future<bool> changePassword(String password) async {
    if (password.trim().length < 6) return false;

    try {
      await _client.auth.updateUser(UserAttributes(password: password.trim()));
      return true;
    } catch (e) {
      debugPrint('Error cambiando contraseña: $e');
      return false;
    }
  }
}
