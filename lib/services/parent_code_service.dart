import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service für ParentCode Generierung und Validierung
///
/// ParentCode Format: 6 Zeichen alphanumerisch
/// Alphabet: ABCDEFGHJKMNPQRSTUVWXYZ23456789 (ohne 0,O,1,I,l)
/// Gültigkeit: 7 Tage oder bis zur ersten Nutzung
class ParentCodeService {
  final FirebaseFirestore _firestore;

  // Verwechslungsfreies Alphabet (ohne 0,O,1,I,l)
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static const int _maxRetries = 10;
  static const Duration _codeValidity = Duration(days: 7);

  ParentCodeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generiert einen neuen einzigartigen ParentCode
  Future<String> generateUniqueCode() async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      final code = _generateCode();

      // Prüfe ob Code bereits existiert
      final exists = await _codeExists(code);
      if (!exists) {
        return code;
      }
    }

    // Fallback: Code mit Timestamp-Suffix
    return _generateCode() + DateTime.now().millisecondsSinceEpoch.toString().substring(10);
  }

  /// Generiert einen zufälligen 6-stelligen Code
  String _generateCode() {
    final random = Random.secure();
    final buffer = StringBuffer();

    for (int i = 0; i < _codeLength; i++) {
      buffer.write(_alphabet[random.nextInt(_alphabet.length)]);
    }

    return buffer.toString();
  }

  /// Prüft ob ein Code bereits in der Datenbank existiert
  Future<bool> _codeExists(String code) async {
    final query = await _firestore
        .collectionGroup('children')
        .where('parentCode', isEqualTo: code)
        .where('parentCodeExpiresAt', isGreaterThan: Timestamp.now())
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Validiert einen ParentCode und gibt die Child-ID zurück
  Future<ParentCodeValidationResult> validateCode(String code) async {
    // Normalisiere den Code (Großbuchstaben, keine Leerzeichen)
    final normalizedCode = code.toUpperCase().replaceAll(' ', '');

    // Validiere Format
    if (!_isValidFormat(normalizedCode)) {
      return ParentCodeValidationResult.invalid('Ungültiges Code-Format');
    }

    // Suche in Firestore
    final query = await _firestore
        .collectionGroup('children')
        .where('parentCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return ParentCodeValidationResult.invalid('Code nicht gefunden');
    }

    final doc = query.docs.first;
    final data = doc.data();

    // Prüfe Ablaufdatum
    final expiresAt = (data['parentCodeExpiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      return ParentCodeValidationResult.expired('Code ist abgelaufen');
    }

    // Prüfe ob bereits verknüpft
    if (data['isLinked'] == true) {
      return ParentCodeValidationResult.alreadyLinked('Code wurde bereits verwendet');
    }

    // Extrahiere Parent-ID aus dem Pfad
    final pathSegments = doc.reference.path.split('/');
    final parentId = pathSegments[1]; // parents/{parentId}/children/{childId}

    return ParentCodeValidationResult.valid(
      childId: doc.id,
      parentId: parentId,
      childName: data['name'] ?? '',
    );
  }

  /// Markiert einen Code als verwendet und verknüpft das Gerät
  Future<void> linkDevice({
    required String parentId,
    required String childId,
    required String deviceId,
  }) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'isLinked': true,
      'linkedDeviceIds': FieldValue.arrayUnion([deviceId]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Generiert einen neuen Code für ein bestehendes Kind
  Future<String> regenerateCode({
    required String parentId,
    required String childId,
  }) async {
    final newCode = await generateUniqueCode();
    final expiresAt = DateTime.now().add(_codeValidity);

    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update({
      'parentCode': newCode,
      'parentCodeExpiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': Timestamp.now(),
    });

    return newCode;
  }

  /// Prüft ob das Format gültig ist
  bool _isValidFormat(String code) {
    if (code.length != _codeLength) return false;

    for (final char in code.split('')) {
      if (!_alphabet.contains(char)) return false;
    }

    return true;
  }

  /// Berechnet Ablaufdatum
  DateTime getExpirationDate() {
    return DateTime.now().add(_codeValidity);
  }
}

/// Ergebnis der Code-Validierung
class ParentCodeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? childId;
  final String? parentId;
  final String? childName;
  final ParentCodeError? error;

  ParentCodeValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.childId,
    this.parentId,
    this.childName,
    this.error,
  });

  factory ParentCodeValidationResult.valid({
    required String childId,
    required String parentId,
    required String childName,
  }) {
    return ParentCodeValidationResult._(
      isValid: true,
      childId: childId,
      parentId: parentId,
      childName: childName,
    );
  }

  factory ParentCodeValidationResult.invalid(String message) {
    return ParentCodeValidationResult._(
      isValid: false,
      errorMessage: message,
      error: ParentCodeError.invalid,
    );
  }

  factory ParentCodeValidationResult.expired(String message) {
    return ParentCodeValidationResult._(
      isValid: false,
      errorMessage: message,
      error: ParentCodeError.expired,
    );
  }

  factory ParentCodeValidationResult.alreadyLinked(String message) {
    return ParentCodeValidationResult._(
      isValid: false,
      errorMessage: message,
      error: ParentCodeError.alreadyLinked,
    );
  }
}

enum ParentCodeError {
  invalid,
  expired,
  alreadyLinked,
}
