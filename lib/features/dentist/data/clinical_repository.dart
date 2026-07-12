import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/core/models/clinical_note.dart';
import 'package:sistema_dental/core/models/prescription.dart';

final clinicalRepositoryProvider = Provider<ClinicalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClinicalRepository(client);
});

/// Repositorio para operaciones CRUD sobre notas clínicas y recetas.
class ClinicalRepository {
  final SupabaseClient _client;

  ClinicalRepository(this._client);

  // ─────────────────────────────────────────────────────────────
  //  NOTAS CLÍNICAS
  // ─────────────────────────────────────────────────────────────

  /// Obtiene todas las notas clínicas de un paciente (historial completo).
  Future<List<ClinicalNote>> getNotesForPatient(String patientId) async {
    try {
      final response = await _client
          .from('clinical_notes')
          .select('''
            *,
            doctor:doctors(user:profiles(name)),
            patient:patients(first_name, last_name)
          ''')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((map) => ClinicalNote.fromMap(map))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener notas clínicas: $e');
      return [];
    }
  }

  /// Obtiene las notas clínicas de un paciente filtradas por clínica.
  Future<List<ClinicalNote>> getNotesForPatientInClinic(
    String patientId,
    String clinicId,
  ) async {
    try {
      final response = await _client
          .from('clinical_notes')
          .select('''
            *,
            doctor:doctors(user:profiles(name)),
            patient:patients(first_name, last_name)
          ''')
          .eq('patient_id', patientId)
          .eq('clinic_id', clinicId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((map) => ClinicalNote.fromMap(map))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener notas clínicas: $e');
      return [];
    }
  }

  /// Obtiene la nota clínica asociada a una cita específica.
  Future<ClinicalNote?> getNoteForAppointment(String appointmentId) async {
    try {
      final response = await _client
          .from('clinical_notes')
          .select('''
            *,
            doctor:doctors(user:profiles(name)),
            patient:patients(first_name, last_name)
          ''')
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (response == null) return null;
      return ClinicalNote.fromMap(response);
    } catch (e) {
      debugPrint('Error al obtener nota de cita: $e');
      return null;
    }
  }

  /// Crea o actualiza una nota clínica.
  /// Si la nota ya tiene un ID, se actualiza; si no, se crea una nueva.
  Future<ClinicalNote?> saveNote(ClinicalNote note) async {
    try {
      if (note.id != null) {
        // Actualizar nota existente
        final response = await _client
            .from('clinical_notes')
            .update(note.toMap())
            .eq('id', note.id!)
            .select()
            .single();
        return ClinicalNote.fromMap(response);
      } else {
        // Crear nueva nota
        final response = await _client
            .from('clinical_notes')
            .insert(note.toMap())
            .select()
            .single();
        return ClinicalNote.fromMap(response);
      }
    } catch (e) {
      debugPrint('Error al guardar nota clínica: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  RECETAS
  // ─────────────────────────────────────────────────────────────

  /// Obtiene la receta asociada a una nota clínica.
  Future<Prescription?> getPrescription(String clinicalNoteId) async {
    try {
      final response = await _client
          .from('prescriptions')
          .select('''
            *,
            doctor:doctors(user:profiles(name)),
            patient:patients(first_name, last_name),
            clinic:clinics(business_name)
          ''')
          .eq('clinical_note_id', clinicalNoteId)
          .maybeSingle();

      if (response == null) return null;
      return Prescription.fromMap(response);
    } catch (e) {
      debugPrint('Error al obtener receta: $e');
      return null;
    }
  }

  /// Obtiene todas las recetas de un paciente.
  Future<List<Prescription>> getPrescriptionsForPatient(
      String patientId) async {
    try {
      final response = await _client
          .from('prescriptions')
          .select('''
            *,
            doctor:doctors(user:profiles(name)),
            patient:patients(first_name, last_name),
            clinic:clinics(business_name)
          ''')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((map) => Prescription.fromMap(map))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener recetas: $e');
      return [];
    }
  }

  /// Crea o actualiza una receta.
  Future<Prescription?> savePrescription(Prescription prescription) async {
    try {
      if (prescription.id != null) {
        final response = await _client
            .from('prescriptions')
            .update(prescription.toMap())
            .eq('id', prescription.id!)
            .select()
            .single();
        return Prescription.fromMap(response);
      } else {
        final response = await _client
            .from('prescriptions')
            .insert(prescription.toMap())
            .select()
            .single();
        return Prescription.fromMap(response);
      }
    } catch (e) {
      debugPrint('Error al guardar receta: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  UTILIDADES
  // ─────────────────────────────────────────────────────────────

  /// Obtiene la lista de pacientes de una clínica (para búsqueda).
  Future<List<Map<String, dynamic>>> getPatientsInClinic(
      String clinicId) async {
    try {
      final response = await _client
          .from('patients')
          .select('id, first_name, last_name, date_of_birth')
          .eq('clinic_id', clinicId)
          .order('last_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error al obtener pacientes: $e');
      return [];
    }
  }

  /// Obtiene el doctor_id (tabla doctors) del usuario actual en una clínica.
  Future<String?> getDoctorRecordId(String userId, String clinicId) async {
    try {
      final response = await _client
          .from('doctors')
          .select('id')
          .eq('user_id', userId)
          .eq('clinic_id', clinicId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      debugPrint('Error al obtener doctor record: $e');
      return null;
    }
  }
}
