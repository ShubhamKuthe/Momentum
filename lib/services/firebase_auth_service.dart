import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MomentumAuthUser {
  const MomentumAuthUser({
    required this.name,
    required this.email,
    required this.uid,
    required this.isNewUser,
  });

  final String name;
  final String email;
  final String uid;
  final bool isNewUser;
}

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();
  static const String _googleServerClientId =
      '101657797872-6362asfio976o7d7kkqfrr7hcq3rll9m.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool get supportsConfiguredFirebase {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<bool> isSignedIn() async => _auth.currentUser != null;

  Future<MomentumAuthUser?> getRestoredSessionUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        return null;
      }

      return MomentumAuthUser(
        name:
            _resolveName(user: refreshedUser, email: refreshedUser.email ?? ''),
        email: refreshedUser.email ?? '',
        uid: refreshedUser.uid,
        isNewUser: false,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found' ||
          error.code == 'user-disabled' ||
          error.code == 'invalid-user-token' ||
          error.code == 'user-token-expired') {
        await signOut();
        return null;
      }
      rethrow;
    }
  }

  Future<MomentumAuthUser> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Momentum could not create your account.',
      );
    }

    if (name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
      await user.reload();
    }

    final refreshedUser = _auth.currentUser ?? user;
    return MomentumAuthUser(
      name: _resolveName(
        explicitName: name,
        user: refreshedUser,
        email: email,
      ),
      email: refreshedUser.email ?? email,
      uid: refreshedUser.uid,
      isNewUser: true,
    );
  }

  Future<MomentumAuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Momentum could not find that account.',
      );
    }

    return MomentumAuthUser(
      name: _resolveName(user: user, email: email),
      email: user.email ?? email,
      uid: user.uid,
      isNewUser: false,
    );
  }

  Future<MomentumAuthUser> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});

      final credential = await _auth.signInWithPopup(provider);
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: 'Google sign-in did not return a user.',
        );
      }

      return MomentumAuthUser(
        name: _resolveName(user: user, email: user.email ?? ''),
        email: user.email ?? '',
        uid: user.uid,
        isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
      );
    }

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: _googleServerClientId,
    );
    // Clear any cached Google session so Android always opens the account picker.
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign-in did not return a user.',
      );
    }

    return MomentumAuthUser(
      name: _resolveName(
        explicitName: googleUser.displayName,
        user: user,
        email: user.email ?? '',
      ),
      email: user.email ?? '',
      uid: user.uid,
      isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  Future<MomentumAuthUser> signInWithApple() async {
    final provider = AppleAuthProvider()..addScope('email');

    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-failed',
        message: 'Apple sign-in did not return a user.',
      );
    }

    return MomentumAuthUser(
      name: _resolveName(user: user, email: user.email ?? ''),
      email: user.email ?? '',
      uid: user.uid,
      isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  String _resolveName({
    String? explicitName,
    User? user,
    String? email,
  }) {
    final trimmedExplicit = explicitName?.trim() ?? '';
    if (trimmedExplicit.isNotEmpty) {
      return trimmedExplicit;
    }

    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final chosenEmail = (user?.email ?? email ?? '').trim();
    if (chosenEmail.contains('@')) {
      return chosenEmail.split('@').first;
    }

    return 'Momentum user';
  }
}

String momentumAuthErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'That email is already being used.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'sign_in_canceled':
        return 'Sign-in was cancelled.';
      case 'account-exists-with-different-credential':
        return 'This email already belongs to another sign-in method.';
      default:
        final message = error.message?.trim() ?? '';
        if (message.isNotEmpty) {
          return message;
        }
    }
  }

  return 'Momentum could not complete sign-in right now.';
}
