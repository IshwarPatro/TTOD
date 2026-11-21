// lib/features/profile/data/datasources/profile_local_datasource.dart
import 'package:hive/hive.dart';
import '../models/profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<ProfileModel?> getProfile({String? userId});
  Future<void> cacheProfile(ProfileModel profile, {String? userId});
  Future<void> clearAllBoxes();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final Box<ProfileModel> profileBox;
  final Box cyclesBox;
  final Box dailyLogsBox;

  ProfileLocalDataSourceImpl({
    required this.profileBox,
    required this.cyclesBox,
    required this.dailyLogsBox,
  });

  @override
  Future<ProfileModel?> getProfile({String? userId}) async {
    final key = userId != null ? 'user_profile_$userId' : 'user_profile_key';
    return profileBox.get(key);
  }

  @override
  Future<void> cacheProfile(ProfileModel profile, {String? userId}) async {
    final key = userId != null ? 'user_profile_$userId' : 'user_profile_key';
    await profileBox.put(key, profile);
  }

  @override
  Future<void> clearAllBoxes() async {
    await profileBox.clear();
    await cyclesBox.clear();
    await dailyLogsBox.clear();
  }
}
