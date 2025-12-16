import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child.dart';
import '../models/time_limit.dart';
import '../models/leaderboard_consent.dart';
import '../services/children_service.dart';
import 'auth_provider.dart';

/// Provider für Children Service
final childrenServiceProvider = Provider<ChildrenService>((ref) {
  return ChildrenService();
});

/// Provider für alle Kinder des aktuellen Parents
final childrenProvider = StreamProvider<List<Child>>((ref) {
  final parentId = ref.watch(parentIdProvider);
  if (parentId == null) {
    return Stream.value([]);
  }

  final service = ref.watch(childrenServiceProvider);
  return service.watchChildren(parentId);
});

/// Provider für ausgewähltes Kind
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

/// Provider für das ausgewählte Kind (Daten)
final selectedChildProvider = Provider<Child?>((ref) {
  final selectedId = ref.watch(selectedChildIdProvider);
  if (selectedId == null) return null;

  final children = ref.watch(childrenProvider);
  return children.when(
    data: (list) => list.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => list.isNotEmpty ? list.first : throw Exception('No children'),
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Notifier für Kinder-Aktionen
class ChildrenNotifier extends StateNotifier<AsyncValue<void>> {
  final ChildrenService _service;
  final String? _parentId;

  ChildrenNotifier(this._service, this._parentId) : super(const AsyncValue.data(null));

  /// Erstellt ein neues Kind
  Future<Child?> createChild(String name, int age) async {
    if (_parentId == null) return null;

    state = const AsyncValue.loading();
    try {
      final child = await _service.createChild(
        parentId: _parentId,
        name: name,
        age: age,
      );
      state = const AsyncValue.data(null);
      return child;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Aktualisiert ein Kind
  Future<bool> updateChild(Child child) async {
    if (_parentId == null) return false;

    state = const AsyncValue.loading();
    try {
      await _service.updateChild(_parentId, child);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Löscht ein Kind
  Future<bool> deleteChild(String childId) async {
    if (_parentId == null) return false;

    state = const AsyncValue.loading();
    try {
      await _service.deleteChild(_parentId, childId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Aktualisiert Zeitlimits
  Future<bool> updateTimeLimit(String childId, TimeLimit timeLimit) async {
    if (_parentId == null) return false;

    try {
      await _service.updateTimeLimit(_parentId, childId, timeLimit);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Aktualisiert Ranglisten-Consent
  Future<bool> updateLeaderboardConsent(String childId, LeaderboardConsent consent) async {
    if (_parentId == null) return false;

    try {
      await _service.updateLeaderboardConsent(_parentId, childId, consent);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Aktualisiert Spieleinstellungen
  Future<bool> updateGameSettings(String childId, String gameId, GameSettings settings) async {
    if (_parentId == null) return false;

    try {
      await _service.updateGameSettings(_parentId, childId, gameId, settings);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generiert neuen ParentCode
  Future<String?> regenerateParentCode(String childId) async {
    if (_parentId == null) return null;

    try {
      return await _service.regenerateParentCode(_parentId, childId);
    } catch (e) {
      return null;
    }
  }
}

/// Provider für Children Notifier
final childrenNotifierProvider = StateNotifierProvider<ChildrenNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(childrenServiceProvider);
  final parentId = ref.watch(parentIdProvider);
  return ChildrenNotifier(service, parentId);
});
