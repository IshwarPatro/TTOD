// lib/features/period_tracker/domain/repositories/period_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/cycle.dart';
import '../entities/daily_log.dart';

abstract class PeriodRepository {
  Future<Either<Failure, List<Cycle>>> getCycles();
  Future<Either<Failure, void>> saveCycle(Cycle cycle);
  Future<Either<Failure, void>> deleteCycle(String id);
  Future<Either<Failure, List<DailyLog>>> getDailyLogs();
}
