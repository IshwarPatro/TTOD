import 'package:flutter_test/flutter_test.dart';
import 'package:thattimeofday/features/period_tracker/domain/usecases/ai_predictor.dart';
import 'package:thattimeofday/features/period_tracker/data/models/daily_log_model.dart';

void main() {
  group('AIPredictionEngine Tests', () {
    test('predictNextCycleLengthTrend - empty falls back to 28', () {
      final res = AIPredictionEngine.predictNextCycleLengthTrend([]);
      expect(res, 28.0);
    });

    test('predictNextCycleLengthTrend - single element trend', () {
      final res = AIPredictionEngine.predictNextCycleLengthTrend([30]);
      expect(res, 30.0);
    });

    test('predictNextCycleLengthTrend - linear trend calculation', () {
      // Index 0: 26, Index 1: 28, Index 2: 30
      // Expected next index (3): 32
      final res = AIPredictionEngine.predictNextCycleLengthTrend([26, 28, 30]);
      expect(res, 32.0);
    });

    test('calculateStandardDeviation - returns correct standard deviation', () {
      final res = AIPredictionEngine.calculateStandardDeviation([26, 28, 30], 28.0);
      // Mean 28. Variance = ((26-28)^2 + (28-28)^2 + (30-28)^2)/3 = (4 + 0 + 4)/3 = 8/3 = 2.666
      // SD = sqrt(2.666) ~= 1.63
      expect(res, closeTo(1.63, 0.05));
    });

    test('predictSymptomProbabilities - naive bayes probability calculations', () {
      final log1 = DailyLogModel(
        hiveId: '1',
        hiveDate: DateTime(2026, 8, 14), // Suppose day 14 has cramps
        hiveSymptoms: const ['cramps', 'fatigue'],
        hiveWaterIntakeMl: 1000,
      );
      final log2 = DailyLogModel(
        hiveId: '2',
        hiveDate: DateTime(2026, 8, 15), // Suppose day 15 has fatigue
        hiveSymptoms: const ['fatigue'],
        hiveWaterIntakeMl: 1200,
      );

      final probs = AIPredictionEngine.predictSymptomProbabilities(
        historicalLogs: [log1, log2],
        targetCycleDay: 14,
        maxCycleLength: 28,
      );

      // Verify that it calculates probabilities successfully
      expect(probs.containsKey('cramps'), isTrue);
      expect(probs.containsKey('fatigue'), isTrue);
      expect(probs['cramps'], greaterThan(0.0));
      expect(probs['fatigue'], greaterThan(0.0));
    });
  });
}
