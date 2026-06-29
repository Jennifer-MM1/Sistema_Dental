class Appointment {
  final String id;
  final String clinicId;
  final String patientId;
  final String doctorId;
  final String serviceId;
  final DateTime dateTime;
  final String status;
  final String? queueCode;
  final String? medicalNotes;

  // Joined fields
  final String? doctorName;
  final String? patientName;
  final String? serviceName;
  final int? serviceDurationMins;

  const Appointment({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.doctorId,
    required this.serviceId,
    required this.dateTime,
    required this.status,
    this.queueCode,
    this.medicalNotes,
    this.doctorName,
    this.patientName,
    this.serviceName,
    this.serviceDurationMins,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    // Manejar joins en caso de que existan
    String? docName;
    if (map['doctor'] != null && map['doctor']['user'] != null) {
      docName = map['doctor']['user']['name'];
    }
    
    String? patName;
    if (map['patient'] != null) {
      patName = '${map['patient']['first_name']} ${map['patient']['last_name']}';
    }

    String? servName;
    int? servDur;
    if (map['service'] != null) {
      servName = map['service']['service_name'];
      servDur = map['service']['duration_mins'] as int?;
    }

    return Appointment(
      id: map['id'] as String,
      clinicId: map['clinic_id'] as String,
      patientId: map['patient_id'] as String,
      doctorId: map['doctor_id'] as String,
      serviceId: map['service_id'] as String,
      dateTime: DateTime.parse(map['date_time'] as String).toLocal(),
      status: map['status'] as String,
      queueCode: map['queue_code'] as String?,
      medicalNotes: map['medical_notes'] as String?,
      doctorName: docName,
      patientName: patName,
      serviceName: servName,
      serviceDurationMins: servDur,
    );
  }
}
