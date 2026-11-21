// lib/features/period_tracker/presentation/bloc/period_event.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/cycle.dart';

abstract class PeriodEvent extends Equatable {
  const PeriodEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllCycles extends PeriodEvent {}

class LogNewCycle extends PeriodEvent {
  final Cycle cycle;
  const LogNewCycle(this.cycle);

  @override
  List<Object?> get props => [cycle];
}

class DeleteCycleRecord extends PeriodEvent {
  final String id;
  const DeleteCycleRecord(this.id);

  @override
  List<Object?> get props => [id];
}
