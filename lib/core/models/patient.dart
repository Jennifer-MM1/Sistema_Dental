

/// Modelo que representa una ficha de paciente (multi-paciente por cuenta).
class Patient {
  final String id;
  final String profileId; // Refers to profiles(id)
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String relationship; // 'self', 'child', 'spouse', 'parent', 'other'
  final DateTime createdAt;

  const Patient({
    required this.id,
    required this.profileId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.relationship = 'self',
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      relationship: map['relationship'] as String? ?? 'self',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'relationship': relationship,
    };
  }

  Patient copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? relationship,
  }) {
    return Patient(
      id: id,
      profileId: profileId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt,
    );
  }
}
