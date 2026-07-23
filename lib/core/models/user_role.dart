/// Enum que define los 4 roles del sistema DentalSync Connect.
/// Cada rol determina a qué panel(es) tiene acceso el usuario.
enum UserRole {
  dentist, // Acceso a panel dentista (ahora actúa como admin/owner)
  secretary, // Acceso a panel secretaria
  client; // Acceso a panel cliente

  /// Convierte la cadena almacenada en Supabase al enum correspondiente.
  static UserRole fromString(String role) {
    switch (role) {
      case 'dentist':
      case 'super_admin': // Compatibilidad hacia atrás si hay roles viejos
      case 'admin_dentist':
        return UserRole.dentist;
      case 'secretary':
      case 'admin_secretary':
        return UserRole.secretary;
      case 'client':
        return UserRole.client;
      default:
        return UserRole.client;
    }
  }

  /// Convierte el enum a la cadena almacenada en Supabase.
  String toDbString() {
    switch (this) {
      case UserRole.dentist:
        return 'dentist';
      case UserRole.secretary:
        return 'secretary';
      case UserRole.client:
        return 'client';
    }
  }

  /// Ruta inicial de GoRouter según el rol del usuario autenticado.
  String get initialRoute {
    switch (this) {
      case UserRole.dentist:
        return '/dentist';
      case UserRole.secretary:
        return '/secretary';
      case UserRole.client:
        return '/client';
    }
  }

  /// Nombre legible para mostrar en la UI.
  String get displayName {
    switch (this) {
      case UserRole.dentist:
        return 'Dentista';
      case UserRole.secretary:
        return 'Secretaria';
      case UserRole.client:
        return 'Cliente';
    }
  }

  /// Verifica si el rol tiene acceso a una ruta específica.
  bool canAccessRoute(String route) {
    switch (this) {
      case UserRole.dentist:
        return true; // El dentista es super admin ahora
      case UserRole.secretary:
        return route.startsWith('/secretary');
      case UserRole.client:
        return route.startsWith('/client') || route.startsWith('/link-clinic');
    }
  }
}
