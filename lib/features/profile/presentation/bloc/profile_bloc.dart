// lib/features/profile/presentation/bloc/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String? userId;
  final String? defaultName;

  const LoadProfile({this.userId, this.defaultName});

  @override
  List<Object?> get props => [userId, defaultName];
}

class UpdateProfileDetails extends ProfileEvent {
  final String name;
  final DateTime dateOfBirth;
  final int averageCycleLengthInput;
  final int historicalCycleCount;
  final String? userId;

  const UpdateProfileDetails({
    required this.name,
    required this.dateOfBirth,
    required this.averageCycleLengthInput,
    required this.historicalCycleCount,
    this.userId,
  });

  @override
  List<Object?> get props => [name, dateOfBirth, averageCycleLengthInput, historicalCycleCount, userId];
}

class ResetAllLocalData extends ProfileEvent {}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileNotCreated extends ProfileState {
  final String? defaultName;
  const ProfileNotCreated({this.defaultName});

  @override
  List<Object?> get props => [defaultName];
}

class ProfileResetSuccess extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileDetails>(_onUpdateProfileDetails);
    on<ResetAllLocalData>(_onResetAllLocalData);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await repository.getProfile(userId: event.userId);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) {
        if (profile == null) {
          emit(ProfileNotCreated(defaultName: event.defaultName));
        } else {
          emit(ProfileLoaded(profile));
        }
      },
    );
  }

  Future<void> _onUpdateProfileDetails(UpdateProfileDetails event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final newProfile = UserProfile(
      name: event.name,
      dateOfBirth: event.dateOfBirth,
      averageCycleLengthInput: event.averageCycleLengthInput,
      historicalCycleCount: event.historicalCycleCount,
    );
    final result = await repository.saveProfile(newProfile, userId: event.userId);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) => emit(ProfileLoaded(newProfile)),
    );
  }

  Future<void> _onResetAllLocalData(ResetAllLocalData event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await repository.resetAllLocalData();
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) {
        emit(ProfileResetSuccess());
        add(LoadProfile());
      },
    );
  }
}
