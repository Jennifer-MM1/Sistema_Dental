import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/models/app_user.dart';
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
  final AppUser? user;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    AppUser? user,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
    state = state.copyWith(isLoading: true, errorMessage: null);

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
          errorMessage: 'Tu cuenta ha sido desactivada. Contacta al administrador.',
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
        errorMessage: 'Error de conexión. Intenta de nuevo.',
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

  /// Vincula al paciente con una clínica usando el código de invitación.
  Future<bool> linkWithCode(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final repo = ref.read(authRepositoryProvider);
    final role = await repo.linkClinicWithCode(code);
    final success = role != null;

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
    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Debes confirmar tu correo electrónico primero.';
    }
    return 'Error de autenticación: $message';
  }
}

/// Proveedor del LoginNotifier.
final loginProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);
