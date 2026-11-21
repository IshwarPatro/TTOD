// lib/features/period_tracker/domain/usecases/get_daily_logs.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/daily_log.dart';
import '../repositories/period_repository.dart';

class GetDailyLogs implements UseCase<List<DailyLog>, NoParams> {
  final PeriodRepository repository;

  GetDailyLogs(this.repository);

  @override
  Future<Either<Failure, List<DailyLog>>> call(NoParams params) async {
    return await repository.getDailyLogs();
  }
}
