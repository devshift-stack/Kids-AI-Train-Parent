import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider für Firebase Auth Instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider für aktuellen User (Anonymous)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Provider für Parent-ID (= Firebase Anonymous User UID)
final parentIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

/// Auth Service für Anonymous Authentication
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;
  String? get parentId => currentUser?.uid;

  /// Prüft ob User eingeloggt ist
  bool get isSignedIn => currentUser != null;

  /// Anonymous Login (automatisch beim App-Start)
  Future<AuthResult> signInAnonymously() async {
    try {
      // Prüfe ob bereits eingeloggt
      if (_auth.currentUser != null) {
        return AuthResult.success(_auth.currentUser!);
      }

      // Anonymous Sign-In
      final credential = await _auth.signInAnonymously();

      if (credential.user != null) {
        await _createParentDocument(credential.user!);
        return AuthResult.success(credential.user!);
      }

      return AuthResult.error('Anmeldung fehlgeschlagen');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Fehler: $e');
    }
  }

  /// Abmelden (löscht lokale Daten, erstellt neuen Anonymous User)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Erstellt Parent-Dokument in Firestore
  Future<void> _createParentDocument(User user) async {
    final docRef = FirebaseFirestore.instance.collection('parents').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'isAnonymous': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// Mappt Firebase Error Codes zu deutschen Meldungen
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'operation-not-allowed':
        return 'Anonymous Auth ist nicht aktiviert';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte später erneut versuchen.';
      default:
        return 'Ein Fehler ist aufgetreten: $code';
    }
  }
}

/// Ergebnis einer Auth-Operation
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User? user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
