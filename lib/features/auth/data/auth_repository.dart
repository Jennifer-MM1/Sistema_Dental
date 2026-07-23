import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/models/app_user.dart';

/// Repositorio que encapsula las operaciones de autenticación
/// y gestión de perfiles contra Supabase Auth + tabla profiles.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Inicia sesión con email y contraseña.
  /// Retorna el [AuthResponse] de Supabase.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Registra un usuario nuevo.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': 'client', // Siempre inicia como client por defecto, luego elige
      },
    );
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Obtiene el perfil completo del usuario autenticado desde la tabla `profiles`.
  /// Retorna `null` si no hay usuario autenticado o si no se encuentra el perfil.
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return AppUser.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Stream que escucha cambios en el estado de autenticación de Supabase.
  Stream<AuthState> onAuthStateChange() {
    return _client.auth.onAuthStateChange;
  }

  /// Obtiene el usuario actual de Supabase Auth (sin perfil).
  User? get currentAuthUser => _client.auth.currentUser;

  /// Verifica si hay una sesión activa.
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Vincula un usuario usando el rol firmado por la invitación.
  Future<String?> linkClinicWithCode(String code) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final result = await _client.rpc(
        'redeem_role_invitation',
        params: {'p_code': code.trim()},
      );
      return (result as Map<String, dynamic>)['role'] as String?;
    } catch (e) {
      debugPrint('Error redeeming invitation: $e');
      return null;
    }
  }

  /// Elimina un código de invitación (usado para códigos efímeros).
  Future<void> deleteInvitationCode(String code) async {
    try {
      await _client.from('invitation_codes').delete().eq('code', code);
    } catch (e) {
      // Ignorar error si no existe
    }
  }

  /// Genera un código de invitación alfanumérico para un paciente.
  /// Solo disponible para dentistas, secretarias y super admins.
  Future<String?> generateInvitationCode(
    String clinicId, {
    String targetRole = 'client',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final result = await _client.rpc(
        'create_role_invitation',
        params: {'p_clinic_id': clinicId, 'p_target_role': targetRole},
      );
      return (result as Map<String, dynamic>)['code'] as String?;
    } catch (e) {
      return null;
    }
  }
}
