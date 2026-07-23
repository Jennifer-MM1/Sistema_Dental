import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:sistema_dental/core/models/patient.dart';
import 'package:sistema_dental/core/supabase/supabase_provider.dart';
import 'package:sistema_dental/features/auth/providers/auth_providers.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PatientRepository(supabase);
});

final familyPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  final repo = ref.watch(patientRepositoryProvider);
  return repo.getPatientsByProfileId(user.id);
});

class SelectedPatientNotifier extends Notifier<Patient?> {
  @override
  Patient? build() => null;

  void select(Patient patient) => state = patient;
}

final selectedPatientProvider =
    NotifierProvider<SelectedPatientNotifier, Patient?>(() {
      return SelectedPatientNotifier();
    });

class PatientRepository {
  final dynamic
  _supabase; // Usamos dynamic por simplicidad si no tenemos el tipo exacto importado. En la práctica es SupabaseClient

  PatientRepository(this._supabase);

  Future<List<Patient>> getPatientsByProfileId(
    String profileId, {
    String? clinicId,
  }) async {
    try {
      var query = _supabase
          .from('patients')
          .select()
          .eq('profile_id', profileId);

      if (clinicId != null) {
        query = query.eq('clinic_id', clinicId);
      }

      final response = await query.order('created_at', ascending: true);

      return (response as List).map((map) => Patient.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error al obtener pacientes: $e');
      return [];
    }
  }

  Future<Patient?> createPatient({
    required String clinicId,
    required String profileId,
    required String firstName,
    required String lastName,
    required String relationship,
    DateTime? dateOfBirth,
  }) async {
    try {
      final response = await _supabase
          .from('patients')
          .insert({
            'clinic_id': clinicId,
            'profile_id': profileId,
            'first_name': firstName,
            'last_name': lastName,
            'relationship': relationship,
            if (dateOfBirth != null)
              'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
          })
          .select()
          .single();

      return Patient.fromMap(response);
    } catch (e) {
      debugPrint('Error al crear paciente: $e');
      return null;
    }
  }

  Future<String?> getPrimaryClinicIdForUser(String userId) async {
    try {
      final response = await _supabase
          .from('clinic_memberships')
          .select('clinic_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      return response?['clinic_id'] as String?;
    } catch (e) {
      debugPrint('Error al obtener clínica del usuario: $e');
      return null;
    }
  }
}
