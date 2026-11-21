// lib/features/period_tracker/data/models/daily_log_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/cycle.dart';

part 'daily_log_model.g.dart';

@HiveType(typeId: 1)
class DailyLogModel extends DailyLog {
  @HiveField(0)
  final String hiveId;

  @HiveField(1)
  final DateTime hiveDate;

  @HiveField(2)
  final int? flowIntensityIndex;

  @HiveField(3)
  final List<String> hiveSymptoms;

  @HiveField(4)
  final int hiveWaterIntakeMl;

  const DailyLogModel({
    required this.hiveId,
    required this.hiveDate,
    this.flowIntensityIndex,
    required this.hiveSymptoms,
    required this.hiveWaterIntakeMl,
  }) : super(
          id: hiveId,
          date: hiveDate,
          flowIntensity: flowIntensityIndex == null
              ? null
              : flowIntensityIndex == 0
                  ? FlowIntensity.light
                  : flowIntensityIndex == 1
                      ? FlowIntensity.medium
                      : FlowIntensity.heavy,
          symptoms: hiveSymptoms,
          waterIntakeMl: hiveWaterIntakeMl,
        );

  factory DailyLogModel.fromEntity(DailyLog log) {
    return DailyLogModel(
      hiveId: log.id,
      hiveDate: log.date,
      flowIntensityIndex: log.flowIntensity?.index,
      hiveSymptoms: log.symptoms,
      hiveWaterIntakeMl: log.waterIntakeMl,
    );
  }

  DailyLog toEntity() {
    return DailyLog(
      id: id,
      date: date,
      flowIntensity: flowIntensity,
      symptoms: symptoms,
      waterIntakeMl: waterIntakeMl,
    );
  }
}
