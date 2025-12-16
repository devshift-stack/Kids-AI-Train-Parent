import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service für PIN-Schutz des Eltern-Dashboards
///
/// - 4-stelliger PIN
/// - Max 5 Fehlversuche, dann 15 Min Sperre
/// - PIN wird als Hash gespeichert
class PinService {
  static const String _pinHashKey = 'parent_pin_hash';
  static const String _failedAttemptsKey = 'pin_failed_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';
  static const String _pinEnabledKey = 'pin_enabled';

  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  final SharedPreferences _prefs;

  PinService(this._prefs);

  /// Prüft ob PIN aktiviert ist
  bool isPinEnabled() {
    return _prefs.getBool(_pinEnabledKey) ?? false;
  }

  /// Prüft ob aktuell gesperrt wegen zu vieler Fehlversuche
  bool isLockedOut() {
    final lockoutUntilMs = _prefs.getInt(_lockoutUntilKey);
    if (lockoutUntilMs == null) return false;

    final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs);
    if (DateTime.now().isBefore(lockoutUntil)) {
      return true;
    }

    // Sperre abgelaufen, zurücksetzen
    _resetFailedAttempts();
    return false;
  }

  /// Gibt verbleibende Sperrzeit in Sekunden zurück
  int getRemainingLockoutSeconds() {
    final lockoutUntilMs = _prefs.getInt(_lockoutUntilKey);
    if (lockoutUntilMs == null) return 0;

    final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs);
    final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Gibt Anzahl verbleibender Versuche zurück
  int getRemainingAttempts() {
    final failed = _prefs.getInt(_failedAttemptsKey) ?? 0;
    return _maxFailedAttempts - failed;
  }

  /// Setzt einen neuen PIN
  Future<bool> setPin(String pin) async {
    if (!_isValidPinFormat(pin)) {
      return false;
    }

    final hash = _hashPin(pin);
    await _prefs.setString(_pinHashKey, hash);
    await _prefs.setBool(_pinEnabledKey, true);
    await _resetFailedAttempts();
    return true;
  }

  /// Verifiziert den PIN
  Future<PinVerificationResult> verifyPin(String pin) async {
    if (isLockedOut()) {
      return PinVerificationResult.lockedOut(getRemainingLockoutSeconds());
    }

    final storedHash = _prefs.getString(_pinHashKey);
    if (storedHash == null) {
      return PinVerificationResult.noPinSet();
    }

    final inputHash = _hashPin(pin);

    if (inputHash == storedHash) {
      await _resetFailedAttempts();
      return PinVerificationResult.success();
    }

    // Fehlversuch zählen
    final failedAttempts = (_prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
    await _prefs.setInt(_failedAttemptsKey, failedAttempts);

    if (failedAttempts >= _maxFailedAttempts) {
      // Sperre aktivieren
      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      await _prefs.setInt(_lockoutUntilKey, lockoutUntil.millisecondsSinceEpoch);
      return PinVerificationResult.lockedOut(_lockoutDuration.inSeconds);
    }

    return PinVerificationResult.wrongPin(_maxFailedAttempts - failedAttempts);
  }

  /// Ändert den PIN (benötigt alten PIN)
  Future<bool> changePin(String oldPin, String newPin) async {
    final result = await verifyPin(oldPin);
    if (!result.isSuccess) {
      return false;
    }

    return setPin(newPin);
  }

  /// Deaktiviert den PIN (benötigt aktuellen PIN)
  Future<bool> disablePin(String currentPin) async {
    final result = await verifyPin(currentPin);
    if (!result.isSuccess) {
      return false;
    }

    await _prefs.remove(_pinHashKey);
    await _prefs.setBool(_pinEnabledKey, false);
    await _resetFailedAttempts();
    return true;
  }

  /// Setzt Fehlversuche zurück
  Future<void> _resetFailedAttempts() async {
    await _prefs.remove(_failedAttemptsKey);
    await _prefs.remove(_lockoutUntilKey);
  }

  /// Hasht den PIN mit SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Prüft PIN-Format (4 Ziffern)
  bool _isValidPinFormat(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }
}

/// Ergebnis der PIN-Verifizierung
class PinVerificationResult {
  final bool isSuccess;
  final PinError? error;
  final int? remainingAttempts;
  final int? lockoutSeconds;

  PinVerificationResult._({
    required this.isSuccess,
    this.error,
    this.remainingAttempts,
    this.lockoutSeconds,
  });

  factory PinVerificationResult.success() {
    return PinVerificationResult._(isSuccess: true);
  }

  factory PinVerificationResult.wrongPin(int remainingAttempts) {
    return PinVerificationResult._(
      isSuccess: false,
      error: PinError.wrongPin,
      remainingAttempts: remainingAttempts,
    );
  }

  factory PinVerificationResult.lockedOut(int seconds) {
    return PinVerificationResult._(
      isSuccess: false,
      error: PinError.lockedOut,
      lockoutSeconds: seconds,
    );
  }

  factory PinVerificationResult.noPinSet() {
    return PinVerificationResult._(
      isSuccess: false,
      error: PinError.noPinSet,
    );
  }
}

enum PinError {
  wrongPin,
  lockedOut,
  noPinSet,
}
