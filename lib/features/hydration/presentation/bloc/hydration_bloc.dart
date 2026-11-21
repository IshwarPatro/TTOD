// lib/features/hydration/presentation/bloc/hydration_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class HydrationEvent extends Equatable {
  const HydrationEvent();
  @override
  List<Object?> get props => [];
}

class LoadDailyIntake extends HydrationEvent {}

class AddWaterIntake extends HydrationEvent {
  final int amountMl;
  const AddWaterIntake(this.amountMl);
  @override
  List<Object?> get props => [amountMl];
}

class RecordResetIntake extends HydrationEvent {}

// States
class HydrationState extends Equatable {
  final int currentIntakeMl;
  final int targetIntakeMl;
  final DateTime date;

  const HydrationState({
    required this.currentIntakeMl,
    required this.targetIntakeMl,
    required this.date,
  });

  HydrationState copyWith({
    int? currentIntakeMl,
    int? targetIntakeMl,
    DateTime? date,
  }) {
    return HydrationState(
      currentIntakeMl: currentIntakeMl ?? this.currentIntakeMl,
      targetIntakeMl: targetIntakeMl ?? this.targetIntakeMl,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [currentIntakeMl, targetIntakeMl, date];
}

// Bloc
class HydrationBloc extends Bloc<HydrationEvent, HydrationState> {
  HydrationBloc() : super(HydrationState(
          currentIntakeMl: 0,
          targetIntakeMl: 2000,
          date: DateTime.now(),
        )) {
    on<LoadDailyIntake>(_onLoadDailyIntake);
    on<AddWaterIntake>(_onAddWaterIntake);
    on<RecordResetIntake>(_onRecordResetIntake);
  }

  void _onLoadDailyIntake(LoadDailyIntake event, Emitter<HydrationState> emit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (state.date.isBefore(today)) {
      emit(HydrationState(currentIntakeMl: 0, targetIntakeMl: state.targetIntakeMl, date: today));
    }
  }

  void _onAddWaterIntake(AddWaterIntake event, Emitter<HydrationState> emit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (state.date.isBefore(today)) {
      emit(HydrationState(
        currentIntakeMl: event.amountMl,
        targetIntakeMl: state.targetIntakeMl,
        date: today,
      ));
    } else {
      emit(state.copyWith(
        currentIntakeMl: state.currentIntakeMl + event.amountMl,
        date: today,
      ));
    }
  }

  void _onRecordResetIntake(RecordResetIntake event, Emitter<HydrationState> emit) {
    emit(state.copyWith(currentIntakeMl: 0, date: DateTime.now()));
  }
}
