import 'package:sistema_dental/core/models/user_role.dart';

/// Modelo que representa al usuario autenticado con su perfil completo
/// obtenido de la tabla `profiles` en Supabase.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  /// Crea un [AppUser] desde un Map devuelto por Supabase.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: UserRole.fromString(map['role'] as String? ?? 'patient'),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convierte el [AppUser] a un Map para enviar a Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role.toDbString(),
      'is_active': isActive,
    };
  }

  /// Crea una copia del usuario con campos actualizados.
  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
