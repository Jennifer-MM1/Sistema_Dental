import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_dental/core/models/appointment.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/features/client/data/patient_repository.dart';

final clientAppointmentsProvider = FutureProvider<List<Appointment>>((
  ref,
) async {
  final selectedPatient = ref.watch(selectedPatientProvider);
  if (selectedPatient == null) return [];

  final repo = ref.watch(appointmentRepositoryProvider);
  return repo.getAppointmentsForPatient(selectedPatient.id);
});

final clinicQueueProvider = StreamProvider<List<Appointment>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  final membership = await supabase
      .from('clinic_memberships')
      .select('clinic_id')
      .eq('user_id', user.id)
      .eq('is_active', true)
      .limit(1)
      .single();

  final clinicId = membership['clinic_id'] as String;

  final repo = ref.watch(appointmentRepositoryProvider);
  yield* repo.watchTodayQueueForClinic(clinicId);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AppointmentRepository(supabase);
});

class AppointmentRepository {
  final dynamic
  _supabase; // Type is SupabaseClient but using dynamic to avoid explicit typing issues if not imported

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
      debugPrint('Error al obtener citas del paciente: $e');
      return [];
    }
  }

  /// Obtiene la fila de espera de hoy para una clínica en tiempo real (Stream) (Para el panel de Dentista)
  Future<List<Appointment>> getTodayQueueForClinic(
    String clinicId, {
    DateTime? now,
  }) async {
    final range = appointmentLocalDayUtcRange(now ?? DateTime.now());
    final response = await _supabase
        .from('appointments')
        .select('''
          *,
          patient:patients(first_name, last_name),
          doctor:doctors(user:profiles(name)),
          service:services(service_name, duration_mins)
        ''')
        .eq('clinic_id', clinicId)
        .gte('date_time', range.startUtc.toIso8601String())
        .lt('date_time', range.endUtc.toIso8601String())
        .inFilter('status', ['upcoming', 'in_lobby', 'in_treatment'])
        .order('date_time', ascending: true);

    return (response as List)
        .map((map) => Appointment.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  Stream<List<Appointment>> watchTodayQueueForClinic(String clinicId) async* {
    final changes = _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('clinic_id', clinicId);

    await for (final _ in changes) {
      yield await getTodayQueueForClinic(clinicId);
    }
  }

  Future<AppointmentSlotValidation> validateAppointmentSlot({
    required String clinicId,
    required String doctorId,
    required DateTime localStart,
    required int durationMinutes,
    String? excludeAppointmentId,
  }) async {
    if (durationMinutes <= 0) {
      return const AppointmentSlotValidation.invalid(
        'La duración del servicio no es válida.',
      );
    }
    if (localStart.isBefore(DateTime.now())) {
      return const AppointmentSlotValidation.invalid(
        'No se puede agendar una cita en el pasado.',
      );
    }

    final doctor = await _supabase
        .from('doctors')
        .select('user_id,is_available')
        .eq('id', doctorId)
        .eq('clinic_id', clinicId)
        .single();
    if (doctor['is_available'] != true) {
      return const AppointmentSlotValidation.invalid(
        'El dentista está marcado como no disponible.',
      );
    }

    final dayOfWeek = localStart.weekday % 7;
    Map<String, dynamic>? schedule;
    try {
      final row = await _supabase
          .from('doctor_schedules')
          .select('is_working_day,start_time,end_time')
          .eq('doctor_user_id', doctor['user_id'])
          .eq('clinic_id', clinicId)
          .eq('day_of_week', dayOfWeek)
          .maybeSingle();
      if (row != null) schedule = Map<String, dynamic>.from(row);
    } catch (_) {
      schedule = null;
    }

    final isDefaultWorkingDay =
        localStart.weekday >= DateTime.monday &&
        localStart.weekday <= DateTime.friday;
    final isWorkingDay =
        schedule?['is_working_day'] as bool? ?? isDefaultWorkingDay;
    if (!isWorkingDay) {
      return const AppointmentSlotValidation.invalid(
        'El dentista no trabaja el día seleccionado.',
      );
    }
    final workStart = schedule?['start_time']?.toString() ?? '08:00';
    final workEnd = schedule?['end_time']?.toString() ?? '17:00';
    if (!appointmentFitsWorkingHours(
      localStart: localStart,
      durationMinutes: durationMinutes,
      workStart: workStart,
      workEnd: workEnd,
    )) {
      return AppointmentSlotValidation.invalid(
        'La cita debe estar dentro del horario $workStart–$workEnd.',
      );
    }

    try {
      final date = localStart.toIso8601String().split('T').first;
      final dayOff = await _supabase
          .from('doctor_days_off')
          .select('id')
          .eq('doctor_user_id', doctor['user_id'])
          .eq('clinic_id', clinicId)
          .eq('date', date)
          .limit(1);
      if ((dayOff as List).isNotEmpty) {
        return const AppointmentSlotValidation.invalid(
          'El dentista tiene registrado un día libre en esa fecha.',
        );
      }
    } catch (_) {
      // La tabla de días libres es opcional en instalaciones antiguas.
    }

    final dayStart = DateTime(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final rows = await _supabase
        .from('appointments')
        .select('id,date_time,services(duration_mins)')
        .eq('clinic_id', clinicId)
        .eq('doctor_id', doctorId)
        .gte('date_time', dayStart.toUtc().toIso8601String())
        .lt(
          'date_time',
          dayStart.add(const Duration(days: 1)).toUtc().toIso8601String(),
        )
        .inFilter('status', ['upcoming', 'in_lobby', 'in_treatment']);
    final requestedEnd = localStart.add(Duration(minutes: durationMinutes));
    for (final row in rows as List) {
      if (row['id']?.toString() == excludeAppointmentId) continue;
      final existingStart = DateTime.parse(row['date_time']).toLocal();
      final existingDuration =
          (row['services']?['duration_mins'] as num?)?.toInt() ?? 30;
      final existingEnd = existingStart.add(
        Duration(minutes: existingDuration),
      );
      if (appointmentSlotsOverlap(
        firstStart: localStart,
        firstEnd: requestedEnd,
        secondStart: existingStart,
        secondEnd: existingEnd,
      )) {
        return AppointmentSlotValidation.invalid(
          'El dentista ya tiene una cita a las '
          '${existingStart.hour.toString().padLeft(2, '0')}:'
          '${existingStart.minute.toString().padLeft(2, '0')}.',
        );
      }
    }

    return const AppointmentSlotValidation.valid();
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required String clinicId,
    required String doctorId,
    required String serviceId,
    required DateTime localStart,
    required int durationMinutes,
  }) async {
    final validation = await validateAppointmentSlot(
      clinicId: clinicId,
      doctorId: doctorId,
      localStart: localStart,
      durationMinutes: durationMinutes,
      excludeAppointmentId: appointmentId,
    );
    if (!validation.isValid) throw StateError(validation.message!);

    final updated = await _supabase
        .from('appointments')
        .update({
          'doctor_id': doctorId,
          'service_id': serviceId,
          'date_time': localStart.toUtc().toIso8601String(),
        })
        .eq('id', appointmentId)
        .eq('clinic_id', clinicId)
        .eq('status', 'upcoming')
        .select('id');
    if ((updated as List).isEmpty) {
      throw StateError('La cita ya no puede reprogramarse.');
    }
  }

  /// Actualiza el estado de una cita y dispara la notificación push al paciente.
  /// Estados válidos: 'upcoming' | 'in_lobby' | 'in_treatment' | 'completed' | 'cancelled'
  Future<bool> updateAppointmentStatus(
    String appointmentId,
    String newStatus, {
    String? expectedCurrentStatus,
  }) async {
    if (expectedCurrentStatus != null &&
        !isValidAppointmentTransition(expectedCurrentStatus, newStatus)) {
      return false;
    }

    try {
      var query = _supabase
          .from('appointments')
          .update({'status': newStatus})
          .eq('id', appointmentId);

      if (expectedCurrentStatus != null) {
        query = query.eq('status', expectedCurrentStatus);
      }

      final updated = await query.select('id');
      if ((updated as List).isEmpty) return false;

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
  Future<void> _invokeNotification(
    String appointmentId,
    String newStatus,
  ) async {
    // Solo notificar en estados relevantes para el paciente
    const notifiableStatuses = {'in_lobby', 'in_treatment', 'completed'};
    if (!notifiableStatuses.contains(newStatus)) return;

    try {
      await _supabase.functions.invoke(
        'notify-patient-turn',
        body: {'appointmentId': appointmentId, 'newStatus': newStatus},
      );
      debugPrint(
        '[Notify] Edge Function invocada para cita $appointmentId → $newStatus',
      );
    } catch (e) {
      // Error silencioso: la notificación es opcional, no crítica
      debugPrint('[Notify] Error al invocar Edge Function: $e');
    }
  }
}

/// Rango UTC que representa el día calendario de la zona horaria local.
({DateTime startUtc, DateTime endUtc}) appointmentLocalDayUtcRange(
  DateTime localNow,
) {
  final startLocal = DateTime(localNow.year, localNow.month, localNow.day);
  final endLocal = startLocal.add(const Duration(days: 1));
  return (startUtc: startLocal.toUtc(), endUtc: endLocal.toUtc());
}

const Map<String, Set<String>> appointmentStatusTransitions = {
  'upcoming': {'in_lobby', 'cancelled'},
  'in_lobby': {'in_treatment', 'cancelled'},
  'in_treatment': {'completed', 'cancelled'},
};

bool isValidAppointmentTransition(String currentStatus, String newStatus) {
  return appointmentStatusTransitions[currentStatus]?.contains(newStatus) ??
      false;
}

class AppointmentSlotValidation {
  const AppointmentSlotValidation.valid() : isValid = true, message = null;
  const AppointmentSlotValidation.invalid(this.message) : isValid = false;

  final bool isValid;
  final String? message;
}

bool appointmentSlotsOverlap({
  required DateTime firstStart,
  required DateTime firstEnd,
  required DateTime secondStart,
  required DateTime secondEnd,
}) => firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);

bool appointmentFitsWorkingHours({
  required DateTime localStart,
  required int durationMinutes,
  required String workStart,
  required String workEnd,
}) {
  int parseMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  final startMinute = localStart.hour * 60 + localStart.minute;
  final endMinute = startMinute + durationMinutes;
  return startMinute >= parseMinutes(workStart) &&
      endMinute <= parseMinutes(workEnd);
}
