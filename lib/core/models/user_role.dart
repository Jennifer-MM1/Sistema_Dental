/// Enum que define los 4 roles del sistema DentalSync Connect.
/// Cada rol determina a qué panel(es) tiene acceso el usuario.
enum UserRole {
  superAdmin,     // Acceso a panel dentista + secretaria
  adminDentist,   // Acceso a panel dentista (tablet)
  adminSecretary, // Acceso a panel secretaria (escritorio)
  patient;        // Acceso a panel paciente (móvil + smartwatch)

  /// Convierte la cadena almacenada en Supabase al enum correspondiente.
  static UserRole fromString(String role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin_dentist':
        return UserRole.adminDentist;
      case 'admin_secretary':
        return UserRole.adminSecretary;
      case 'patient':
        return UserRole.patient;
      default:
        return UserRole.patient;
    }
  }

  /// Convierte el enum a la cadena almacenada en Supabase.
  String toDbString() {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.adminDentist:
        return 'admin_dentist';
      case UserRole.adminSecretary:
        return 'admin_secretary';
      case UserRole.patient:
        return 'patient';
    }
  }

  /// Ruta inicial de GoRouter según el rol del usuario autenticado.
  String get initialRoute {
    switch (this) {
      case UserRole.superAdmin:
        return '/super-admin';
      case UserRole.adminDentist:
        return '/dentist';
      case UserRole.adminSecretary:
        return '/secretary';
      case UserRole.patient:
        return '/patient';
    }
  }

  /// Nombre legible para mostrar en la UI.
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrador';
      case UserRole.adminDentist:
        return 'Dentista';
      case UserRole.adminSecretary:
        return 'Secretaria';
      case UserRole.patient:
        return 'Paciente';
    }
  }

  /// Verifica si el rol tiene acceso a una ruta específica.
  bool canAccessRoute(String route) {
    switch (this) {
      case UserRole.superAdmin:
        return true; // Acceso total
      case UserRole.adminDentist:
        return route.startsWith('/dentist');
      case UserRole.adminSecretary:
        return route.startsWith('/secretary');
      case UserRole.patient:
        return route.startsWith('/patient');
    }
  }
}
