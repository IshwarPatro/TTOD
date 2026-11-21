// lib/features/period_tracker/domain/usecases/predict_cycle.dart
import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cycle.dart';

class PredictionResult extends Equatable {
  final int averageCycleLength;
  final int averagePeriodDuration;
  final DateTime? predictedNextStartDate;
  final DateTime? predictedNextEndDate;
  final DateTime? ovulationWindowStart;
  final DateTime? ovulationWindowEnd;

  const PredictionResult({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    this.predictedNextStartDate,
    this.predictedNextEndDate,
    this.ovulationWindowStart,
    this.ovulationWindowEnd,
  });

  @override
  List<Object?> get props => [
        averageCycleLength,
        averagePeriodDuration,
        predictedNextStartDate,
        predictedNextEndDate,
        ovulationWindowStart,
        ovulationWindowEnd,
      ];
}

class PredictCycle implements UseCase<PredictionResult, List<Cycle>> {
  @override
  Future<Either<Failure, PredictionResult>> call(List<Cycle> cycles) async {
    try {
      if (cycles.isEmpty) {
        return const Right(PredictionResult(
          averageCycleLength: 28,
          averagePeriodDuration: 5,
        ));
      }

      // Sort cycles by startDate ascending
      final sorted = List<Cycle>.from(cycles)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      // Calculate dynamic average cycle length based on last 3 cycles
      int averageCycleLength = 28; // Default fallback
      if (sorted.length >= 2) {
        final lastThree = sorted.length >= 3 
            ? sorted.sublist(sorted.length - 3) 
            : sorted;
        
        final List<int> startDifferences = [];
        for (int i = 0; i < lastThree.length - 1; i++) {
          final diff = lastThree[i + 1].startDate.difference(lastThree[i].startDate).inDays;
          startDifferences.add(diff);
        }
        
        if (startDifferences.isNotEmpty) {
          final sum = startDifferences.reduce((a, b) => a + b);
          averageCycleLength = (sum / startDifferences.length).round();
        }
      }

      // Calculate average period duration (bleeding duration) dynamically on last 3 cycles
      int averagePeriodDuration = 5; // Default fallback
      final lastThreeForDuration = sorted.length >= 3 
          ? sorted.sublist(sorted.length - 3) 
          : sorted;
      final List<int> durations = lastThreeForDuration
          .map((c) => c.endDate.difference(c.startDate).inDays + 1)
          .toList();
      if (durations.isNotEmpty) {
        final sum = durations.reduce((a, b) => a + b);
        averagePeriodDuration = (sum / durations.length).round();
      }

      final mostRecentCycle = sorted.last;
      
      // Calculate predicted next cycle start date
      final predictedNextStartDate = mostRecentCycle.startDate.add(
        Duration(days: averageCycleLength),
      );

      // Predicted next cycle end date
      final predictedNextEndDate = predictedNextStartDate.add(
        Duration(days: averagePeriodDuration - 1),
      );

      // Calculate the local ovulation window:
      // Subtract exactly 14 days from predicted next start date, creating 5-day boundary overlay around it
      final ovulationDate = predictedNextStartDate.subtract(const Duration(days: 14));
      final ovulationWindowStart = ovulationDate.subtract(const Duration(days: 2));
      final ovulationWindowEnd = ovulationDate.add(const Duration(days: 2));

      return Right(PredictionResult(
        averageCycleLength: averageCycleLength,
        averagePeriodDuration: averagePeriodDuration,
        predictedNextStartDate: predictedNextStartDate,
        predictedNextEndDate: predictedNextEndDate,
        ovulationWindowStart: ovulationWindowStart,
        ovulationWindowEnd: ovulationWindowEnd,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
