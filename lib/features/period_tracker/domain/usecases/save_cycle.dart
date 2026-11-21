// lib/features/period_tracker/domain/usecases/save_cycle.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cycle.dart';
import '../repositories/period_repository.dart';

class SaveCycle implements UseCase<void, SaveCycleParams> {
  final PeriodRepository repository;

  SaveCycle(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveCycleParams params) async {
    return await repository.saveCycle(params.cycle);
  }
}

class SaveCycleParams {
  final Cycle cycle;
  const SaveCycleParams(this.cycle);
}
