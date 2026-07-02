import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/models/user_role.dart';
import 'package:sistema_dental/features/auth/presentation/register_screen.dart';
import 'package:sistema_dental/features/auth/presentation/role_selection_screen.dart';
import 'package:sistema_dental/features/auth/presentation/login_screen.dart';
import 'package:sistema_dental/features/client/presentation/client_dashboard.dart';
import 'package:sistema_dental/features/dentist/presentation/dentist_dashboard.dart';
import 'package:sistema_dental/features/secretary/presentation/secretary_dashboard.dart';

import 'package:sistema_dental/features/auth/presentation/link_clinic_screen.dart';

/// Proveedor del router con protección de rutas basada en roles.
/// Usa Riverpod para acceder al estado de autenticación.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      final isOnLoginPage = state.uri.path == '/login' || state.uri.path == '/register';

      // Si no hay usuario autenticado y NO está en login/registro → redirigir a login
      if (user == null) {
        return isOnLoginPage ? null : '/login';
      }

      // Si hay usuario autenticado y ESTÁ en login/registro → redirigir al hub de modos
      if (isOnLoginPage) {
        return '/mode_selector';
      }

      // Las rutas internas manejan su propia autorización ahora a través de los datos de membresía de clínica
      return null;

    },
    routes: [
      
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/mode_selector',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/link-clinic',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'patient';
          return LinkClinicScreen(role: role);
        },
      ),
GoRoute(
        path: '/client',
        builder: (context, state) => const ClientDashboard(),
      ),

      GoRoute(
        path: '/dentist',
        builder: (context, state) => const DentistDashboard(),
      ),
      GoRoute(
        path: '/secretary',
        builder: (context, state) => const SecretaryDashboard(),
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

