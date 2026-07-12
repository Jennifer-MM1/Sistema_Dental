import 'dart:convert';

/// Modelo que representa una receta digital asociada a una nota clínica.
class Prescription {
  final String? id;
  final String clinicalNoteId;
  final String patientId;
  final String doctorId;
  final String clinicId;
  final List<PrescriptionItem> medications;
  final String? instructions;
  final DateTime? createdAt;

  /// Campos de join (solo lectura)
  final String? doctorName;
  final String? patientName;
  final String? clinicName;

  const Prescription({
    this.id,
    required this.clinicalNoteId,
    required this.patientId,
    required this.doctorId,
    required this.clinicId,
    this.medications = const [],
    this.instructions,
    this.createdAt,
    this.doctorName,
    this.patientName,
    this.clinicName,
  });

  factory Prescription.fromMap(Map<String, dynamic> map) {
    // Parsear medicamentos desde JSONB
    List<PrescriptionItem> meds = [];
    if (map['medications'] != null) {
      final medsData = map['medications'] is String
          ? jsonDecode(map['medications'] as String)
          : map['medications'];
      meds = (medsData as List<dynamic>)
          .map((e) => PrescriptionItem.fromMap(e as Map<String, dynamic>))
          .toList();
    }

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

    String? clinName;
    if (map['clinic'] != null) {
      clinName = map['clinic']['business_name'];
    }

    return Prescription(
      id: map['id'] as String?,
      clinicalNoteId: map['clinical_note_id'] as String,
      patientId: map['patient_id'] as String,
      doctorId: map['doctor_id'] as String,
      clinicId: map['clinic_id'] as String,
      medications: meds,
      instructions: map['instructions'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      doctorName: docName,
      patientName: patName,
      clinicName: clinName,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'clinical_note_id': clinicalNoteId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'clinic_id': clinicId,
      'medications': medications.map((m) => m.toMap()).toList(),
      'instructions': instructions,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}

/// Representa un medicamento individual dentro de una receta.
class PrescriptionItem {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;

  const PrescriptionItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
  });

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
    };
  }
}
