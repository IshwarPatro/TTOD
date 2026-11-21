// lib/features/period_tracker/data/repositories/period_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/cycle.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/period_repository.dart';
import '../datasources/period_local_datasource.dart';
import '../models/cycle_model.dart';

class PeriodRepositoryImpl implements PeriodRepository {
  final PeriodLocalDataSource localDataSource;

  PeriodRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Cycle>>> getCycles() async {
    try {
      final localModels = await localDataSource.getCycles();
      final List<Cycle> cycles = localModels.map((model) => model.toEntity()).toList();
      return Right(cycles);
    } catch (e) {
      return Left(CacheFailure("Failed to retrieve cycles: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> saveCycle(Cycle cycle) async {
    try {
      final model = CycleModel.fromEntity(cycle);
      await localDataSource.cacheCycle(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure("Failed to cache cycle: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCycle(String id) async {
    try {
      await localDataSource.deleteCycle(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure("Failed to delete cycle: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<DailyLog>>> getDailyLogs() async {
    try {
      final localModels = await localDataSource.getDailyLogs();
      final List<DailyLog> logs = localModels.map((model) => model.toEntity()).toList();
      return Right(logs);
    } catch (e) {
      return Left(CacheFailure("Failed to retrieve daily logs: ${e.toString()}"));
    }
  }
}
