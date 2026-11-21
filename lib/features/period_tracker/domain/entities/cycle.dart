// lib/features/period_tracker/domain/entities/cycle.dart
import 'package:equatable/equatable.dart';

enum FlowIntensity { light, medium, heavy }

class Cycle extends Equatable {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final FlowIntensity flowIntensity;
  final List<String> symptoms;

  const Cycle({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.flowIntensity,
    required this.symptoms,
  });

  @override
  List<Object?> get props => [id, startDate, endDate, flowIntensity, symptoms];

  int get durationInDays => endDate.difference(startDate).inDays + 1;
}
