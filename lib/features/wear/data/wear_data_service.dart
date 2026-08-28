enum WearRole { patient, dentist, secretary }

class WearPatientQueueData {
  final String patientName;
  final String queueCode;
  final int peopleAhead;
  final int estimatedMinutes;
  final String doctorName;
  final String serviceName;
  final String roomName;
  final String status;
  final String dateTimeLabel;
  final bool hasReminder;

  const WearPatientQueueData({
    required this.patientName,
    required this.queueCode,
    required this.peopleAhead,
    required this.estimatedMinutes,
    required this.doctorName,
    required this.serviceName,
    required this.roomName,
    required this.status,
    this.dateTimeLabel = 'Hoy • 10:30 AM',
    this.hasReminder = false,
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
      dateTimeLabel: json['date_time_label'] as String? ?? 'Hoy • 10:30 AM',
      hasReminder: json['has_reminder'] == true,
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
    'date_time_label': dateTimeLabel,
    'has_reminder': hasReminder,
  };

  static const demo = WearPatientQueueData(
    patientName: 'Paciente',
    queueCode: 'C-04',
    peopleAhead: 1,
    estimatedMinutes: 15,
    doctorName: 'Dr. García',
    serviceName: 'Limpieza Dental',
    roomName: 'Consultorio 2',
    status: 'upcoming',
    dateTimeLabel: 'Hoy • 10:30 AM',
    hasReminder: false,
  );
}

class WearDoctorQueueData {
  final String appointmentId;
  final String patientName;
  final String queueCode;
  final int queueCount;
  final int estimatedMinutes;
  final String statusLabel;
  final String status;
  final String doctorName;

  const WearDoctorQueueData({
    required this.appointmentId,
    required this.patientName,
    required this.queueCode,
    required this.queueCount,
    required this.estimatedMinutes,
    required this.statusLabel,
    required this.status,
    required this.doctorName,
  });

  factory WearDoctorQueueData.fromJson(Map<String, dynamic> json) {
    return WearDoctorQueueData(
      appointmentId: json['appointment_id'] as String? ?? '',
      patientName: json['patient_name'] as String? ?? 'Paciente',
      queueCode: json['queue_code'] as String? ?? 'Sin turno',
      queueCount: _asInt(json['queue_count']),
      estimatedMinutes: _asInt(json['estimated_minutes']),
      statusLabel: json['status_label'] as String? ?? 'Listo',
      status: json['status'] as String? ?? 'upcoming',
      doctorName: json['doctor_name'] as String? ?? 'Dentista',
    );
  }

  Map<String, dynamic> toJson() => {
    'appointment_id': appointmentId,
    'patient_name': patientName,
    'queue_code': queueCode,
    'queue_count': queueCount,
    'estimated_minutes': estimatedMinutes,
    'status_label': statusLabel,
    'status': status,
    'doctor_name': doctorName,
  };

  static const demo = WearDoctorQueueData(
    appointmentId: '',
    patientName: 'Paciente',
    queueCode: 'Sin turno',
    queueCount: 0,
    estimatedMinutes: 0,
    statusLabel: 'Sin citas',
    status: 'upcoming',
    doctorName: 'Dentista',
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
  final List<WearPatientQueueData> appointments;

  const WearPatientSummaryData({
    required this.userName,
    required this.email,
    required this.roleLabel,
    required this.patientNames,
    required this.appointmentCount,
    required this.nextPatientName,
    required this.nextAppointmentTime,
    this.appointments = const [],
  });

  factory WearPatientSummaryData.fromJson(Map<String, dynamic> json) {
    final rawList = json['appointments'] as List? ?? const [];
    final appts = rawList
        .whereType<Map>()
        .map((m) => WearPatientQueueData.fromJson(Map<String, dynamic>.from(m)))
        .toList();

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
      appointments: appts,
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
    'appointments': appointments.map((a) => a.toJson()).toList(),
  };

  bool get hasAppointments => appointmentCount > 0 || appointments.isNotEmpty;
}

class WearStartupData {
  final WearRole role;
  final WearPatientQueueData? patient;
  final WearDoctorQueueData? doctor;
  final WearDoctorQueueData? secretary;
  final WearPatientSummaryData? summary;
  final bool isLinked;

  const WearStartupData({
    required this.role,
    required this.patient,
    required this.doctor,
    required this.secretary,
    required this.summary,
    required this.isLinked,
  });

  factory WearStartupData.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'dentist' => WearRole.dentist,
      'secretary' => WearRole.secretary,
      _ => WearRole.patient,
    };
    final patientJson = json['patient_queue'];
    final doctorJson = json['doctor_queue'];
    final secretaryJson = json['secretary_queue'];
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
      secretary: secretaryJson is Map
          ? WearDoctorQueueData.fromJson(
              Map<String, dynamic>.from(secretaryJson),
            )
          : null,
      summary: summaryJson is Map
          ? WearPatientSummaryData.fromJson(
              Map<String, dynamic>.from(summaryJson),
            )
          : null,
      isLinked: json['is_linked'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'patient_queue': patient?.toJson(),
        'doctor_queue': doctor?.toJson(),
        'secretary_queue': secretary?.toJson(),
        'summary': summary?.toJson(),
        'is_linked': isLinked,
      };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
