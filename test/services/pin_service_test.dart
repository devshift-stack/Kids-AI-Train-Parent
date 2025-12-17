import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kids_ai_parent/services/pin_service.dart';

void main() {
  group('PinService', () {
    late SharedPreferences prefs;
    late PinService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = PinService(prefs);
    });

    group('isPinEnabled', () {
      test('gibt false wenn kein PIN gesetzt', () {
        expect(service.isPinEnabled(), isFalse);
      });

      test('gibt true nach setPin', () async {
        await service.setPin('1234');

        expect(service.isPinEnabled(), isTrue);
      });
    });

    group('setPin', () {
      test('akzeptiert 4 Ziffern', () async {
        final result = await service.setPin('1234');

        expect(result, isTrue);
        expect(service.isPinEnabled(), isTrue);
      });

      test('akzeptiert 0000', () async {
        final result = await service.setPin('0000');

        expect(result, isTrue);
      });

      test('lehnt zu kurzen PIN ab', () async {
        final result = await service.setPin('123');

        expect(result, isFalse);
        expect(service.isPinEnabled(), isFalse);
      });

      test('lehnt zu langen PIN ab', () async {
        final result = await service.setPin('12345');

        expect(result, isFalse);
      });

      test('lehnt Buchstaben ab', () async {
        final result = await service.setPin('abcd');

        expect(result, isFalse);
      });

      test('lehnt gemischte Zeichen ab', () async {
        final result = await service.setPin('12ab');

        expect(result, isFalse);
      });

      test('lehnt leeren String ab', () async {
        final result = await service.setPin('');

        expect(result, isFalse);
      });
    });

    group('verifyPin', () {
      setUp(() async {
        await service.setPin('1234');
      });

      test('gibt success bei korrektem PIN', () async {
        final result = await service.verifyPin('1234');

        expect(result.isSuccess, isTrue);
        expect(result.error, isNull);
      });

      test('gibt wrongPin bei falschem PIN', () async {
        final result = await service.verifyPin('0000');

        expect(result.isSuccess, isFalse);
        expect(result.error, equals(PinError.wrongPin));
        expect(result.remainingAttempts, equals(4));
      });

      test('zaehlt Fehlversuche', () async {
        await service.verifyPin('0000'); // 1. Fehlversuch
        final result = await service.verifyPin('0000'); // 2. Fehlversuch

        expect(result.remainingAttempts, equals(3));
      });

      test('sperrt nach 5 Fehlversuchen', () async {
        for (int i = 0; i < 5; i++) {
          await service.verifyPin('0000');
        }

        final result = await service.verifyPin('0000');

        expect(result.isSuccess, isFalse);
        expect(result.error, equals(PinError.lockedOut));
        expect(result.lockoutSeconds, isNotNull);
      });

      test('setzt Fehlversuche nach Erfolg zurueck', () async {
        await service.verifyPin('0000'); // 1. Fehlversuch
        await service.verifyPin('0000'); // 2. Fehlversuch
        await service.verifyPin('1234'); // Erfolg

        expect(service.getRemainingAttempts(), equals(5));
      });
    });

    group('verifyPin ohne PIN', () {
      test('gibt noPinSet wenn kein PIN gesetzt', () async {
        final result = await service.verifyPin('1234');

        expect(result.isSuccess, isFalse);
        expect(result.error, equals(PinError.noPinSet));
      });
    });

    group('isLockedOut', () {
      setUp(() async {
        await service.setPin('1234');
      });

      test('gibt false initial', () {
        expect(service.isLockedOut(), isFalse);
      });

      test('gibt true nach 5 Fehlversuchen', () async {
        for (int i = 0; i < 5; i++) {
          await service.verifyPin('0000');
        }

        expect(service.isLockedOut(), isTrue);
      });
    });

    group('getRemainingAttempts', () {
      setUp(() async {
        await service.setPin('1234');
      });

      test('gibt 5 initial', () {
        expect(service.getRemainingAttempts(), equals(5));
      });

      test('reduziert sich nach Fehlversuchen', () async {
        await service.verifyPin('0000');

        expect(service.getRemainingAttempts(), equals(4));
      });
    });

    group('getRemainingLockoutSeconds', () {
      setUp(() async {
        await service.setPin('1234');
      });

      test('gibt 0 wenn nicht gesperrt', () {
        expect(service.getRemainingLockoutSeconds(), equals(0));
      });
    });

    group('changePin', () {
      setUp(() async {
        await service.setPin('1234');
      });

      test('aendert PIN mit korrektem alten PIN', () async {
        final result = await service.changePin('1234', '5678');

        expect(result, isTrue);

        final verify = await service.verifyPin('5678');
        expect(verify.isSuccess, isTrue);
      });

      test('lehnt ab mit falschem alten PIN', () async {
        final result = await service.changePin('0000', '5678');

        expect(result, isFalse);
      });

      test('lehnt ungültigen neuen PIN ab', () async {
        final result = await service.changePin('1234', '12'); // Zu kurz

        expect(result, isFalse);
      });
    });

    group('disablePin', () {
      setUp(() async {
        await service.setPin('1234');
      });

      test('deaktiviert PIN mit korrektem PIN', () async {
        final result = await service.disablePin('1234');

        expect(result, isTrue);
        expect(service.isPinEnabled(), isFalse);
      });

      test('lehnt ab mit falschem PIN', () async {
        final result = await service.disablePin('0000');

        expect(result, isFalse);
        expect(service.isPinEnabled(), isTrue);
      });
    });
  });

  group('PinVerificationResult', () {
    test('success() hat isSuccess true', () {
      final result = PinVerificationResult.success();

      expect(result.isSuccess, isTrue);
      expect(result.error, isNull);
    });

    test('wrongPin() hat korrekten Error', () {
      final result = PinVerificationResult.wrongPin(3);

      expect(result.isSuccess, isFalse);
      expect(result.error, equals(PinError.wrongPin));
      expect(result.remainingAttempts, equals(3));
    });

    test('lockedOut() hat korrekten Error', () {
      final result = PinVerificationResult.lockedOut(900);

      expect(result.isSuccess, isFalse);
      expect(result.error, equals(PinError.lockedOut));
      expect(result.lockoutSeconds, equals(900));
    });

    test('noPinSet() hat korrekten Error', () {
      final result = PinVerificationResult.noPinSet();

      expect(result.isSuccess, isFalse);
      expect(result.error, equals(PinError.noPinSet));
    });
  });
}
