/// Modelo que representa un código de invitación generado
/// por el dentista/secretaria para vincular un paciente a una clínica (RF-03).
class InvitationCode {
  final String id;
  final String clinicId;
  final String code;
  final String createdBy;
  final String? usedBy;
  final bool isUsed;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const InvitationCode({
    required this.id,
    required this.clinicId,
    required this.code,
    required this.createdBy,
    this.usedBy,
    this.isUsed = false,
    this.expiresAt,
    required this.createdAt,
  });

  /// Crea un [InvitationCode] desde un Map devuelto por Supabase.
  factory InvitationCode.fromMap(Map<String, dynamic> map) {
    return InvitationCode(
      id: map['id'] as String,
      clinicId: map['clinic_id'] as String,
      code: map['code'] as String,
      createdBy: map['created_by'] as String,
      usedBy: map['used_by'] as String?,
      isUsed: map['is_used'] as bool? ?? false,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convierte el [InvitationCode] a un Map para enviar a Supabase.
  Map<String, dynamic> toMap() {
    return {
      'clinic_id': clinicId,
      'code': code,
      'created_by': createdBy,
      'used_by': usedBy,
      'is_used': isUsed,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
