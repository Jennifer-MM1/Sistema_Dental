import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/models/user_role.dart';
import 'package:sistema_dental/features/auth/presentation/login_screen.dart';
import 'package:sistema_dental/features/client/presentation/client_dashboard.dart';
import 'package:sistema_dental/features/dentist/presentation/dentist_dashboard.dart';
import 'package:sistema_dental/features/secretary/presentation/secretary_dashboard.dart';
import 'package:sistema_dental/features/super_admin/presentation/super_admin_dashboard.dart';
import 'package:sistema_dental/features/auth/presentation/link_clinic_screen.dart';

/// Proveedor del router con protección de rutas basada en roles.
/// Usa Riverpod para acceder al estado de autenticación.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final isOnLoginPage = state.matchedLocation == '/login';

      // Si no hay usuario autenticado y NO está en login → redirigir a login
      if (user == null) {
        return isOnLoginPage ? null : '/login';
      }

      // Si hay usuario autenticado y ESTÁ en login → redirigir a su panel
      if (isOnLoginPage) {
        try {
          final profile = await supabase
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .single();

          final role = UserRole.fromString(profile['role'] as String? ?? 'client');
          return role.initialRoute;
        } catch (e) {
          // Si hay error obteniendo el perfil, quedarse en login
          return null;
        }
      }

      // Verificar acceso por rol a la ruta actual
      try {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        final role = UserRole.fromString(profile['role'] as String? ?? 'client');
        final currentPath = state.matchedLocation;

        // Si el rol no tiene acceso a esta ruta → redirigir a su panel
        if (!role.canAccessRoute(currentPath)) {
          return role.initialRoute;
        }
      } catch (e) {
        return '/login';
      }

      return null; // Sin redirección
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/client',
        builder: (context, state) => const ClientDashboard(),
      ),
      GoRoute(
        path: '/link-clinic',
        builder: (context, state) => const LinkClinicScreen(),
      ),
      GoRoute(
        path: '/dentist',
        builder: (context, state) => const DentistDashboard(),
      ),
      GoRoute(
        path: '/secretary',
        builder: (context, state) => const SecretaryDashboard(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Mantener compatibilidad: variable global que usa el provider
// Se actualizará en main.dart para usar el provider directamente
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final isOnLoginPage = state.matchedLocation == '/login';

    if (user == null) {
      return isOnLoginPage ? null : '/login';
    }

    if (isOnLoginPage) {
      try {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        final role = UserRole.fromString(profile['role'] as String? ?? 'client');
        return role.initialRoute;
      } catch (e) {
        return null;
      }
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = UserRole.fromString(profile['role'] as String? ?? 'client');
      final currentPath = state.matchedLocation;

      if (!role.canAccessRoute(currentPath)) {
        return role.initialRoute;
      }
    } catch (e) {
      return '/login';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/client',
      builder: (context, state) => const ClientDashboard(),
    ),
    GoRoute(
      path: '/link-clinic',
      builder: (context, state) => const LinkClinicScreen(),
    ),
    GoRoute(
      path: '/dentist',
      builder: (context, state) => const DentistDashboard(),
    ),
    GoRoute(
      path: '/secretary',
      builder: (context, state) => const SecretaryDashboard(),
    ),
    GoRoute(
      path: '/super-admin',
      builder: (context, state) => const SuperAdminDashboard(),
    ),
  ],
);
