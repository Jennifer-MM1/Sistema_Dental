/// Modelo que representa a un doctor/secretaria dentro de la clínica,
/// incluyendo su consultorio asignado, disponibilidad y datos del perfil.
class StaffMember {
  final String userId;
  final String name;
  final String roleInClinic; // 'owner', 'dentist', 'secretary'
  final String clinicId;
  final String? specialty;
  final String? cabinAssigned;
  final bool isAvailable;
  final String? doctorRecordId; // id en tabla doctors (puede ser null para secretaria)

  const StaffMember({
    required this.userId,
    required this.name,
    required this.roleInClinic,
    required this.clinicId,
    this.specialty,
    this.cabinAssigned,
    this.isAvailable = true,
    this.doctorRecordId,
  });

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final doctor = map['doctors'] as Map<String, dynamic>?;
    return StaffMember(
      userId: map['user_id'] as String,
      name: profile?['name'] as String? ?? 'Desconocido',
      roleInClinic: map['role_in_clinic'] as String,
      clinicId: map['clinic_id'] as String,
      specialty: doctor?['specialty'] as String?,
      cabinAssigned: doctor?['cabin_assigned'] as String?,
      isAvailable: doctor?['is_available'] as bool? ?? true,
      doctorRecordId: doctor?['id'] as String?,
    );
  }

  StaffMember copyWith({
    String? specialty,
    String? cabinAssigned,
    bool? isAvailable,
  }) {
    return StaffMember(
      userId: userId,
      name: name,
      roleInClinic: roleInClinic,
      clinicId: clinicId,
      specialty: specialty ?? this.specialty,
      cabinAssigned: cabinAssigned ?? this.cabinAssigned,
      isAvailable: isAvailable ?? this.isAvailable,
      doctorRecordId: doctorRecordId,
    );
  }

  /// Devuelve true si el miembro tiene registro en la tabla doctors
  bool get hasDocRecord => doctorRecordId != null;

  /// Etiqueta legible del rol
  String get roleLabel {
    switch (roleInClinic) {
      case 'owner':
        return 'Dentista Principal (Dueño)';
      case 'dentist':
        return 'Dentista';
      case 'secretary':
        return 'Secretaria / Recepción';
      default:
        return roleInClinic;
    }
  }
}

/// Horario de un día de la semana para un doctor.
class DoctorDaySchedule {
  final String? id; // null si aún no se ha guardado en BD
  final int dayOfWeek; // 0=Dom, 1=Lun, ... 6=Sáb
  bool isWorkingDay;
  String startTime; // formato "HH:MM"
  String endTime;   // formato "HH:MM"

  DoctorDaySchedule({
    this.id,
    required this.dayOfWeek,
    this.isWorkingDay = true,
    this.startTime = '08:00',
    this.endTime = '17:00',
  });

  factory DoctorDaySchedule.fromMap(Map<String, dynamic> map) {
    return DoctorDaySchedule(
      id: map['id'] as String?,
      dayOfWeek: map['day_of_week'] as int,
      isWorkingDay: map['is_working_day'] as bool? ?? true,
      startTime: (map['start_time'] as String?)?.substring(0, 5) ?? '08:00',
      endTime: (map['end_time'] as String?)?.substring(0, 5) ?? '17:00',
    );
  }

  Map<String, dynamic> toMap(String doctorUserId, String clinicId) {
    return {
      'doctor_user_id': doctorUserId,
      'clinic_id': clinicId,
      'day_of_week': dayOfWeek,
      'is_working_day': isWorkingDay,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  String get dayName {
    const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return days[dayOfWeek];
  }

  String get dayShort {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return days[dayOfWeek];
  }
}

/// Registro de un día libre / ausencia de un doctor.
class DoctorDayOff {
  final String? id;
  final String doctorUserId;
  final String clinicId;
  final DateTime date;
  final String? reason;

  const DoctorDayOff({
    this.id,
    required this.doctorUserId,
    required this.clinicId,
    required this.date,
    this.reason,
  });

  factory DoctorDayOff.fromMap(Map<String, dynamic> map) {
    return DoctorDayOff(
      id: map['id'] as String?,
      doctorUserId: map['doctor_user_id'] as String,
      clinicId: map['clinic_id'] as String,
      date: DateTime.parse(map['date'] as String),
      reason: map['reason'] as String?,
    );
  }
}
