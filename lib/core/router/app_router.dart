import 'package:go_router/go_router.dart';
import 'package:sistema_dental/features/auth/presentation/login_screen.dart';
import 'package:sistema_dental/features/patient/presentation/patient_dashboard.dart';
import 'package:sistema_dental/features/dentist/presentation/dentist_dashboard.dart';
import 'package:sistema_dental/features/secretary/presentation/secretary_dashboard.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/patient',
      builder: (context, state) => const PatientDashboard(),
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
);
