import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_cycles.dart';
import '../../domain/usecases/save_cycle.dart';
import '../../domain/usecases/delete_cycle.dart';
import '../../domain/usecases/predict_cycle.dart';
import '../../domain/usecases/get_daily_logs.dart';
import '../../domain/usecases/ai_predictor.dart';
import '../../data/models/daily_log_model.dart';
import '../../../../core/usecase/usecase.dart';
import 'period_event.dart';
import 'period_state.dart';
import '../../domain/entities/cycle.dart';

class PeriodBloc extends Bloc<PeriodEvent, PeriodState> {
  final GetCycles getCyclesUseCase;
  final SaveCycle saveCycleUseCase;
  final DeleteCycle deleteCycleUseCase;
  final PredictCycle predictCycleUseCase;
  final GetDailyLogs getDailyLogsUseCase;

  PeriodBloc({
    required this.getCyclesUseCase,
    required this.saveCycleUseCase,
    required this.deleteCycleUseCase,
    required this.predictCycleUseCase,
    required this.getDailyLogsUseCase,
  }) : super(PeriodInitial()) {
    on<LoadAllCycles>(_onLoadAllCycles);
    on<LogNewCycle>(_onLogNewCycle);
    on<DeleteCycleRecord>(_onDeleteCycleRecord);
  }

  Future<PeriodState> _buildPeriodLoadedState({
    required List<Cycle> cycles,
    required PredictionResult p,
  }) async {
    final logsResult = await getDailyLogsUseCase(const NoParams());
    final List<DailyLogModel> dailyLogModels = [];
    logsResult.fold(
      (_) => null,
      (logs) => dailyLogModels.addAll(logs.map((log) => DailyLogModel.fromEntity(log)).toList()),
    );

    final int maxCycleLength = p.averageCycleLength > 0 ? p.averageCycleLength : 28;
    int targetDay = 14;
    if (cycles.isNotEmpty) {
      final lastCycle = cycles.last;
      final elapsed = DateTime.now().difference(lastCycle.startDate).inDays + 1;
      targetDay = ((elapsed - 1) % maxCycleLength) + 1;
    }

    final cycleLengths = cycles.map((c) => c.endDate.difference(c.startDate).inDays).toList();
    final double aiPredictedCycleLength = AIPredictionEngine.predictNextCycleLengthTrend(cycleLengths);
    final double aiCycleLengthSD = AIPredictionEngine.calculateStandardDeviation(cycleLengths, p.averageCycleLength.toDouble());
    final Map<String, double> aiSymptomProbabilities = AIPredictionEngine.predictSymptomProbabilities(
      historicalLogs: dailyLogModels,
      targetCycleDay: targetDay,
      maxCycleLength: maxCycleLength,
    );

    return PeriodLoaded(
      cycles: cycles,
      averageCycleLength: p.averageCycleLength,
      averagePeriodDuration: p.averagePeriodDuration,
      predictedNextStartDate: p.predictedNextStartDate,
      predictedNextEndDate: p.predictedNextEndDate,
      predictedFertilityStartDate: p.ovulationWindowStart,
      predictedFertilityEndDate: p.ovulationWindowEnd,
      aiPredictedCycleLength: aiPredictedCycleLength,
      aiCycleLengthStandardDeviation: aiCycleLengthSD,
      aiSymptomProbabilities: aiSymptomProbabilities,
    );
  }

  Future<void> _onLoadAllCycles(LoadAllCycles event, Emitter<PeriodState> emit) async {
    emit(PeriodLoading());
    final result = await getCyclesUseCase(const NoParams());
    await result.fold(
      (failure) async => emit(PeriodError(failure.message)),
      (cycles) async {
        final predResult = await predictCycleUseCase(cycles);
        await predResult.fold(
          (failure) async => emit(PeriodError(failure.message)),
          (p) async => emit(await _buildPeriodLoadedState(cycles: cycles, p: p)),
        );
      },
    );
  }

  Future<void> _onLogNewCycle(LogNewCycle event, Emitter<PeriodState> emit) async {
    emit(PeriodLoading());
    final saveResult = await saveCycleUseCase(SaveCycleParams(event.cycle));
    await saveResult.fold(
      (failure) async => emit(PeriodError(failure.message)),
      (_) async {
        final loadResult = await getCyclesUseCase(const NoParams());
        await loadResult.fold(
          (failure) async => emit(PeriodError(failure.message)),
          (cycles) async {
            final predResult = await predictCycleUseCase(cycles);
            await predResult.fold(
              (failure) async => emit(PeriodError(failure.message)),
              (p) async => emit(await _buildPeriodLoadedState(cycles: cycles, p: p)),
            );
          },
        );
      },
    );
  }

  Future<void> _onDeleteCycleRecord(DeleteCycleRecord event, Emitter<PeriodState> emit) async {
    emit(PeriodLoading());
    final deleteResult = await deleteCycleUseCase(DeleteCycleParams(event.id));
    await deleteResult.fold(
      (failure) async => emit(PeriodError(failure.message)),
      (_) async {
        final loadResult = await getCyclesUseCase(const NoParams());
        await loadResult.fold(
          (failure) async => emit(PeriodError(failure.message)),
          (cycles) async {
            final predResult = await predictCycleUseCase(cycles);
            await predResult.fold(
              (failure) async => emit(PeriodError(failure.message)),
              (p) async => emit(await _buildPeriodLoadedState(cycles: cycles, p: p)),
            );
          },
        );
      },
    );
  }
}

