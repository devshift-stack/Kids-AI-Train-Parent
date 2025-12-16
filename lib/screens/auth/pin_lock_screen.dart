import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pin_provider.dart';
import '../../services/pin_service.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final List<String> _enteredDigits = [];
  String? _errorMessage;
  int? _remainingAttempts;
  bool _isLockedOut = false;
  int _lockoutSeconds = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              const Text(
                'PIN eingeben',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gib deinen 4-stelligen PIN ein',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha:0.6),
                ),
              ),
              const SizedBox(height: 48),
              _buildPinDots(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ],
              if (_remainingAttempts != null && _remainingAttempts! > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Noch $_remainingAttempts Versuche',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_isLockedOut) ...[
                const SizedBox(height: 8),
                Text(
                  'Gesperrt für $_lockoutSeconds Sekunden',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _enteredDigits.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Colors.white : Colors.transparent,
            border: Border.all(
              color: Colors.white.withValues(alpha:0.5),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildKeypadRow(['', '0', 'del']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    if (key.isEmpty) {
      return const SizedBox(width: 80, height: 80);
    }

    final isDelete = key == 'del';

    return GestureDetector(
      onTap: _isLockedOut ? null : () => _onKeyTap(key),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha:_isLockedOut ? 0.05 : 0.1),
        ),
        child: Center(
          child: isDelete
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.white.withValues(alpha:_isLockedOut ? 0.3 : 0.8),
                  size: 24,
                )
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha:_isLockedOut ? 0.3 : 1),
                  ),
                ),
        ),
      ),
    );
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();

    setState(() {
      _errorMessage = null;
    });

    if (key == 'del') {
      if (_enteredDigits.isNotEmpty) {
        setState(() {
          _enteredDigits.removeLast();
        });
      }
    } else {
      if (_enteredDigits.length < 4) {
        setState(() {
          _enteredDigits.add(key);
        });

        if (_enteredDigits.length == 4) {
          _verifyPin();
        }
      }
    }
  }

  Future<void> _verifyPin() async {
    final pin = _enteredDigits.join();
    final unlockNotifier = ref.read(pinUnlockStateProvider.notifier);
    final result = await unlockNotifier.unlock(pin);

    if (result == null) return;

    if (!result.isSuccess) {
      HapticFeedback.heavyImpact();

      setState(() {
        _enteredDigits.clear();
        _remainingAttempts = result.remainingAttempts;

        if (result.error == PinError.lockedOut) {
          _isLockedOut = true;
          _lockoutSeconds = result.lockoutSeconds ?? 0;
          _errorMessage = 'Zu viele Fehlversuche';
          _startLockoutTimer();
        } else {
          _errorMessage = 'Falscher PIN';
        }
      });
    }
  }

  void _startLockoutTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _lockoutSeconds > 0) {
        setState(() {
          _lockoutSeconds--;
          if (_lockoutSeconds == 0) {
            _isLockedOut = false;
            _errorMessage = null;
            _remainingAttempts = null;
          }
        });
        if (_lockoutSeconds > 0) {
          _startLockoutTimer();
        }
      }
    });
  }
}
