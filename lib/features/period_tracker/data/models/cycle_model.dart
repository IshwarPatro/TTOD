// lib/features/period_tracker/data/models/cycle_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/cycle.dart';

part 'cycle_model.g.dart';

@HiveType(typeId: 0)
class CycleModel extends Cycle {
  @HiveField(0)
  final String hiveId;

  @HiveField(1)
  final DateTime hiveStartDate;

  @HiveField(2)
  final DateTime hiveEndDate;

  @HiveField(3)
  final int flowIntensityIndex;

  @HiveField(4)
  final List<String> hiveSymptoms;

  const CycleModel({
    required this.hiveId,
    required this.hiveStartDate,
    required this.hiveEndDate,
    required this.flowIntensityIndex,
    required this.hiveSymptoms,
  }) : super(
          id: hiveId,
          startDate: hiveStartDate,
          endDate: hiveEndDate,
          flowIntensity: flowIntensityIndex == 0
              ? FlowIntensity.light
              : flowIntensityIndex == 1
                  ? FlowIntensity.medium
                  : FlowIntensity.heavy,
          symptoms: hiveSymptoms,
        );

  factory CycleModel.fromEntity(Cycle cycle) {
    return CycleModel(
      hiveId: cycle.id,
      hiveStartDate: cycle.startDate,
      hiveEndDate: cycle.endDate,
      flowIntensityIndex: cycle.flowIntensity.index,
      hiveSymptoms: cycle.symptoms,
    );
  }

  Cycle toEntity() {
    return Cycle(
      id: id,
      startDate: startDate,
      endDate: endDate,
      flowIntensity: flowIntensity,
      symptoms: symptoms,
    );
  }
}
