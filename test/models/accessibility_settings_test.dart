import 'package:flutter_test/flutter_test.dart';
import 'package:kids_ai_parent/models/accessibility_settings.dart';

void main() {
  group('AccessibilitySettings', () {
    group('Defaults', () {
      test('subtitlesEnabled ist false per Default', () {
        const settings = AccessibilitySettings();

        expect(settings.subtitlesEnabled, isFalse);
      });

      test('subtitleLanguage ist de per Default', () {
        const settings = AccessibilitySettings();

        expect(settings.subtitleLanguage, equals('de'));
      });
    });

    group('fromMap/toMap Roundtrip', () {
      test('erhaelt alle Daten bei Roundtrip', () {
        const original = AccessibilitySettings(
          subtitlesEnabled: true,
          subtitleLanguage: 'en',
        );

        final map = original.toMap();
        final restored = AccessibilitySettings.fromMap(map);

        expect(restored.subtitlesEnabled, equals(original.subtitlesEnabled));
        expect(restored.subtitleLanguage, equals(original.subtitleLanguage));
      });

      test('handled fehlende Felder mit Defaults', () {
        final restored = AccessibilitySettings.fromMap({});

        expect(restored.subtitlesEnabled, isFalse);
        expect(restored.subtitleLanguage, equals('de'));
      });
    });

    group('copyWith', () {
      test('aendert nur angegebene Felder', () {
        const original = AccessibilitySettings(
          subtitlesEnabled: false,
          subtitleLanguage: 'de',
        );

        final updated = original.copyWith(subtitlesEnabled: true);

        expect(updated.subtitlesEnabled, isTrue);
        expect(updated.subtitleLanguage, equals('de'));
      });

      test('kann Sprache aendern', () {
        const original = AccessibilitySettings();
        final updated = original.copyWith(subtitleLanguage: 'bs');

        expect(updated.subtitleLanguage, equals('bs'));
      });
    });

    group('currentLanguageName', () {
      test('gibt Deutsch fuer de', () {
        const settings = AccessibilitySettings(subtitleLanguage: 'de');

        expect(settings.currentLanguageName, equals('Deutsch'));
      });

      test('gibt Englisch fuer en', () {
        const settings = AccessibilitySettings(subtitleLanguage: 'en');

        expect(settings.currentLanguageName, equals('Englisch'));
      });

      test('gibt Bosnisch fuer bs', () {
        const settings = AccessibilitySettings(subtitleLanguage: 'bs');

        expect(settings.currentLanguageName, equals('Bosnisch'));
      });

      test('gibt Kroatisch fuer hr', () {
        const settings = AccessibilitySettings(subtitleLanguage: 'hr');

        expect(settings.currentLanguageName, equals('Kroatisch'));
      });

      test('gibt Serbisch fuer sr', () {
        const settings = AccessibilitySettings(subtitleLanguage: 'sr');

        expect(settings.currentLanguageName, equals('Serbisch'));
      });

      test('gibt Tuerkisch fuer tr', () {
        const settings = AccessibilitySettings(subtitleLanguage: 'tr');

        expect(settings.currentLanguageName, equals('Türkisch'));
      });

      test('gibt ersten verfuegbaren Namen fuer unbekannte Sprache', () {
        const settings = AccessibilitySettings(subtitleLanguage: 'fr');

        expect(settings.currentLanguageName, equals('Deutsch'));
      });
    });

    group('Equatable', () {
      test('zwei Settings mit gleichen Daten sind equal', () {
        const settings1 = AccessibilitySettings(
          subtitlesEnabled: true,
          subtitleLanguage: 'en',
        );
        const settings2 = AccessibilitySettings(
          subtitlesEnabled: true,
          subtitleLanguage: 'en',
        );

        expect(settings1, equals(settings2));
      });

      test('zwei Settings mit unterschiedlichen Daten sind nicht equal', () {
        const settings1 = AccessibilitySettings(subtitlesEnabled: true);
        const settings2 = AccessibilitySettings(subtitlesEnabled: false);

        expect(settings1, isNot(equals(settings2)));
      });
    });
  });

  group('SubtitleLanguage', () {
    test('hat alle erwarteten Sprachen', () {
      final codes = AccessibilitySettings.availableLanguages
          .map((l) => l.code)
          .toList();

      expect(codes.contains('de'), isTrue);
      expect(codes.contains('en'), isTrue);
      expect(codes.contains('bs'), isTrue);
      expect(codes.contains('hr'), isTrue);
      expect(codes.contains('sr'), isTrue);
      expect(codes.contains('tr'), isTrue);
    });

    test('hat 6 verfuegbare Sprachen', () {
      expect(AccessibilitySettings.availableLanguages.length, equals(6));
    });

    test('alle Sprachen haben code, name und nativeName', () {
      for (final lang in AccessibilitySettings.availableLanguages) {
        expect(lang.code, isNotEmpty);
        expect(lang.name, isNotEmpty);
        expect(lang.nativeName, isNotEmpty);
      }
    });
  });
}
