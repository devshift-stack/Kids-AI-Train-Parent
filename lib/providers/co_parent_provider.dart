import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/co_parent_service.dart';
import 'auth_provider.dart';

/// Provider für CoParent Service
final coParentServiceProvider = Provider<CoParentService>((ref) {
  return CoParentService();
});

/// Provider für verknüpfte CoParents
final coParentsProvider = FutureProvider<List<CoParentInfo>>((ref) async {
  final parentId = ref.watch(parentIdProvider);
  if (parentId == null) return [];

  final service = ref.watch(coParentServiceProvider);
  return service.getCoParents(parentId);
});

/// Provider für aktuellen Einladungscode
final currentInviteCodeProvider = FutureProvider<CoParentInviteInfo?>((ref) async {
  final parentId = ref.watch(parentIdProvider);
  if (parentId == null) return null;

  final service = ref.watch(coParentServiceProvider);
  return service.getCurrentInviteCode(parentId);
});

/// Notifier für CoParent-Aktionen
class CoParentNotifier extends StateNotifier<AsyncValue<void>> {
  final CoParentService _service;
  final String? _parentId;
  final Ref _ref;

  CoParentNotifier(this._service, this._parentId, this._ref)
      : super(const AsyncValue.data(null));

  /// Generiert neuen Einladungscode
  Future<String?> generateInviteCode() async {
    if (_parentId == null) return null;

    state = const AsyncValue.loading();
    try {
      final code = await _service.generateInviteCode(_parentId);
      state = const AsyncValue.data(null);
      _ref.invalidate(currentInviteCodeProvider);
      return code;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Validiert und verknüpft mit Einladungscode
  Future<CoParentValidationResult?> joinWithCode(String code) async {
    if (_parentId == null) return null;

    state = const AsyncValue.loading();
    try {
      final result = await _service.validateCode(code, _parentId);

      if (result.isValid && result.targetParentId != null) {
        await _service.linkCoParents(result.targetParentId!, _parentId);
        _ref.invalidate(coParentsProvider);
      }

      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Entfernt CoParent-Verknüpfung
  Future<bool> unlinkCoParent(String coParentId) async {
    if (_parentId == null) return false;

    state = const AsyncValue.loading();
    try {
      await _service.unlinkCoParent(_parentId, coParentId);
      _ref.invalidate(coParentsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider für CoParent Notifier
final coParentNotifierProvider =
    StateNotifierProvider<CoParentNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(coParentServiceProvider);
  final parentId = ref.watch(parentIdProvider);
  return CoParentNotifier(service, parentId, ref);
});
