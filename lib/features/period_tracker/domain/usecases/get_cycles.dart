// lib/features/period_tracker/domain/usecases/get_cycles.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cycle.dart';
import '../repositories/period_repository.dart';

class GetCycles implements UseCase<List<Cycle>, NoParams> {
  final PeriodRepository repository;

  GetCycles(this.repository);

  @override
  Future<Either<Failure, List<Cycle>>> call(NoParams params) async {
    return await repository.getCycles();
  }
}
