import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_dental/core/models/doctor.dart';
import 'package:sistema_dental/features/dentist/presentation/widgets/dentist_calendar_view.dart';
import 'package:sistema_dental/features/shared/data/appointment_repository.dart';
import 'package:sistema_dental/features/secretary/data/billing_repository.dart';

void main() {
  group('appointmentLocalDayUtcRange', () {
    test('covers exactly the selected local calendar day', () {
      final localNow = DateTime(2026, 7, 21, 18, 30);
      final range = appointmentLocalDayUtcRange(localNow);

      expect(range.startUtc, DateTime(2026, 7, 21).toUtc());
      expect(range.endUtc, DateTime(2026, 7, 22).toUtc());
    });
  });

  group('appointment status transitions', () {
    test('accepts the clinical workflow', () {
      expect(isValidAppointmentTransition('upcoming', 'in_lobby'), isTrue);
      expect(isValidAppointmentTransition('in_lobby', 'in_treatment'), isTrue);
      expect(isValidAppointmentTransition('in_treatment', 'completed'), isTrue);
    });

    test('allows cancellation only from active states', () {
      expect(isValidAppointmentTransition('upcoming', 'cancelled'), isTrue);
      expect(isValidAppointmentTransition('in_lobby', 'cancelled'), isTrue);
      expect(isValidAppointmentTransition('in_treatment', 'cancelled'), isTrue);
      expect(isValidAppointmentTransition('completed', 'cancelled'), isFalse);
    });

    test('rejects skipped and backwards transitions', () {
      expect(isValidAppointmentTransition('upcoming', 'completed'), isFalse);
      expect(isValidAppointmentTransition('in_treatment', 'in_lobby'), isFalse);
      expect(isValidAppointmentTransition('cancelled', 'upcoming'), isFalse);
    });
  });

  group('StaffMember', () {
    test('reads inactive clinic memberships', () {
      final member = StaffMember.fromMap({
        'user_id': 'user-1',
        'clinic_id': 'clinic-1',
        'role_in_clinic': 'dentist',
        'is_active': false,
        'profiles': {'name': 'Dra. Rivera'},
        'doctors': null,
      });

      expect(member.name, 'Dra. Rivera');
      expect(member.isMembershipActive, isFalse);
    });

    test('preserves membership state when clinical details change', () {
      const member = StaffMember(
        userId: 'user-1',
        name: 'Dra. Rivera',
        roleInClinic: 'dentist',
        clinicId: 'clinic-1',
        isMembershipActive: false,
      );

      final updated = member.copyWith(specialty: 'Ortodoncia');

      expect(updated.specialty, 'Ortodoncia');
      expect(updated.isMembershipActive, isFalse);
    });
  });

  group('billing totals', () {
    test('calculates partial payments and remaining balance', () {
      final invoice = <String, dynamic>{
        'total': 100,
        'payments': [
          {'amount': 35.50, 'voided_at': null},
          {'amount': '14.50', 'voided_at': null},
        ],
      };

      expect(invoicePaidAmount(invoice), 50);
      expect(invoiceBalance(invoice), 50);
    });

    test('excludes voided payments from accounting totals', () {
      final invoice = <String, dynamic>{
        'total': 80,
        'payments': [
          {'amount': 30, 'voided_at': '2026-07-21T12:00:00Z'},
          {'amount': 20, 'voided_at': null},
        ],
      };

      expect(invoicePaidAmount(invoice), 20);
      expect(invoiceBalance(invoice), 60);
    });

    test('normalizes numeric values returned as strings', () {
      expect(billingMoney('125.40'), 125.40);
      expect(billingMoney(null), 0);
    });
  });

  group('dentist weekly calendar', () {
    test('starts every week on Monday', () {
      expect(startOfCalendarWeek(DateTime(2026, 7, 21)), DateTime(2026, 7, 20));
      expect(startOfCalendarWeek(DateTime(2026, 7, 26)), DateTime(2026, 7, 20));
    });

    test('translates appointment states', () {
      expect(calendarAppointmentStatusLabel('in_lobby'), 'En espera');
      expect(calendarAppointmentStatusLabel('completed'), 'Completada');
    });
  });

  group('appointment slot validation', () {
    test('detects overlaps but allows adjacent appointments', () {
      final firstStart = DateTime(2026, 7, 22, 10);
      final firstEnd = DateTime(2026, 7, 22, 10, 30);

      expect(
        appointmentSlotsOverlap(
          firstStart: firstStart,
          firstEnd: firstEnd,
          secondStart: DateTime(2026, 7, 22, 10, 15),
          secondEnd: DateTime(2026, 7, 22, 10, 45),
        ),
        isTrue,
      );
      expect(
        appointmentSlotsOverlap(
          firstStart: firstStart,
          firstEnd: firstEnd,
          secondStart: firstEnd,
          secondEnd: DateTime(2026, 7, 22, 11),
        ),
        isFalse,
      );
    });

    test('requires the full service to fit inside working hours', () {
      expect(
        appointmentFitsWorkingHours(
          localStart: DateTime(2026, 7, 22, 16, 30),
          durationMinutes: 30,
          workStart: '08:00',
          workEnd: '17:00',
        ),
        isTrue,
      );
      expect(
        appointmentFitsWorkingHours(
          localStart: DateTime(2026, 7, 22, 16, 45),
          durationMinutes: 30,
          workStart: '08:00',
          workEnd: '17:00',
        ),
        isFalse,
      );
    });
  });
}
