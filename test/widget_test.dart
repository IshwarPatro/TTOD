import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:thattimeofday/core/error/failure.dart';
import 'package:thattimeofday/features/period_tracker/domain/entities/cycle.dart';
import 'package:thattimeofday/features/period_tracker/domain/repositories/period_repository.dart';
import 'package:thattimeofday/features/period_tracker/data/repositories/period_repository_impl.dart';
import 'package:thattimeofday/features/period_tracker/data/datasources/period_local_datasource.dart';
import 'package:thattimeofday/features/period_tracker/data/models/cycle_model.dart';
import 'package:thattimeofday/features/profile/domain/entities/user_profile.dart';
import 'package:thattimeofday/features/profile/domain/repositories/profile_repository.dart';
import 'package:thattimeofday/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:thattimeofday/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:thattimeofday/features/profile/data/models/profile_model.dart';
import 'package:thattimeofday/features/period_tracker/data/models/daily_log_model.dart';
import 'package:thattimeofday/features/period_tracker/domain/entities/daily_log.dart';
import 'package:thattimeofday/main.dart';
import 'package:thattimeofday/features/auth/domain/repositories/auth_repository.dart';
import 'package:thattimeofday/features/community/data/repositories/firestore_community_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class FakeAuthRepository implements AuthRepository {
  final _currentUser = AppUser(
    uid: "mock_uid",
    email: "mock@example.com",
    displayName: "Mock User",
    phoneNumber: "+11234567890",
  );

  @override
  Stream<AppUser?> get user => Stream.value(_currentUser);

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async => _currentUser;

  @override
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => _currentUser;

  @override
  Future<AppUser?> signInWithGoogle() async => _currentUser;

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(firebase.FirebaseAuthException e) verificationFailed,
    required void Function(firebase.PhoneAuthCredential credential) verificationCompleted,
  }) async {}

  @override
  Future<AppUser?> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async => _currentUser;

  @override
  Future<void> signOut() async {}
}

class MockPeriodRepository implements PeriodRepository {
  @override
  Future<Either<Failure, List<Cycle>>> getCycles() async => const Right([]);

  @override
  Future<Either<Failure, void>> saveCycle(Cycle cycle) async => const Right(null);

  @override
  Future<Either<Failure, void>> deleteCycle(String id) async => const Right(null);

  @override
  Future<Either<Failure, List<DailyLog>>> getDailyLogs() async => const Right([]);
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<Either<Failure, UserProfile?>> getProfile({String? userId}) async {
    return Right(UserProfile(
      name: "Mock User",
      dateOfBirth: DateTime(1995, 1, 1),
      averageCycleLengthInput: 28,
      historicalCycleCount: 0,
    ));
  }

  @override
  Future<Either<Failure, void>> saveProfile(UserProfile profile, {String? userId}) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> resetAllLocalData() async => const Right(null);
}

void main() {
  testWidgets('App smoke test - verifies simplified TTOD shell loads', (WidgetTester tester) async {
    final mockPeriodRepo = PeriodRepositoryImpl(
      localDataSource: FakeLocalDataSource(),
    );
    final mockProfileRepo = ProfileRepositoryImpl(
      localDataSource: FakeProfileLocalDataSource(),
    );
    final mockAuthRepo = FakeAuthRepository();
    final mockCommunityRepo = FirestoreCommunityRepository();

    await tester.pumpWidget(MyApp(
      periodRepository: mockPeriodRepo,
      profileRepository: mockProfileRepo,
      authRepository: mockAuthRepo,
      communityRepository: mockCommunityRepo,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cycle'), findsWidgets);
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('Log Period'), findsWidgets);
  });
}

class FakeLocalDataSource implements PeriodLocalDataSource {
  @override
  Future<List<CycleModel>> getCycles() async => [];

  @override
  Future<void> cacheCycle(CycleModel cycle) async {}

  @override
  Future<void> deleteCycle(String id) async {}

  @override
  Future<List<DailyLogModel>> getDailyLogs() async => [];
}

class FakeProfileLocalDataSource implements ProfileLocalDataSource {
  @override
  Future<ProfileModel?> getProfile({String? userId}) async => ProfileModel(
        hiveName: "Mock User",
        hiveDateOfBirth: DateTime(1995, 1, 1),
        hiveAverageCycleLengthInput: 28,
        hiveHistoricalCycleCount: 0,
      );

  @override
  Future<void> cacheProfile(ProfileModel profile, {String? userId}) async {}

  @override
  Future<void> clearAllBoxes() async {}
}
