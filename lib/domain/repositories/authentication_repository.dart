import '../entities/study_user.dart';

abstract interface class AuthenticationRepository {
  StudyUser? get currentUser;
  Stream<StudyUser?> authStateChanges();
  Future<StudyUser?> signInWithGoogle();
  Future<void> signOut();
}
