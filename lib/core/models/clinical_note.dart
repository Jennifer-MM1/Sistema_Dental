/// Modelo que representa una nota clínica asociada a una cita.
/// Almacena el diagnóstico, tratamiento realizado, observaciones
/// y los números de dientes involucrados (nomenclatura FDI).
class ClinicalNote {
  final String? id;
  final String? appointmentId;
  final String patientId;
  final String doctorId;
  final String clinicId;
  final String? diagnosis;
  final String? treatmentPerformed;
  final String? observations;
  final List<int> toothNumbers;
  final DateTime? createdAt;

  /// Campos de join (solo lectura)
  final String? doctorName;
  final String? patientName;

  const ClinicalNote({
    this.id,
    this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.clinicId,
    this.diagnosis,
    this.treatmentPerformed,
    this.observations,
    this.toothNumbers = const [],
    this.createdAt,
    this.doctorName,
    this.patientName,
  });

  factory ClinicalNote.fromMap(Map<String, dynamic> map) {
    // Extraer nombres de joins si existen
    String? docName;
    if (map['doctor'] != null && map['doctor']['user'] != null) {
      docName = map['doctor']['user']['name'];
    }

    String? patName;
    if (map['patient'] != null) {
      patName =
          '${map['patient']['first_name']} ${map['patient']['last_name']}';
    }

    return ClinicalNote(
      id: map['id'] as String?,
      appointmentId: map['appointment_id'] as String?,
      patientId: map['patient_id'] as String,
      doctorId: map['doctor_id'] as String,
      clinicId: map['clinic_id'] as String,
      diagnosis: map['diagnosis'] as String?,
      treatmentPerformed: map['treatment_performed'] as String?,
      observations: map['observations'] as String?,
      toothNumbers: (map['tooth_numbers'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      doctorName: docName,
      patientName: patName,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'patient_id': patientId,
      'doctor_id': doctorId,
      'clinic_id': clinicId,
      'diagnosis': diagnosis,
      'treatment_performed': treatmentPerformed,
      'observations': observations,
      'tooth_numbers': toothNumbers,
    };
    if (appointmentId != null) map['appointment_id'] = appointmentId;
    if (id != null) map['id'] = id;
    return map;
  }

  ClinicalNote copyWith({
    String? diagnosis,
    String? treatmentPerformed,
    String? observations,
    List<int>? toothNumbers,
  }) {
    return ClinicalNote(
      id: id,
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      clinicId: clinicId,
      diagnosis: diagnosis ?? this.diagnosis,
      treatmentPerformed: treatmentPerformed ?? this.treatmentPerformed,
      observations: observations ?? this.observations,
      toothNumbers: toothNumbers ?? this.toothNumbers,
      createdAt: createdAt,
      doctorName: doctorName,
      patientName: patientName,
    );
  }
}
