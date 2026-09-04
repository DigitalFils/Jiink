import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Just the auth operations the UI needs — lets tests swap in a fake
/// without touching Firebase at all.
abstract class AuthServiceBase {
  Stream<User?> get authStateChanges;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String city,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

class AuthService implements AuthServiceBase {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String city,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'displayName': displayName,
      'city': city,
      'payoutsEnabled': false,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
