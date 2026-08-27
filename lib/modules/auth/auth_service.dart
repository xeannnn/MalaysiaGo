import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Firebase Authentication and user profile storage.
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential =
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'The account could not be created.',
      );
    }

    await user.updateDisplayName(name.trim());

    await _saveUserProfile(user);

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      serverClientId:
      '280746057244-egjn1iq2f3e06us8r2nt9ti5kvo1vli7.apps.googleusercontent.com',
    );

    final GoogleSignInAccount googleUser =
    await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
    await _firebaseAuth.signInWithCredential(credential);

    final User? user = userCredential.user;

    if (user != null) {
      await _saveUserProfile(user);
    }

    return userCredential;
  }

  Future<void> _saveUserProfile(User user) async {
    final DocumentReference<Map<String, dynamic>> userDoc =
    _firestore.collection('users').doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> existing =
    await userDoc.get();

    if (!existing.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email?.toLowerCase() ?? '',
        'photoUrl': user.photoURL,
        'role': 'user',
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        'name': user.displayName ?? '',
        'email': user.email?.toLowerCase() ?? '',
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<UserCredential> continueAsGuest() {
    return _firebaseAuth.signInAnonymously();
  }

  Future<void> logout() async {
    await GoogleSignIn.instance.signOut();
    await _firebaseAuth.signOut();
  }
}