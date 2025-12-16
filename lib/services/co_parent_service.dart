import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service für Elternteil-Einladung
///
/// Ablauf:
/// 1. Vater erstellt Code in Einstellungen
/// 2. Mutter gibt Code in ihrem Dashboard ein
/// 3. Beide sehen gleiche Kinder + Einstellungen
/// 4. Echtzeit-Sync
class CoParentService {
  final FirebaseFirestore _firestore;

  // Gleiches Alphabet wie ParentCode (ohne 0,O,1,I,l)
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static const Duration _codeValidity = Duration(days: 7);

  CoParentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generiert einen neuen Elternteil-Einladungscode
  Future<String> generateInviteCode(String parentId) async {
    final code = _generateCode();
    final expiresAt = DateTime.now().add(_codeValidity);

    await _firestore.collection('parents').doc(parentId).update({
      'coParentCode': code,
      'coParentCodeExpiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': Timestamp.now(),
    });

    return code;
  }

  /// Generiert zufälligen 6-stelligen Code
  String _generateCode() {
    final random = Random.secure();
    final buffer = StringBuffer();

    for (int i = 0; i < _codeLength; i++) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }

    return buffer.toString();
  }

  /// Validiert einen Einladungscode und gibt Parent-ID zurück
  Future<CoParentValidationResult> validateCode(String code, String myParentId) async {
    final normalizedCode = code.toUpperCase().replaceAll(' ', '');

    // Suche Parent mit diesem Code
    final query = await _firestore
        .collection('parents')
        .where('coParentCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return CoParentValidationResult.invalid('Code nicht gefunden');
    }

    final doc = query.docs.first;
    final data = doc.data();

    // Nicht sich selbst einladen
    if (doc.id == myParentId) {
      return CoParentValidationResult.invalid('Das ist dein eigener Code');
    }

    // Prüfe Ablaufdatum
    final expiresAt = (data['coParentCodeExpiresAt'] as Timestamp?)?.toDate();
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      return CoParentValidationResult.expired('Code ist abgelaufen');
    }

    // Prüfe ob bereits verknüpft
    final coParents = data['coParents'] as Map<String, dynamic>? ?? {};
    if (coParents.containsKey(myParentId)) {
      return CoParentValidationResult.alreadyLinked('Bereits verknüpft');
    }

    return CoParentValidationResult.valid(
      targetParentId: doc.id,
      targetEmail: data['email'] ?? '',
    );
  }

  /// Verknüpft zwei Elternteile (bidirektional)
  Future<void> linkCoParents(String parentId1, String parentId2) async {
    final batch = _firestore.batch();

    // Parent 1 bekommt Parent 2 als CoParent
    batch.update(_firestore.collection('parents').doc(parentId1), {
      'coParents.$parentId2': true,
      'coParentCode': FieldValue.delete(), // Code nach Nutzung löschen
      'coParentCodeExpiresAt': FieldValue.delete(),
      'updatedAt': Timestamp.now(),
    });

    // Parent 2 bekommt Parent 1 als CoParent
    batch.update(_firestore.collection('parents').doc(parentId2), {
      'coParents.$parentId1': true,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  /// Entfernt CoParent-Verknüpfung (bidirektional)
  Future<void> unlinkCoParent(String parentId1, String parentId2) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('parents').doc(parentId1), {
      'coParents.$parentId2': FieldValue.delete(),
      'updatedAt': Timestamp.now(),
    });

    batch.update(_firestore.collection('parents').doc(parentId2), {
      'coParents.$parentId1': FieldValue.delete(),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  /// Holt alle verknüpften CoParents
  Future<List<CoParentInfo>> getCoParents(String parentId) async {
    final doc = await _firestore.collection('parents').doc(parentId).get();
    if (!doc.exists) return [];

    final data = doc.data()!;
    final coParents = data['coParents'] as Map<String, dynamic>? ?? {};

    final List<CoParentInfo> result = [];

    for (final coParentId in coParents.keys) {
      final coParentDoc = await _firestore.collection('parents').doc(coParentId).get();
      if (coParentDoc.exists) {
        final coParentData = coParentDoc.data()!;
        result.add(CoParentInfo(
          id: coParentId,
          email: coParentData['email'] ?? '',
          linkedAt: (coParentData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
    }

    return result;
  }

  /// Holt aktuellen Einladungscode (falls vorhanden)
  Future<CoParentInviteInfo?> getCurrentInviteCode(String parentId) async {
    final doc = await _firestore.collection('parents').doc(parentId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final code = data['coParentCode'] as String?;
    final expiresAt = (data['coParentCodeExpiresAt'] as Timestamp?)?.toDate();

    if (code == null || expiresAt == null) return null;
    if (DateTime.now().isAfter(expiresAt)) return null;

    return CoParentInviteInfo(code: code, expiresAt: expiresAt);
  }
}

/// Ergebnis der Code-Validierung
class CoParentValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? targetParentId;
  final String? targetEmail;
  final CoParentError? error;

  CoParentValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.targetParentId,
    this.targetEmail,
    this.error,
  });

  factory CoParentValidationResult.valid({
    required String targetParentId,
    required String targetEmail,
  }) {
    return CoParentValidationResult._(
      isValid: true,
      targetParentId: targetParentId,
      targetEmail: targetEmail,
    );
  }

  factory CoParentValidationResult.invalid(String message) {
    return CoParentValidationResult._(
      isValid: false,
      errorMessage: message,
      error: CoParentError.invalid,
    );
  }

  factory CoParentValidationResult.expired(String message) {
    return CoParentValidationResult._(
      isValid: false,
      errorMessage: message,
      error: CoParentError.expired,
    );
  }

  factory CoParentValidationResult.alreadyLinked(String message) {
    return CoParentValidationResult._(
      isValid: false,
      errorMessage: message,
      error: CoParentError.alreadyLinked,
    );
  }
}

enum CoParentError {
  invalid,
  expired,
  alreadyLinked,
}

/// Info über einen verknüpften CoParent
class CoParentInfo {
  final String id;
  final String email;
  final DateTime linkedAt;

  CoParentInfo({
    required this.id,
    required this.email,
    required this.linkedAt,
  });
}

/// Info über aktiven Einladungscode
class CoParentInviteInfo {
  final String code;
  final DateTime expiresAt;

  CoParentInviteInfo({
    required this.code,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get daysRemaining => expiresAt.difference(DateTime.now()).inDays;
}
