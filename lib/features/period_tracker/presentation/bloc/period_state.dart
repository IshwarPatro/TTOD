// lib/features/period_tracker/presentation/bloc/period_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/cycle.dart';

abstract class PeriodState extends Equatable {
  const PeriodState();

  @override
  List<Object?> get props => [];
}

class PeriodInitial extends PeriodState {}

class PeriodLoading extends PeriodState {}

class PeriodLoaded extends PeriodState {
  final List<Cycle> cycles;
  final int averageCycleLength;
  final int averagePeriodDuration;
  final DateTime? predictedNextStartDate;
  final DateTime? predictedNextEndDate;
  final DateTime? predictedFertilityStartDate;
  final DateTime? predictedFertilityEndDate;
  final double aiPredictedCycleLength;
  final double aiCycleLengthStandardDeviation;
  final Map<String, double> aiSymptomProbabilities;

  const PeriodLoaded({
    required this.cycles,
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    this.predictedNextStartDate,
    this.predictedNextEndDate,
    this.predictedFertilityStartDate,
    this.predictedFertilityEndDate,
    this.aiPredictedCycleLength = 28.0,
    this.aiCycleLengthStandardDeviation = 0.0,
    this.aiSymptomProbabilities = const {},
  });

  @override
  List<Object?> get props => [
        cycles,
        averageCycleLength,
        averagePeriodDuration,
        predictedNextStartDate,
        predictedNextEndDate,
        predictedFertilityStartDate,
        predictedFertilityEndDate,
        aiPredictedCycleLength,
        aiCycleLengthStandardDeviation,
        aiSymptomProbabilities,
      ];
}

class PeriodError extends PeriodState {
  final String message;
  const PeriodError(this.message);

  @override
  List<Object?> get props => [message];
}
