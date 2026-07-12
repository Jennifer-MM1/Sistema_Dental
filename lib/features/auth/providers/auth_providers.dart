import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/models/app_user.dart';
import 'package:sistema_dental/core/models/user_role.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/features/auth/data/auth_repository.dart';

/// Proveedor del repositorio de autenticación.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

/// Proveedor del estado de autenticación de Supabase.
/// Emite eventos cada vez que el usuario inicia o cierra sesión.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.onAuthStateChange();
});

/// Proveedor del perfil del usuario autenticado actual.
/// Retorna null si no hay sesión activa.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  // Escuchar cambios de autenticación para re-evaluar
  ref.watch(authStateProvider);
  final repo = ref.read(authRepositoryProvider);
  return await repo.getCurrentUserProfile();
});

/// Estado del proceso de login.
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final AppUser? user;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.user,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    AppUser? user,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      user: user ?? this.user,
    );
  }
}

/// Notifier para manejar el estado del proceso de login.
class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// Ejecuta el login con email y contraseña.
  Future<AppUser?> login(String email, String password) async {
    state = const LoginState(isLoading: true);

    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.signInWithEmail(email: email, password: password);
      final user = await repo.getCurrentUserProfile();

      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se encontró el perfil del usuario.',
        );
        return null;
      }

      if (!user.isActive) {
        await repo.signOut();
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Tu cuenta ha sido desactivada. Contacta al administrador.',
        );
        return null;
      }

      state = state.copyWith(isLoading: false, user: user);
      return user;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateAuthError(e.message),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateConnectionError(e),
      );
      return null;
    }
  }

  /// Registra un nuevo usuario con email, contraseña y nombre.
  Future<AppUser?> register(String name, String email, String password) async {
    state = const LoginState(isLoading: true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo crear la cuenta.',
        );
        return null;
      }

      // Si el registro fue exitoso pero no hay sesión, significa que se requiere confirmación por correo
      if (response.session == null) {
        state = state.copyWith(
          isLoading: false,
          successMessage:
              'Cuenta creada exitosamente. Por favor revisa tu correo electrónico para verificar tu cuenta antes de iniciar sesión.',
        );
        return null; // Retornamos null para que no intente redirigir al hub todavía
      }

      final appUser = AppUser(
        id: user.id,
        email: user.email ?? '',
        name: name,
        createdAt: DateTime.now(),
        role: UserRole.client, // Will be overridden dynamically by the Hub
      );

      state = state.copyWith(isLoading: false, user: appUser);
      return appUser;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateAuthError(e.message),
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateConnectionError(e),
      );
      return null;
    }
  }

  /// Cierra la sesión del usuario.
  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const LoginState();
  }

  /// Vincula al usuario con una clínica usando el código de invitación y un rol específico.
  Future<bool> linkWithCode(String code, String role) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final repo = ref.read(authRepositoryProvider);
    final roleResult = await repo.linkClinicWithCode(code, role);
    final success = roleResult != null;

    if (!success) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Código inválido o ya utilizado.',
      );
    } else {
      state = state.copyWith(isLoading: false);
    }

    return success;
  }

  String _translateAuthError(String message) {
    final normalized = message.toLowerCase();
    if (_isConnectionError(normalized)) {
      return 'No tienes conexión a internet. Revisa tu Wi-Fi o datos móviles e intenta de nuevo.';
    }
    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Debes confirmar tu correo electrónico primero.';
    }
    return 'Error de autenticación: $message';
  }

  String _translateConnectionError(Object error) {
    final message = error.toString().toLowerCase();
    if (_isConnectionError(message)) {
      return 'No tienes conexión a internet. Revisa tu Wi-Fi o datos móviles e intenta de nuevo.';
    }
    return 'No pudimos conectar con el servidor. Intenta de nuevo en unos segundos.';
  }

  bool _isConnectionError(String message) {
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('no address associated with hostname') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('connection timed out') ||
        message.contains('timed out') ||
        message.contains('clientexception');
  }
}

/// Proveedor del LoginNotifier.
final loginProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
