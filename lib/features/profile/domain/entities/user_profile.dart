// lib/features/profile/domain/entities/user_profile.dart
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String name;
  final DateTime dateOfBirth;
  final int averageCycleLengthInput;
  final int historicalCycleCount;

  const UserProfile({
    required this.name,
    required this.dateOfBirth,
    required this.averageCycleLengthInput,
    required this.historicalCycleCount,
  });

  @override
  List<Object?> get props => [
        name,
        dateOfBirth,
        averageCycleLengthInput,
        historicalCycleCount,
      ];
}
