import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/models/appointment.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/features/client/data/patient_repository.dart';

final clientAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final selectedPatient = ref.watch(selectedPatientProvider);
  if (selectedPatient == null) return [];
  
  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.getAppointmentsForPatient(selectedPatient.id);
});

final clinicQueueProvider = StreamProvider<List<Appointment>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) yield [];

  final membership = await supabase
      .from('clinic_memberships')
      .select('clinic_id')
      .eq('user_id', user!.id)
      .limit(1)
      .single();

  final clinicId = membership['clinic_id'] as String;
  
  final repo = ref.watch(appointmentRepositoryProvider);
  yield* repo.getTodayQueueForClinic(clinicId);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AppointmentRepository(supabase);
});

class AppointmentRepository {
  final dynamic _supabase; // Type is SupabaseClient but using dynamic to avoid explicit typing issues if not imported

  AppointmentRepository(this._supabase);

  /// Obtiene las citas de un paciente específico (para el panel de Cliente)
  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            doctor:doctors(user:profiles(name)),
            service:services(service_name, duration_mins)
          ''')
          .eq('patient_id', patientId)
          .order('date_time', ascending: false);

      return (response as List).map((map) => Appointment.fromMap(map)).toList();
    } catch (e) {
      print('Error al obtener citas del paciente: $e');
      return [];
    }
  }

  /// Obtiene la fila de espera de hoy para una clínica en tiempo real (Stream) (Para el panel de Dentista)
  Stream<List<Appointment>> getTodayQueueForClinic(String clinicId) {
    // Para simplificar la demo, traemos todas las citas de la clinica que estén en estado activo (no cancelado/completado)
    // idealmente se filtraría por date_time = hoy.
    return _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('clinic_id', clinicId)
        .order('date_time', ascending: true)
        .map<List<Appointment>>((List<Map<String, dynamic>> list) => list
            .map((map) => Appointment.fromMap(map))
            .where((app) => app.status != 'completed' && app.status != 'cancelled')
            .toList());
  }

  /// Actualiza el estado de una cita y dispara la notificación push al paciente.
  /// Estados válidos: 'upcoming' | 'in_lobby' | 'in_treatment' | 'completed' | 'cancelled'
  Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', appointmentId);

      // Disparar notificación push al paciente de forma asíncrona (fire-and-forget).
      // Si la Edge Function falla, no afecta el flujo principal.
      _invokeNotification(appointmentId, newStatus);

      return true;
    } catch (e) {
      debugPrint('Error al actualizar estado de cita: $e');
      return false;
    }
  }

  /// Llama a la Supabase Edge Function `notify-patient-turn` que envía la push
  /// notification al dispositivo del paciente vía FCM.
  Future<void> _invokeNotification(String appointmentId, String newStatus) async {
    // Solo notificar en estados relevantes para el paciente
    const notifiableStatuses = {'in_lobby', 'in_treatment', 'completed'};
    if (!notifiableStatuses.contains(newStatus)) return;

    try {
      await _supabase.functions.invoke(
        'notify-patient-turn',
        body: {
          'appointmentId': appointmentId,
          'newStatus': newStatus,
        },
      );
      debugPrint('[Notify] Edge Function invocada para cita $appointmentId → $newStatus');
    } catch (e) {
      // Error silencioso: la notificación es opcional, no crítica
      debugPrint('[Notify] Error al invocar Edge Function: $e');
    }
  }
}
