import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/core/models/clinical_attachment.dart';

final clinicalAttachmentRepositoryProvider =
    Provider<ClinicalAttachmentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClinicalAttachmentRepository(client);
});

final patientAttachmentsProvider =
    FutureProvider.family<List<ClinicalAttachment>, String>((ref, patientId) async {
  final repo = ref.watch(clinicalAttachmentRepositoryProvider);
  return repo.getAttachmentsForPatient(patientId);
});

class ClinicalAttachmentRepository {
  final SupabaseClient _client;
  static const String _bucketName = 'clinical-files';

  ClinicalAttachmentRepository(this._client);

  /// Obtiene la lista de estudios y radiografías adjuntas de un paciente.
  Future<List<ClinicalAttachment>> getAttachmentsForPatient(String patientId) async {
    try {
      final response = await _client
          .from('clinical_attachments')
          .select('*')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((map) => ClinicalAttachment.fromJson(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener adjuntos clínicos: $e');
      return [];
    }
  }

  /// Sube un archivo a Supabase Storage y registra los metadatos en la base de datos.
  Future<ClinicalAttachment?> uploadAttachment({
    required String patientId,
    required String fileName,
    required Uint8List bytes,
    String? notes,
    String? appointmentId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      final fileExt = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
      final fileType = (fileExt == 'pdf') ? 'pdf' : 'image';
      final storagePath = 'patient_$patientId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // 1. Subir al Bucket de Storage
      await _client.storage.from(_bucketName).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: fileType == 'pdf' ? 'application/pdf' : 'image/$fileExt',
              upsert: true,
            ),
          );

      // 2. Obtener URL pública
      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(storagePath);

      // 3. Guardar registro en la tabla clinical_attachments
      final insertData = {
        'patient_id': patientId,
        'appointment_id': appointmentId,
        'uploaded_by': user?.id,
        'file_name': fileName,
        'file_path': publicUrl,
        'file_type': fileType,
        'notes': notes,
      };

      final response = await _client
          .from('clinical_attachments')
          .insert(insertData)
          .select('*')
          .single();

      return ClinicalAttachment.fromJson(response);
    } catch (e) {
      debugPrint('Error al subir adjunto clínico: $e');
      return null;
    }
  }

  /// Elimina un adjunto de la BD y de Storage.
  Future<bool> deleteAttachment(String attachmentId, String fileUrl) async {
    try {
      await _client.from('clinical_attachments').delete().eq('id', attachmentId);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar adjunto clínico: $e');
      return false;
    }
  }
}
