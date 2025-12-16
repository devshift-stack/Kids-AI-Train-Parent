import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider für Firebase Auth Instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider für aktuellen User
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Provider für Parent-ID (= Firebase User UID)
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

/// Auth Service für Anmeldung/Registrierung
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;
  String? get parentId => currentUser?.uid;

  /// Registrierung mit E-Mail
  Future<AuthResult> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createParentDocument(credential.user!);
        return AuthResult.success(credential.user!);
      }

      return AuthResult.error('Registrierung fehlgeschlagen');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    }
  }

  /// Anmeldung mit E-Mail
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return AuthResult.success(credential.user!);
      }

      return AuthResult.error('Anmeldung fehlgeschlagen');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    }
  }

  /// Abmelden
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Passwort zurücksetzen
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_mapFirebaseError(e.code));
    }
  }

  /// Erstellt Parent-Dokument in Firestore
  Future<void> _createParentDocument(User user) async {
    final docRef = FirebaseFirestore.instance.collection('parents').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'email': user.email,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  /// Mappt Firebase Error Codes zu deutschen Meldungen
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Diese E-Mail wird bereits verwendet';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse';
      case 'weak-password':
        return 'Passwort ist zu schwach';
      case 'user-not-found':
        return 'Kein Konto mit dieser E-Mail gefunden';
      case 'wrong-password':
        return 'Falsches Passwort';
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert';
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
