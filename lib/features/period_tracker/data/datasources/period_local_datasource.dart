// lib/features/period_tracker/data/datasources/period_local_datasource.dart
import 'package:hive/hive.dart';
import '../models/cycle_model.dart';
import '../models/daily_log_model.dart';

abstract class PeriodLocalDataSource {
  Future<List<CycleModel>> getCycles();
  Future<void> cacheCycle(CycleModel cycle);
  Future<void> deleteCycle(String id);
  Future<List<DailyLogModel>> getDailyLogs();
}

class PeriodLocalDataSourceImpl implements PeriodLocalDataSource {
  final Box<CycleModel> cycleBox;
  final Box<DailyLogModel> dailyLogsBox;

  PeriodLocalDataSourceImpl({
    required this.cycleBox,
    required this.dailyLogsBox,
  });

  @override
  Future<List<CycleModel>> getCycles() async {
    try {
      return cycleBox.values.toList();
    } catch (e) {
      throw Exception("Failed to read from Hive box: ${e.toString()}");
    }
  }

  @override
  Future<void> cacheCycle(CycleModel cycle) async {
    try {
      await cycleBox.put(cycle.id, cycle);
    } catch (e) {
      throw Exception("Failed to write to Hive box: ${e.toString()}");
    }
  }

  @override
  Future<void> deleteCycle(String id) async {
    try {
      await cycleBox.delete(id);
    } catch (e) {
      throw Exception("Failed to delete from Hive box: ${e.toString()}");
    }
  }

  @override
  Future<List<DailyLogModel>> getDailyLogs() async {
    try {
      return dailyLogsBox.values.toList();
    } catch (e) {
      throw Exception("Failed to read daily logs from Hive box: ${e.toString()}");
    }
  }
}
