import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_dental/core/models/clinical_attachment.dart';

void main() {
  group('ClinicalAttachment Model Tests', () {
    test('Debe serializar y deserializar correctamente un objeto ClinicalAttachment', () {
      final now = DateTime.now();
      final attachment = ClinicalAttachment(
        id: 'att-123',
        patientId: 'pat-456',
        appointmentId: 'app-789',
        uploadedBy: 'doc-001',
        fileName: 'radiografia_panoramica.png',
        filePath: 'https://example.com/files/radiografia_panoramica.png',
        fileType: 'image',
        notes: 'Caries visible en molar 18',
        createdAt: now,
      );

      final json = attachment.toJson();
      expect(json['id'], equals('att-123'));
      expect(json['patient_id'], equals('pat-456'));
      expect(json['file_name'], equals('radiografia_panoramica.png'));
      expect(json['file_type'], equals('image'));

      final fromJson = ClinicalAttachment.fromJson(json);
      expect(fromJson.id, equals(attachment.id));
      expect(fromJson.patientId, equals(attachment.patientId));
      expect(fromJson.fileName, equals(attachment.fileName));
      expect(fromJson.fileType, equals(attachment.fileType));
      expect(fromJson.notes, equals(attachment.notes));
    });
  });
}
