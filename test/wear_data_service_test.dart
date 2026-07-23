import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';

void main() {
  group('WearStartupData', () {
    test('mantiene a la secretaria como un rol independiente', () {
      final data = WearStartupData.fromJson({
        'role': 'secretary',
        'is_linked': true,
        'secretary_queue': {
          'appointment_id': 'appointment-1',
          'patient_name': 'Paciente Uno',
          'queue_code': 'A-01',
          'queue_count': 3,
          'estimated_minutes': 15,
          'status_label': 'En sala',
          'status': 'in_lobby',
          'doctor_name': 'Dra. Dental',
        },
      });

      expect(data.role, WearRole.secretary);
      expect(data.secretary?.appointmentId, 'appointment-1');
      expect(data.secretary?.status, 'in_lobby');
      expect(data.doctor, isNull);
    });

    test('carga la cola exclusiva del dentista', () {
      final data = WearStartupData.fromJson({
        'role': 'dentist',
        'is_linked': true,
        'doctor_queue': {
          'appointment_id': 'appointment-2',
          'patient_name': 'Paciente Dos',
          'queue_count': 1,
          'status': 'in_treatment',
        },
      });

      expect(data.role, WearRole.dentist);
      expect(data.doctor?.appointmentId, 'appointment-2');
      expect(data.doctor?.status, 'in_treatment');
      expect(data.secretary, isNull);
    });

    test('el cliente conserva varios pacientes asociados', () {
      final data = WearStartupData.fromJson({
        'role': 'patient',
        'is_linked': true,
        'summary': {
          'user_name': 'Cliente',
          'patient_names': ['Paciente Uno', 'Paciente Dos'],
          'appointment_count': 2,
        },
      });

      expect(data.role, WearRole.patient);
      expect(data.summary?.patientNames, hasLength(2));
      expect(data.summary?.appointmentCount, 2);
    });
  });
}
