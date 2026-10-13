import '../entities/study_user.dart';

abstract interface class UserProfileRepository {
  Future<void> syncProfile(StudyUser user);
}