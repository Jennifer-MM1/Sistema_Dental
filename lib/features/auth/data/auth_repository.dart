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

  /// Vincula un usuario a una clínica usando un código de invitación.
  /// Asigna al usuario el rol elegido en la clínica.
  Future<String?> linkClinicWithCode(String code, String role) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // Buscar el código de invitación no usado
      final codeData = await _client
          .from('invitation_codes')
          .select()
          .eq('code', code)
          .eq('is_used', false)
          .single();

      // Marcar el código como usado
      await _client
          .from('invitation_codes')
          .update({
            'is_used': true,
            'used_by': user.id,
          })
          .eq('id', codeData['id']);

      // Crear la membresía clínica para el usuario usando su rol
      await _client.from('clinic_memberships').insert({
        'clinic_id': codeData['clinic_id'],
        'user_id': user.id,
        'role_in_clinic': role,
        'is_active': true,
      });

      // Si el usuario ya tenía fichas creadas antes de vincularse,
      // asignarlas a la clínica para que no se mezclen con otras clínicas.
      if (role == 'client') {
        await _client
            .from('patients')
            .update({'clinic_id': codeData['clinic_id']})
            .eq('profile_id', user.id)
            .filter('clinic_id', 'is', null);
      }

      return role;
    } catch (e) {
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
  Future<String?> generateInvitationCode(String clinicId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // Generar un código alfanumérico único
      final code = _generateAlphanumericCode();

      await _client.from('invitation_codes').insert({
        'clinic_id': clinicId,
        'code': code,
        'created_by': user.id,
        'is_used': false,
      });

      return code;
    } catch (e) {
      return null;
    }
  }

  /// Genera un código alfanumérico de 8 caracteres.
  String _generateAlphanumericCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }
}
