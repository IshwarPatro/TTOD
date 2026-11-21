// lib/features/profile/data/models/profile_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/user_profile.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 2)
class ProfileModel extends UserProfile {
  @HiveField(0)
  final String hiveName;

  @HiveField(1)
  final DateTime hiveDateOfBirth;

  @HiveField(2)
  final int hiveAverageCycleLengthInput;

  @HiveField(3)
  final int hiveHistoricalCycleCount;

  const ProfileModel({
    required this.hiveName,
    required this.hiveDateOfBirth,
    required this.hiveAverageCycleLengthInput,
    required this.hiveHistoricalCycleCount,
  }) : super(
          name: hiveName,
          dateOfBirth: hiveDateOfBirth,
          averageCycleLengthInput: hiveAverageCycleLengthInput,
          historicalCycleCount: hiveHistoricalCycleCount,
        );

  factory ProfileModel.fromEntity(UserProfile profile) {
    return ProfileModel(
      hiveName: profile.name,
      hiveDateOfBirth: profile.dateOfBirth,
      hiveAverageCycleLengthInput: profile.averageCycleLengthInput,
      hiveHistoricalCycleCount: profile.historicalCycleCount,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      name: name,
      dateOfBirth: dateOfBirth,
      averageCycleLengthInput: averageCycleLengthInput,
      historicalCycleCount: historicalCycleCount,
    );
  }
}
