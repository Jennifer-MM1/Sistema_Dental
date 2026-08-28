import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicalAttachment {
  final String id;
  final String patientId;
  final String? appointmentId;
  final String? uploadedBy;
  final String fileName;
  final String filePath;
  final String fileType; // 'image' | 'pdf'
  final String? notes;
  final DateTime createdAt;

  ClinicalAttachment({
    required this.id,
    required this.patientId,
    this.appointmentId,
    this.uploadedBy,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    this.notes,
    required this.createdAt,
  });

  factory ClinicalAttachment.fromJson(Map<String, dynamic> json) {
    return ClinicalAttachment(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      fileName: json['file_name'] as String? ?? 'Archivo sin nombre',
      filePath: json['file_path'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'image',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fileUrl {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    return Supabase.instance.client.storage
        .from('clinical-files')
        .getPublicUrl(filePath);
  }
}
