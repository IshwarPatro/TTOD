// lib/features/period_tracker/domain/entities/daily_log.dart
import 'package:equatable/equatable.dart';
import 'cycle.dart';

class DailyLog extends Equatable {
  final String id;
  final DateTime date;
  final FlowIntensity? flowIntensity;
  final List<String> symptoms;
  final int waterIntakeMl;

  const DailyLog({
    required this.id,
    required this.date,
    this.flowIntensity,
    required this.symptoms,
    this.waterIntakeMl = 0,
  });

  @override
  List<Object?> get props => [id, date, flowIntensity, symptoms, waterIntakeMl];
}
