import 'package:flutter_test/flutter_test.dart';
import 'package:kids_ai_parent/models/time_limit.dart';

void main() {
  group('TimeLimit', () {
    group('defaultLimit', () {
      test('hat korrekte Default-Werte', () {
        final limit = TimeLimit.defaultLimit();

        expect(limit.dailyMinutes, equals(60));
        expect(limit.breakIntervalMinutes, equals(30));
        expect(limit.breakDurationMinutes, equals(5));
        expect(limit.bedtimeEnabled, isTrue);
      });

      test('bedtimeStart ist 20:00', () {
        final limit = TimeLimit.defaultLimit();

        expect(limit.bedtimeStart.hour, equals(20));
        expect(limit.bedtimeStart.minute, equals(0));
      });

      test('bedtimeEnd ist 07:00', () {
        final limit = TimeLimit.defaultLimit();

        expect(limit.bedtimeEnd.hour, equals(7));
        expect(limit.bedtimeEnd.minute, equals(0));
      });
    });

    group('fromMap/toMap Roundtrip', () {
      test('erhaelt alle Daten bei Roundtrip', () {
        final original = const TimeLimit(
          dailyMinutes: 90,
          breakIntervalMinutes: 45,
          breakDurationMinutes: 10,
          bedtimeStart: TimeOfDay(hour: 21, minute: 30),
          bedtimeEnd: TimeOfDay(hour: 6, minute: 30),
          bedtimeEnabled: false,
          weekdayLimits: {1: 60, 6: 120, 7: 120},
        );

        final map = original.toMap();
        final restored = TimeLimit.fromMap(map);

        expect(restored.dailyMinutes, equals(original.dailyMinutes));
        expect(restored.breakIntervalMinutes, equals(original.breakIntervalMinutes));
        expect(restored.bedtimeEnabled, equals(original.bedtimeEnabled));
        expect(restored.bedtimeStart.hour, equals(original.bedtimeStart.hour));
        expect(restored.weekdayLimits[6], equals(120));
      });

      test('handled fehlende Felder mit Defaults', () {
        final restored = TimeLimit.fromMap({});

        expect(restored.dailyMinutes, equals(60));
        expect(restored.breakIntervalMinutes, equals(30));
        expect(restored.bedtimeEnabled, isTrue);
      });
    });

    group('isCurrentlyBedtime', () {
      test('gibt false wenn bedtimeEnabled false', () {
        final limit = const TimeLimit(
          bedtimeStart: TimeOfDay(hour: 20, minute: 0),
          bedtimeEnd: TimeOfDay(hour: 7, minute: 0),
          bedtimeEnabled: false,
        );

        expect(limit.isCurrentlyBedtime(), isFalse);
      });

      // Note: Time-based tests sind schwer zu testen ohne Clock-Mocking
      // Diese Tests demonstrieren die Logik aber sind zeitabhaengig
    });

    group('getLimitForDay', () {
      test('gibt weekdayLimit wenn gesetzt', () {
        final limit = const TimeLimit(
          dailyMinutes: 60,
          weekdayLimits: {6: 120, 7: 120}, // Wochenende mehr Zeit
        );

        expect(limit.getLimitForDay(6), equals(120)); // Samstag
        expect(limit.getLimitForDay(7), equals(120)); // Sonntag
      });

      test('gibt dailyMinutes als Fallback', () {
        final limit = const TimeLimit(
          dailyMinutes: 60,
          weekdayLimits: {6: 120, 7: 120},
        );

        expect(limit.getLimitForDay(1), equals(60)); // Montag - kein special limit
        expect(limit.getLimitForDay(3), equals(60)); // Mittwoch
      });

      test('handled leere weekdayLimits', () {
        final limit = const TimeLimit(
          dailyMinutes: 45,
          weekdayLimits: {},
        );

        expect(limit.getLimitForDay(1), equals(45));
        expect(limit.getLimitForDay(7), equals(45));
      });
    });

    group('copyWith', () {
      test('aendert nur angegebene Felder', () {
        final original = TimeLimit.defaultLimit();
        final updated = original.copyWith(dailyMinutes: 90);

        expect(updated.dailyMinutes, equals(90));
        expect(updated.breakIntervalMinutes, equals(original.breakIntervalMinutes));
        expect(updated.bedtimeEnabled, equals(original.bedtimeEnabled));
      });
    });

    group('Equatable', () {
      test('zwei TimeLimits mit gleichen Daten sind equal', () {
        final limit1 = TimeLimit.defaultLimit();
        final limit2 = TimeLimit.defaultLimit();

        expect(limit1, equals(limit2));
      });
    });
  });

  group('TimeOfDay', () {
    group('format', () {
      test('formatiert einstellige Stunden mit fuehrender Null', () {
        const time = TimeOfDay(hour: 8, minute: 30);

        expect(time.format(), equals('08:30'));
      });

      test('formatiert einstellige Minuten mit fuehrender Null', () {
        const time = TimeOfDay(hour: 20, minute: 5);

        expect(time.format(), equals('20:05'));
      });

      test('formatiert zweistellige Werte korrekt', () {
        const time = TimeOfDay(hour: 15, minute: 45);

        expect(time.format(), equals('15:45'));
      });

      test('formatiert Mitternacht korrekt', () {
        const time = TimeOfDay(hour: 0, minute: 0);

        expect(time.format(), equals('00:00'));
      });

      test('formatiert 23:59 korrekt', () {
        const time = TimeOfDay(hour: 23, minute: 59);

        expect(time.format(), equals('23:59'));
      });
    });

    group('Equatable', () {
      test('zwei TimeOfDays mit gleichen Werten sind equal', () {
        const time1 = TimeOfDay(hour: 20, minute: 30);
        const time2 = TimeOfDay(hour: 20, minute: 30);

        expect(time1, equals(time2));
      });

      test('zwei TimeOfDays mit unterschiedlichen Werten sind nicht equal', () {
        const time1 = TimeOfDay(hour: 20, minute: 30);
        const time2 = TimeOfDay(hour: 20, minute: 31);

        expect(time1, isNot(equals(time2)));
      });
    });
  });
}
