import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/core/models/doctor.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StaffRepository(client);
});

/// Repositorio para gestión de personal médico y administrativo.
/// Cubre operaciones sobre las tablas: clinic_memberships, doctors,
/// doctor_schedules y doctor_days_off.
class StaffRepository {
  final SupabaseClient _client;
  String? lastError;

  StaffRepository(this._client);

  void _clearError() => lastError = null;

  void _captureError(String operation, Object error) {
    debugPrint('$operation: $error');
    if (error is PostgrestException) {
      switch (error.code) {
        case '42501':
          lastError = 'Tu usuario no tiene permiso para realizar este cambio.';
          return;
        case 'PGRST205':
        case '42P01':
          lastError = 'Falta instalar una tabla requerida en Supabase.';
          return;
        case '42703':
          lastError = 'La base de datos no tiene una columna requerida.';
          return;
        case '23505':
          lastError = 'Ese registro ya existe.';
          return;
      }
      lastError = error.message;
      return;
    }
    lastError = 'Ocurrio un error inesperado. Intenta nuevamente.';
  }

  // ─────────────────────────────────────────────────────────────
  //  PERSONAL DE LA CLÍNICA
  // ─────────────────────────────────────────────────────────────

  /// Devuelve todo el personal activo de la clínica (dentistas + secretarias).
  /// Incluye datos del perfil y del registro en la tabla doctors si existe.
  Future<List<StaffMember>> getStaffInClinic(
    String clinicId, {
    bool includeInactive = false,
  }) async {
    _clearError();
    try {
      final membershipsQuery = _client
          .from('clinic_memberships')
          .select('user_id, clinic_id, role_in_clinic, is_active')
          .eq('clinic_id', clinicId)
          .inFilter('role_in_clinic', ['owner', 'dentist', 'secretary']);
      final memberships = includeInactive
          ? await membershipsQuery
          : await membershipsQuery.eq('is_active', true);

      final userIds = memberships
          .map<String>((m) => m['user_id'] as String)
          .toSet()
          .toList();

      final profiles = userIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('profiles')
                .select('id, name')
                .inFilter('id', userIds);

      final doctorsRecords = await _client
          .from('doctors')
          .select('id, user_id, specialty, cabin_assigned, is_available')
          .eq('clinic_id', clinicId);

      final profilesByUserId = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        profilesByUserId[p['id'] as String] = p;
      }

      final doctorsByUserId = <String, Map<String, dynamic>>{};
      for (final d in doctorsRecords) {
        doctorsByUserId[d['user_id'] as String] = d;
      }

      return memberships.map<StaffMember>((m) {
        final userId = m['user_id'] as String;
        final enriched = Map<String, dynamic>.from(m);
        enriched['profiles'] = profilesByUserId[userId];
        enriched['doctors'] = doctorsByUserId[userId];
        return StaffMember.fromMap(enriched);
      }).toList();
    } catch (e) {
      debugPrint('Error loading staff in clinic: $e');
      return [];
    }
  }

  /// Actualiza el consultorio asignado de un doctor.
  Future<bool> updateDoctorCabin({
    required String doctorRecordId,
    required String cabin,
  }) async {
    try {
      await _client
          .from('doctors')
          .update({'cabin_assigned': cabin})
          .eq('id', doctorRecordId);
      return true;
    } catch (e) {
      _captureError('Error updating doctor cabin', e);
      return false;
    }
  }

  /// Actualiza la especialidad mostrada en la ficha del doctor.
  Future<bool> updateDoctorSpecialty({
    required String doctorRecordId,
    required String specialty,
  }) async {
    _clearError();
    try {
      await _client
          .from('doctors')
          .update({'specialty': specialty.trim()})
          .eq('id', doctorRecordId);
      return true;
    } catch (e) {
      _captureError('Error updating doctor specialty', e);
      return false;
    }
  }

  /// Crea el registro de doctor si no existe (para owner que no fue creado manualmente).
  Future<String?> ensureDoctorRecord({
    required String userId,
    required String clinicId,
    String specialty = 'General',
    String cabin = 'Consultorio 1',
  }) async {
    _clearError();
    try {
      final existing = await _client
          .from('doctors')
          .select('id')
          .eq('user_id', userId)
          .eq('clinic_id', clinicId)
          .maybeSingle();

      if (existing != null) return existing['id'] as String;

      final result = await _client
          .from('doctors')
          .insert({
            'user_id': userId,
            'clinic_id': clinicId,
            'specialty': specialty,
            'cabin_assigned': cabin,
            'is_available': true,
          })
          .select('id')
          .single();

      return result['id'] as String;
    } catch (e) {
      debugPrint('Error ensuring doctor record: $e');
      return null;
    }
  }

  /// Alterna la disponibilidad del doctor (disponible / no disponible).
  Future<bool> toggleAvailability({
    required String doctorRecordId,
    required bool isAvailable,
  }) async {
    _clearError();
    try {
      await _client
          .from('doctors')
          .update({'is_available': isAvailable})
          .eq('id', doctorRecordId);
      return true;
    } catch (e) {
      _captureError('Error updating doctor availability', e);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  HORARIOS SEMANALES
  // ─────────────────────────────────────────────────────────────

  /// Obtiene el horario semanal completo de un doctor (7 días).
  /// Si algún día no tiene registro, retorna uno por defecto.
  Future<List<DoctorDaySchedule>> getWeeklySchedule({
    required String doctorUserId,
    required String clinicId,
  }) async {
    _clearError();
    try {
      final rows = await _client
          .from('doctor_schedules')
          .select()
          .eq('doctor_user_id', doctorUserId)
          .eq('clinic_id', clinicId)
          .order('day_of_week');

      final existing = {for (final r in rows) r['day_of_week'] as int: r};

      // Asegurar los 7 días
      return List.generate(7, (i) {
        if (existing.containsKey(i)) {
          return DoctorDaySchedule.fromMap(existing[i]!);
        }
        // Días por defecto: lunes a viernes activos, fines de semana libres
        return DoctorDaySchedule(dayOfWeek: i, isWorkingDay: i >= 1 && i <= 5);
      });
    } catch (e) {
      _captureError('Error loading doctor schedule', e);
      return List.generate(
        7,
        (i) => DoctorDaySchedule(dayOfWeek: i, isWorkingDay: i >= 1 && i <= 5),
      );
    }
  }

  /// Guarda (UPSERT) el horario completo de un doctor.
  Future<bool> saveWeeklySchedule({
    required String doctorUserId,
    required String clinicId,
    required List<DoctorDaySchedule> schedule,
  }) async {
    _clearError();
    try {
      final rows = schedule
          .map((s) => s.toMap(doctorUserId, clinicId))
          .toList();

      await _client
          .from('doctor_schedules')
          .upsert(rows, onConflict: 'doctor_user_id,clinic_id,day_of_week');
      return true;
    } catch (e) {
      _captureError('Error saving doctor schedule', e);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  DÍAS LIBRES
  // ─────────────────────────────────────────────────────────────

  /// Obtiene todos los días libres futuros de un doctor.
  Future<List<DoctorDayOff>> getDaysOff({
    required String doctorUserId,
    required String clinicId,
  }) async {
    _clearError();
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final rows = await _client
          .from('doctor_days_off')
          .select()
          .eq('doctor_user_id', doctorUserId)
          .eq('clinic_id', clinicId)
          .gte('date', today)
          .order('date');

      return rows.map((r) => DoctorDayOff.fromMap(r)).toList();
    } catch (e) {
      _captureError('Error loading doctor days off', e);
      return [];
    }
  }

  /// Agrega un día libre.
  Future<bool> addDayOff({
    required String doctorUserId,
    required String clinicId,
    required DateTime date,
    String? reason,
  }) async {
    _clearError();
    try {
      await _client.from('doctor_days_off').insert({
        'doctor_user_id': doctorUserId,
        'clinic_id': clinicId,
        'date': date.toIso8601String().substring(0, 10),
        'reason': reason,
      });
      return true;
    } catch (e) {
      _captureError('Error adding doctor day off', e);
      return false;
    }
  }

  /// Elimina un día libre por su ID.
  Future<bool> removeDayOff(String dayOffId) async {
    _clearError();
    try {
      await _client.from('doctor_days_off').delete().eq('id', dayOffId);
      return true;
    } catch (e) {
      _captureError('Error removing doctor day off', e);
      return false;
    }
  }

  /// Remueve el acceso de un miembro del personal (desactiva membresía).
  Future<bool> removeMemberAccess({
    required String userId,
    required String clinicId,
  }) async {
    _clearError();
    try {
      await _client
          .from('clinic_memberships')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('clinic_id', clinicId);
      return true;
    } catch (e) {
      _captureError('Error removing member access', e);
      return false;
    }
  }

  Future<bool> setMemberAccess({
    required String userId,
    required String clinicId,
    required bool isActive,
  }) async {
    _clearError();
    try {
      await _client
          .from('clinic_memberships')
          .update({'is_active': isActive})
          .eq('user_id', userId)
          .eq('clinic_id', clinicId);
      return true;
    } catch (e) {
      _captureError('Error updating member access', e);
      return false;
    }
  }
}
