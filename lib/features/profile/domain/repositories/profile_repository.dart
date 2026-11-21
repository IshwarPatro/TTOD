// lib/features/profile/domain/repositories/profile_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile?>> getProfile({String? userId});
  Future<Either<Failure, void>> saveProfile(UserProfile profile, {String? userId});
  Future<Either<Failure, void>> resetAllLocalData();
}
