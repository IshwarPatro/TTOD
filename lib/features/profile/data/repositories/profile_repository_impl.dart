// lib/features/profile/data/repositories/profile_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../datasources/profile_local_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource localDataSource;

  ProfileRepositoryImpl({required this.localDataSource});

  bool _isFirebaseAvailable() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getProfile({String? userId}) async {
    try {
      // 1. Try local cache
      final model = await localDataSource.getProfile(userId: userId);
      if (model != null) {
        return Right(model.toEntity());
      }

      // 2. If client is logged in and Firebase is initialized, try Firestore
      if (userId != null && _isFirebaseAvailable()) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final profile = ProfileModel(
              hiveName: data['name'] ?? '',
              hiveDateOfBirth: DateTime.parse(
                data['dateOfBirth'] ?? DateTime(1998, 6, 15).toIso8601String(),
              ),
              hiveAverageCycleLengthInput: data['averageCycleLengthInput'] ?? 28,
              hiveHistoricalCycleCount: data['historicalCycleCount'] ?? 0,
            );
            // Cache locally
            await localDataSource.cacheProfile(profile, userId: userId);
            return Right(profile.toEntity());
          }
        } catch (e) {
          // If Firestore is disabled or fails, do not crash the app - fallback gracefully to null (ProfileNotCreated)
          print("Firestore getProfile failed: $e. Falling back to local/null.");
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveProfile(UserProfile profile, {String? userId}) async {
    try {
      final model = ProfileModel.fromEntity(profile);
      // 1. Cache locally
      await localDataSource.cacheProfile(model, userId: userId);

      // 2. Sync to Firestore if authenticated & Firebase is initialized
      if (userId != null && _isFirebaseAvailable()) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'name': profile.name,
            'dateOfBirth': profile.dateOfBirth.toIso8601String(),
            'averageCycleLengthInput': profile.averageCycleLengthInput,
            'historicalCycleCount': profile.historicalCycleCount,
          });
        } catch (e) {
          // If Firestore is disabled or fails, do not fail the save operation since it succeeded locally
          print("Firestore saveProfile failed: $e. Local save was successful.");
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetAllLocalData() async {
    try {
      await localDataSource.clearAllBoxes();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
