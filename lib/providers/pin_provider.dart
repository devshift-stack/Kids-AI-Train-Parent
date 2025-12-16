import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pin_service.dart';

/// Provider für SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Provider für PIN Service
final pinServiceProvider = Provider<PinService?>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) => PinService(prefs),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// State für PIN-Entsperrung
enum PinUnlockState {
  locked,
  unlocked,
  noPinSet,
  loading,
}

/// Provider für PIN-Unlock-Status
final pinUnlockStateProvider = StateNotifierProvider<PinUnlockNotifier, PinUnlockState>((ref) {
  final pinService = ref.watch(pinServiceProvider);
  return PinUnlockNotifier(pinService);
});

class PinUnlockNotifier extends StateNotifier<PinUnlockState> {
  final PinService? _pinService;

  PinUnlockNotifier(this._pinService) : super(PinUnlockState.loading) {
    _init();
  }

  void _init() {
    if (_pinService == null) {
      state = PinUnlockState.loading;
      return;
    }

    if (!_pinService.isPinEnabled()) {
      state = PinUnlockState.noPinSet;
    } else {
      state = PinUnlockState.locked;
    }
  }

  /// Versucht PIN zu entsperren
  Future<PinVerificationResult?> unlock(String pin) async {
    if (_pinService == null) return null;

    final result = await _pinService.verifyPin(pin);
    if (result.isSuccess) {
      state = PinUnlockState.unlocked;
    }
    return result;
  }

  /// Sperrt die App wieder
  void lock() {
    if (_pinService?.isPinEnabled() == true) {
      state = PinUnlockState.locked;
    }
  }

  /// Aktualisiert den Status nach PIN-Änderung
  void refresh() {
    _init();
  }
}

/// Provider für PIN-Konfiguration
final pinConfigProvider = StateNotifierProvider<PinConfigNotifier, AsyncValue<void>>((ref) {
  final pinService = ref.watch(pinServiceProvider);
  final unlockNotifier = ref.read(pinUnlockStateProvider.notifier);
  return PinConfigNotifier(pinService, unlockNotifier);
});

class PinConfigNotifier extends StateNotifier<AsyncValue<void>> {
  final PinService? _pinService;
  final PinUnlockNotifier _unlockNotifier;

  PinConfigNotifier(this._pinService, this._unlockNotifier) : super(const AsyncValue.data(null));

  /// Prüft ob PIN aktiviert ist
  bool get isPinEnabled => _pinService?.isPinEnabled() ?? false;

  /// Setzt neuen PIN
  Future<bool> setPin(String pin) async {
    if (_pinService == null) return false;

    state = const AsyncValue.loading();
    try {
      final success = await _pinService.setPin(pin);
      state = const AsyncValue.data(null);
      if (success) {
        _unlockNotifier.refresh();
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Ändert PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    if (_pinService == null) return false;

    state = const AsyncValue.loading();
    try {
      final success = await _pinService.changePin(oldPin, newPin);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Deaktiviert PIN
  Future<bool> disablePin(String currentPin) async {
    if (_pinService == null) return false;

    state = const AsyncValue.loading();
    try {
      final success = await _pinService.disablePin(currentPin);
      state = const AsyncValue.data(null);
      if (success) {
        _unlockNotifier.refresh();
      }
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
