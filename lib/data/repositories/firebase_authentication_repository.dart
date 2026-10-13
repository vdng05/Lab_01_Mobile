import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/cloud_environment.dart';
import '../../domain/entities/study_user.dart';
import '../../domain/repositories/authentication_repository.dart';

class FirebaseAuthenticationRepository implements AuthenticationRepository {
  FirebaseAuthenticationRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             serverClientId: CloudEnvironment.googleServerClientId.isEmpty
                 ? null
                 : CloudEnvironment.googleServerClientId,
           );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  StudyUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<StudyUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  @override
  Future<StudyUser?> signInWithGoogle() async {
    final UserCredential result;
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      result = await _auth.signInWithPopup(provider);
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      result = await _auth.signInWithProvider(provider);
    } else {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final tokens = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
      );
      result = await _auth.signInWithCredential(credential);
    }
    return _mapUser(result.user);
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('FirebaseAuth.signOut error: $e');
    }
    try {
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('GoogleSignIn.signOut error: $e');
    }
  }

  StudyUser? _mapUser(User? user) {
    if (user == null) return null;
    return StudyUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      emailVerified: user.emailVerified,
    );
  }
}
