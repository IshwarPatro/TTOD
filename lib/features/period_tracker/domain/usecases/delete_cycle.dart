// lib/features/period_tracker/domain/usecases/delete_cycle.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/period_repository.dart';

class DeleteCycle implements UseCase<void, DeleteCycleParams> {
  final PeriodRepository repository;

  DeleteCycle(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCycleParams params) async {
    return await repository.deleteCycle(params.id);
  }
}

class DeleteCycleParams {
  final String id;
  const DeleteCycleParams(this.id);
}
