import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child.dart';
import '../models/time_limit.dart';
import '../models/leaderboard_consent.dart';
import 'parent_code_service.dart';

/// Service für Kinderverwaltung
class ChildrenService {
  final FirebaseFirestore _firestore;
  final ParentCodeService _parentCodeService;

  ChildrenService({
    FirebaseFirestore? firestore,
    ParentCodeService? parentCodeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _parentCodeService = parentCodeService ?? ParentCodeService();

  /// Holt alle Kinder eines Elternteils
  Stream<List<Child>> watchChildren(String parentId) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Child.fromFirestore(doc)).toList());
  }

  /// Holt ein einzelnes Kind
  Future<Child?> getChild(String parentId, String childId) async {
    final doc = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .get();

    if (!doc.exists) return null;
    return Child.fromFirestore(doc);
  }

  /// Erstellt ein neues Kind
  Future<Child> createChild({
    required String parentId,
    required String name,
    required int age,
  }) async {
    // Generiere einzigartigen ParentCode
    final parentCode = await _parentCodeService.generateUniqueCode();

    // Erstelle Dokument-Referenz
    final docRef = _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc();

    // Erstelle Child-Objekt
    final child = Child.create(
      id: docRef.id,
      name: name,
      age: age,
      parentCode: parentCode,
    );

    // Speichere in Firestore
    await docRef.set(child.toFirestore());

    return child;
  }

  /// Aktualisiert ein Kind
  Future<void> updateChild(String parentId, Child child) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(child.id)
        .update(child.toFirestore());
  }

  /// Löscht ein Kind
  Future<void> deleteChild(String parentId, String childId) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .delete();
  }

  /// Aktualisiert Zeitlimits
  Future<void> updateTimeLimit(
    String parentId,
    String childId,
    TimeLimit timeLimit,
  ) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'timeLimit': timeLimit.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Aktualisiert Ranglisten-Einstellungen
  Future<void> updateLeaderboardConsent(
    String parentId,
    String childId,
    LeaderboardConsent consent,
  ) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'leaderboardConsent': consent.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Aktualisiert Spieleinstellungen für ein bestimmtes Spiel
  Future<void> updateGameSettings(
    String parentId,
    String childId,
    String gameId,
    GameSettings settings,
  ) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'gameSettings.$gameId': settings.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Generiert neuen ParentCode für ein Kind
  Future<String> regenerateParentCode(String parentId, String childId) async {
    return _parentCodeService.regenerateCode(
      parentId: parentId,
      childId: childId,
    );
  }

  /// Entfernt ein Gerät von einem Kind
  Future<void> unlinkDevice(
    String parentId,
    String childId,
    String deviceId,
  ) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'linkedDeviceIds': FieldValue.arrayRemove([deviceId]),
      'updatedAt': Timestamp.now(),
    });
  }
}
