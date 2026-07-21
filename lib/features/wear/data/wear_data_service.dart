enum WearRole { patient, dentist }

class WearPatientQueueData {
  final String patientName;
  final String queueCode;
  final int peopleAhead;
  final int estimatedMinutes;
  final String doctorName;
  final String serviceName;
  final String roomName;
  final String status;

  const WearPatientQueueData({
    required this.patientName,
    required this.queueCode,
    required this.peopleAhead,
    required this.estimatedMinutes,
    required this.doctorName,
    required this.serviceName,
    required this.roomName,
    required this.status,
  });

  factory WearPatientQueueData.fromJson(Map<String, dynamic> json) {
    return WearPatientQueueData(
      patientName: json['patient_name'] as String? ?? 'Paciente',
      queueCode: json['queue_code'] as String? ?? 'Sin turno',
      peopleAhead: _asInt(json['people_ahead']),
      estimatedMinutes: _asInt(json['estimated_minutes']),
      doctorName: json['doctor_name'] as String? ?? 'Dentista',
      serviceName: json['service_name'] as String? ?? 'Consulta',
      roomName: json['room_name'] as String? ?? 'Consultorio',
      status: json['status'] as String? ?? 'upcoming',
    );
  }

  Map<String, dynamic> toJson() => {
    'patient_name': patientName,
    'queue_code': queueCode,
    'people_ahead': peopleAhead,
    'estimated_minutes': estimatedMinutes,
    'doctor_name': doctorName,
    'service_name': serviceName,
    'room_name': roomName,
    'status': status,
  };

  static const demo = WearPatientQueueData(
    patientName: 'Paciente',
    queueCode: 'Sin turno',
    peopleAhead: 0,
    estimatedMinutes: 0,
    doctorName: 'Dentista',
    serviceName: 'Consulta',
    roomName: 'Consultorio',
    status: 'upcoming',
  );
}

class WearDoctorQueueData {
  final String appointmentId;
  final String patientName;
  final String queueCode;
  final int queueCount;
  final int estimatedMinutes;
  final String statusLabel;

  const WearDoctorQueueData({
    required this.appointmentId,
    required this.patientName,
    required this.queueCode,
    required this.queueCount,
    required this.estimatedMinutes,
    required this.statusLabel,
  });

  factory WearDoctorQueueData.fromJson(Map<String, dynamic> json) {
    return WearDoctorQueueData(
      appointmentId: json['appointment_id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? 'Paciente',
      queueCode: json['queue_code'] as String? ?? 'Sin turno',
      queueCount: _asInt(json['queue_count']),
      estimatedMinutes: _asInt(json['estimated_minutes']),
      statusLabel: json['status_label'] as String? ?? 'Listo',
    );
  }

  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'patient_name': patientName,
    'queue_code': queueCode,
    'queue_count': queueCount,
    'estimated_minutes': estimatedMinutes,
    'status_label': statusLabel,
  };

  static const demo = WearDoctorQueueData(
    appointmentId: '',
    patientName: 'Paciente',
    queueCode: 'Sin turno',
    queueCount: 0,
    estimatedMinutes: 0,
    statusLabel: 'Sin citas',
  );
}

class WearPatientSummaryData {
  final String userName;
  final String email;
  final String roleLabel;
  final List<String> patientNames;
  final int appointmentCount;
  final String? nextPatientName;
  final DateTime? nextAppointmentTime;

  const WearPatientSummaryData({
    required this.userName,
    required this.email,
    required this.roleLabel,
    required this.patientNames,
    required this.appointmentCount,
    required this.nextPatientName,
    required this.nextAppointmentTime,
  });

  factory WearPatientSummaryData.fromJson(Map<String, dynamic> json) {
    return WearPatientSummaryData(
      userName: json['user_name'] as String? ?? 'Cliente',
      email: json['email'] as String? ?? '',
      roleLabel: json['role_label'] as String? ?? 'Cliente',
      patientNames: List<String>.from(
        json['patient_names'] as List? ?? const [],
      ),
      appointmentCount: _asInt(json['appointment_count']),
      nextPatientName: json['next_patient_name'] as String?,
      nextAppointmentTime: DateTime.tryParse(
        json['next_appointment_time'] as String? ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_name': userName,
    'email': email,
    'role_label': roleLabel,
    'patient_names': patientNames,
    'appointment_count': appointmentCount,
    'next_patient_name': nextPatientName,
    'next_appointment_time': nextAppointmentTime?.toIso8601String(),
  };

  bool get hasAppointments => appointmentCount > 0;
}

class WearStartupData {
  final WearRole role;
  final WearPatientQueueData? patient;
  final WearDoctorQueueData? doctor;
  final WearPatientSummaryData? summary;
  final bool isLinked;

  const WearStartupData({
    required this.role,
    required this.patient,
    required this.doctor,
    required this.summary,
    required this.isLinked,
  });

  factory WearStartupData.fromJson(Map<String, dynamic> json) {
    final role = json['role'] == 'dentist' || json['role'] == 'secretary'
        ? WearRole.dentist
        : WearRole.patient;
    final patientJson = json['patient_queue'];
    final doctorJson = json['doctor_queue'];
    final summaryJson = json['summary'];

    return WearStartupData(
      role: role,
      patient: patientJson is Map
          ? WearPatientQueueData.fromJson(
              Map<String, dynamic>.from(patientJson),
            )
          : null,
      doctor: doctorJson is Map
          ? WearDoctorQueueData.fromJson(Map<String, dynamic>.from(doctorJson))
          : null,
      summary: summaryJson is Map
          ? WearPatientSummaryData.fromJson(
              Map<String, dynamic>.from(summaryJson),
            )
          : null,
      isLinked: json['is_linked'] != false,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
