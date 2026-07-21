import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sistema_dental/features/wear/data/wear_data_service.dart';

class WearLinkResult {
  final bool success;
  final int deviceCount;
  final String message;

  const WearLinkResult({
    required this.success,
    required this.deviceCount,
    required this.message,
  });
}

class WearLinkService {
  static const _channel = MethodChannel('dental_sync/wear_link');
  static const instance = WearLinkService._();

  const WearLinkService._();

  Future<int> getConnectedWearDevices() async {
    try {
      final count = await _channel.invokeMethod<int>('getConnectedWearDevices');
      return count ?? 0;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }

  Future<WearLinkResult> linkCurrentSession({required String role}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const WearLinkResult(
        success: false,
        deviceCount: 0,
        message: 'Inicia sesión antes de vincular el reloj.',
      );
    }

    try {
      final payload = await _buildCompanionState(roleLabel: role);
      final envelope = {
        'state_json': jsonEncode(payload),
        'sent_at': payload['sent_at'],
      };
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'linkWearSession',
        envelope,
      );

      final deviceCount = (result?['device_count'] as int?) ?? 0;
      final success = result?['success'] == true;

      return WearLinkResult(
        success: success,
        deviceCount: deviceCount,
        message: success
            ? 'Estado enviado al reloj. Toca Reintentar en Wear OS.'
            : 'No se detectó un reloj Wear OS conectado.',
      );
    } on MissingPluginException {
      return const WearLinkResult(
        success: false,
        deviceCount: 0,
        message: 'La vinculación Wear OS solo está disponible en Android.',
      );
    } on PlatformException catch (e) {
      return WearLinkResult(
        success: false,
        deviceCount: 0,
        message: e.message ?? 'No se pudo vincular el reloj.',
      );
    } catch (e) {
      debugPrint('[Wear] Error preparando estado companion: $e');
      return const WearLinkResult(
        success: false,
        deviceCount: 0,
        message: 'No se pudo preparar la información del reloj.',
      );
    }
  }

  Future<WearStartupData?> readCompanionState() async {
    try {
      final unlinked = await consumePendingUnlink();
      if (unlinked) return null;

      final payload = await _channel.invokeMapMethod<String, dynamic>(
        'consumePendingWearSession',
      );
      final stateJson = payload?['state_json'] as String?;
      if (stateJson == null || stateJson.isEmpty) return null;

      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      if (state['is_linked'] == false) return null;
      return WearStartupData.fromJson(state);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } catch (e) {
      debugPrint('[Wear] Error leyendo estado companion: $e');
      return null;
    }
  }

  Future<bool> restoreSessionFromCompanion() async {
    return await readCompanionState() != null;
  }

  Future<WearLinkResult> unlinkCurrentSession() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'unlinkWearSession',
      );
      final deviceCount = (result?['device_count'] as int?) ?? 0;
      final success = result?['success'] == true;

      return WearLinkResult(
        success: success,
        deviceCount: deviceCount,
        message: success
            ? 'Orden de desvinculación enviada al reloj.'
            : 'No se detectó un reloj Wear OS conectado.',
      );
    } on MissingPluginException {
      return const WearLinkResult(
        success: false,
        deviceCount: 0,
        message: 'La desvinculación Wear OS solo está disponible en Android.',
      );
    } on PlatformException catch (e) {
      return WearLinkResult(
        success: false,
        deviceCount: 0,
        message: e.message ?? 'No se pudo avisar al reloj.',
      );
    }
  }

  Future<bool> consumePendingUnlink() async {
    try {
      return await _channel.invokeMethod<bool>('consumePendingWearUnlink') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<Map<String, dynamic>> _buildCompanionState({
    required String roleLabel,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser!;
    final profile = await client
        .from('profiles')
        .select('name, email, role')
        .eq('id', user.id)
        .maybeSingle();

    final membership = await client
        .from('clinic_memberships')
        .select('clinic_id, role_in_clinic')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    final clinicRole = membership?['role_in_clinic'] as String?;
    final clinicId = membership?['clinic_id'] as String?;
    final role = _wearRole(roleLabel, clinicRole, profile?['role'] as String?);
    final summary = await _buildSummary(profile, user.id);

    Map<String, dynamic>? patientQueue;
    Map<String, dynamic>? doctorQueue;
    if (role == 'dentist' && clinicId != null) {
      doctorQueue = await _buildDoctorQueue(clinicId);
    } else if (clinicId != null) {
      patientQueue = await _buildPatientQueue(user.id, clinicId);
    }

    return {
      'is_linked': true,
      'role': role,
      'sent_at': DateTime.now().toUtc().toIso8601String(),
      'summary': summary,
      'patient_queue': patientQueue,
      'doctor_queue': doctorQueue,
    };
  }

  Future<Map<String, dynamic>> _buildSummary(
    Map<String, dynamic>? profile,
    String userId,
  ) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser!;
    final patients = await client
        .from('patients')
        .select('id, first_name, last_name')
        .eq('profile_id', userId)
        .order('first_name');

    final patientRows = List<Map<String, dynamic>>.from(patients);
    final patientIds = patientRows.map((p) => p['id'] as String).toList();
    List<Map<String, dynamic>> appointmentRows = [];
    if (patientIds.isNotEmpty) {
      final appointments = await client
          .from('appointments')
          .select('''
            id,
            patient_id,
            date_time,
            status,
            patient:patients(first_name, last_name)
          ''')
          .inFilter('patient_id', patientIds)
          .inFilter('status', ['upcoming', 'in_lobby', 'in_treatment'])
          .order('date_time')
          .limit(20);
      appointmentRows = List<Map<String, dynamic>>.from(appointments);
    }

    final next = appointmentRows.isEmpty ? null : appointmentRows.first;
    return {
      'user_name':
          profile?['name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.email?.split('@').first ??
          'Cliente',
      'email': profile?['email'] as String? ?? user.email ?? '',
      'role_label': _roleLabel(profile?['role'] as String? ?? 'client'),
      'patient_names': patientRows.map(_patientRowName).toList(),
      'appointment_count': appointmentRows.length,
      'next_patient_name': next == null ? null : _patientName(next),
      'next_appointment_time': next?['date_time'] as String?,
    };
  }

  Future<Map<String, dynamic>?> _buildPatientQueue(
    String userId,
    String clinicId,
  ) async {
    final client = Supabase.instance.client;
    final patients = await client
        .from('patients')
        .select('id')
        .eq('profile_id', userId);
    final patientIds = List<Map<String, dynamic>>.from(
      patients,
    ).map((patient) => patient['id'] as String).toList();
    if (patientIds.isEmpty) return null;

    final appointments = await client
        .from('appointments')
        .select('''
          id,
          clinic_id,
          patient_id,
          date_time,
          status,
          queue_code,
          patient:patients(first_name, last_name),
          doctor:doctors(cabin_assigned, user:profiles(name)),
          service:services(service_name, duration_mins)
        ''')
        .eq('clinic_id', clinicId)
        .inFilter('patient_id', patientIds)
        .inFilter('status', ['upcoming', 'in_lobby', 'in_treatment'])
        .order('date_time')
        .limit(1);
    final rows = List<Map<String, dynamic>>.from(appointments);
    if (rows.isEmpty) return null;

    final appointment = rows.first;
    final ahead = await _countPeopleAhead(
      clinicId: clinicId,
      dateTime: appointment['date_time'] as String,
    );
    return {
      'patient_name': _patientName(appointment),
      'queue_code': appointment['queue_code'] as String? ?? 'Sin turno',
      'people_ahead': ahead,
      'estimated_minutes':
          ((appointment['service']?['duration_mins'] as int?) ?? 6) * ahead,
      'doctor_name':
          appointment['doctor']?['user']?['name'] as String? ?? 'Dentista',
      'service_name':
          appointment['service']?['service_name'] as String? ?? 'Consulta',
      'room_name':
          appointment['doctor']?['cabin_assigned'] as String? ?? 'Consultorio',
      'status': appointment['status'] as String? ?? 'upcoming',
    };
  }

  Future<Map<String, dynamic>?> _buildDoctorQueue(String clinicId) async {
    final client = Supabase.instance.client;
    final appointments = await client
        .from('appointments')
        .select('''
          id,
          date_time,
          status,
          queue_code,
          patient:patients(first_name, last_name),
          service:services(duration_mins)
        ''')
        .eq('clinic_id', clinicId)
        .inFilter('status', ['upcoming', 'in_lobby', 'in_treatment'])
        .order('date_time')
        .limit(10);
    final rows = List<Map<String, dynamic>>.from(appointments);
    if (rows.isEmpty) return null;

    final current = rows.first;
    return {
      'appointment_id': current['id'] as String,
      'patient_name': _patientName(current),
      'queue_code': current['queue_code'] as String? ?? 'Sin turno',
      'queue_count': rows.length,
      'estimated_minutes':
          ((current['service']?['duration_mins'] as int?) ?? 6) * rows.length,
      'status_label': _statusLabel(current['status'] as String? ?? 'upcoming'),
    };
  }

  Future<int> _countPeopleAhead({
    required String clinicId,
    required String dateTime,
  }) async {
    final response = await Supabase.instance.client
        .from('appointments')
        .select('id')
        .eq('clinic_id', clinicId)
        .inFilter('status', ['upcoming', 'in_lobby'])
        .lt('date_time', dateTime);
    return List.from(response).length;
  }

  String _wearRole(String roleLabel, String? clinicRole, String? profileRole) {
    final source =
        '${roleLabel.toLowerCase()} ${clinicRole ?? ''} ${profileRole ?? ''}';
    if (source.contains('dentist') ||
        source.contains('dentista') ||
        source.contains('secretary') ||
        source.contains('secretaria') ||
        source.contains('owner')) {
      return 'dentist';
    }
    return 'patient';
  }

  String _patientName(Map<String, dynamic> appointment) {
    final patient = appointment['patient'];
    if (patient == null) return 'Paciente';
    return '${patient['first_name'] ?? 'Paciente'} ${patient['last_name'] ?? ''}'
        .trim();
  }

  String _patientRowName(Map<String, dynamic> patient) {
    return '${patient['first_name'] ?? 'Paciente'} ${patient['last_name'] ?? ''}'
        .trim();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'dentist':
        return 'Dentista';
      case 'secretary':
        return 'Secretaria';
      case 'admin':
      case 'owner':
        return 'Administrador';
      default:
        return 'Cliente';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_lobby':
        return 'En sala';
      case 'in_treatment':
        return 'En tratamiento';
      case 'completed':
        return 'Atendido';
      default:
        return 'Listo';
    }
  }
}
