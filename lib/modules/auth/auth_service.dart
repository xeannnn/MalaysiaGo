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

  static const String _serverClientId =
      '280746057244-egjn1iq2f3e06us8r2nt9ti5kvo1vli7.apps.googleusercontent.com';

  User? get currentUser => _firebaseAuth.currentUser;

  // ============================================================
  // REGISTER
  // ============================================================

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

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'photoUrl': user.photoURL,
      'phone': '',
      'state': '',
      'interests': [],
      'role': 'user',
      'accountStatus': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      serverClientId: _serverClientId,
    );

    final GoogleSignInAccount googleUser =
    await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final OAuthCredential credential =
    GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
    await _firebaseAuth.signInWithCredential(
      credential,
    );

    final User? user = userCredential.user;

    if (user != null) {
      await _saveUserProfile(user);
    }

    return userCredential;
  }

  // ============================================================
  // FIRESTORE PROFILE
  // ============================================================

  Future<void> _saveUserProfile(User user) async {
    final DocumentReference<Map<String, dynamic>> userDoc =
    _firestore.collection('users').doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> existing =
    await userDoc.get();

    final Map<String, dynamic> data = {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email?.toLowerCase() ?? '',
      'photoUrl': user.photoURL,
      'role': 'user',
      'accountStatus': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      data['phone'] = '';
      data['state'] = '';
      data['interests'] = [];
      data['createdAt'] = FieldValue.serverTimestamp();

      await userDoc.set(data);
    } else {
      await userDoc.set(
        data,
        SetOptions(merge: true),
      );
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> sendPasswordResetEmail(
      String email,
      ) {
    return _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // ============================================================
  // GUEST
  // ============================================================

  Future<UserCredential> continueAsGuest() {
    return _firebaseAuth.signInAnonymously();
  }

  // ============================================================
  // CHECK PASSWORD PROVIDER
  // ============================================================

  bool isPasswordUser() {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
          (UserInfo info) =>
      info.providerId == 'password',
    );
  }

  bool isGoogleUser() {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
          (UserInfo info) =>
      info.providerId == 'google.com',
    );
  }

  // ============================================================
  // REAUTHENTICATE EMAIL USER
  // ============================================================

  Future<void> reauthenticateWithPassword(
      String password,
      ) async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final String? email = user.email;

    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'This account does not have an email address.',
      );
    }

    final AuthCredential credential =
    EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(
      credential,
    );
  }

  // ============================================================
  // REAUTHENTICATE GOOGLE USER
  // ============================================================

  Future<void> reauthenticateWithGoogle() async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final GoogleSignIn googleSignIn =
        GoogleSignIn.instance;

    await googleSignIn.initialize(
      serverClientId: _serverClientId,
    );

    final GoogleSignInAccount googleUser =
    await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final OAuthCredential credential =
    GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(
      credential,
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    if (!isPasswordUser()) {
      throw FirebaseAuthException(
        code: 'not-password-user',
        message:
        'Password changes are only available for email accounts.',
      );
    }

    await reauthenticateWithPassword(
      currentPassword,
    );

    await user.updatePassword(
      newPassword,
    );
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> deleteAccount({
    String? password,
  }) async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    final String uid = user.uid;

    // Reauthenticate before sensitive deletion.
    if (user.isAnonymous) {
      // Anonymous accounts do not require another provider login.
    } else if (isGoogleUser()) {
      await reauthenticateWithGoogle();
    } else if (isPasswordUser()) {
      if (password == null ||
          password.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'password-required',
          message:
          'Please enter your current password.',
        );
      }

      await reauthenticateWithPassword(
        password.trim(),
      );
    }

    // Remove Firestore profile.
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .delete();
    } catch (error) {
      // Continue with Firebase Auth deletion even if
      // the Firestore document does not exist.
    }

    await user.delete();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore if account wasn't signed in using Google.
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // User may have logged in using email/password.
    }

    await _firebaseAuth.signOut();
  }
}