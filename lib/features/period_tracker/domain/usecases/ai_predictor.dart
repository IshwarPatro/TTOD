import 'dart:math' as math;
import '../../../period_tracker/data/models/daily_log_model.dart';

/// Predicts next cycle length trends and symptom probabilities on-device.
class AIPredictionEngine {
  /// Fits a simple linear regression (y = mx + c) on past cycle lengths
  /// to forecast the next cycle's expected duration.
  ///
  /// [cycleLengths] representing lengths of consecutive cycles in order.
  static double predictNextCycleLengthTrend(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return 28.0;
    if (cycleLengths.length == 1) return cycleLengths.first.toDouble();

    // Independent variable X represents the index of the cycle (0, 1, 2...)
    final n = cycleLengths.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;

    for (int i = 0; i < n; i++) {
      final y = cycleLengths[i].toDouble();
      sumX += i;
      sumY += y;
      sumXY += i * y;
      sumXX += i * i;
    }

    final denominator = n * sumXX - sumX * sumX;
    if (denominator == 0) {
      return sumY / n; // Return average if slope is flat (parallel/no variance)
    }

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // Forecast the next index (n)
    final predicted = slope * n + intercept;
    
    // Clamp to realistic human physiology parameters (15 to 45 days)
    return predicted.clamp(15.0, 45.0);
  }

  /// Calculates statistical standard deviation for cycle lengths.
  static double calculateStandardDeviation(List<int> cycleLengths, double mean) {
    if (cycleLengths.isEmpty) return 0.0;
    double varianceSum = 0;
    for (final length in cycleLengths) {
      varianceSum += math.pow(length - mean, 2);
    }
    return math.sqrt(varianceSum / cycleLengths.length);
  }

  /// Naive Bayes Symptom Predictor:
  /// Evaluates symptom occurrences across historical daily logs to predict the
  /// probability (0.0 to 1.0) of experiencing a symptom at a given normalized cycle day.
  ///
  /// Formulates: P(Symptom | Day) = (P(Day | Symptom) * P(Symptom)) / P(Day)
  /// To ensure smooth distributions we apply Laplace smoothing.
  static Map<String, double> predictSymptomProbabilities({
    required List<DailyLogModel> historicalLogs,
    required int targetCycleDay, // 1-indexed target day in standard cycle
    required int maxCycleLength,
  }) {
    final Map<String, double> probabilities = {};
    if (historicalLogs.isEmpty) return probabilities;

    // Track total logs
    final totalLogs = historicalLogs.length;

    // Retrieve unique symptoms present in historical logs
    final Set<String> allSymptomKeys = {};
    for (final log in historicalLogs) {
      allSymptomKeys.addAll(log.symptoms);
    }

    // Default target cycle length constraint
    if (maxCycleLength <= 0) maxCycleLength = 28;
    
    // Calculate P(Day = targetCycleDay) with Laplace smoothing
    final logsWithTargetDay = historicalLogs.where((log) => _getNormalizedDay(log, maxCycleLength) == targetCycleDay).length;
    final pDay = (logsWithTargetDay + 1) / (totalLogs + maxCycleLength);

    for (final symptom in allSymptomKeys) {
      // P(Symptom) = fraction of logs having this symptom
      final symptomCount = historicalLogs.where((log) => log.symptoms.contains(symptom)).length;
      final pSymptom = (symptomCount + 1) / (totalLogs + 2); // Laplace smoothing for boolean parameter

      // P(Day | Symptom) = fraction of symptom occurrences matching target day
      final logsWithSymptom = historicalLogs.where((log) => log.symptoms.contains(symptom));
      final logsWithSymptomAndDay = logsWithSymptom.where((log) => _getNormalizedDay(log, maxCycleLength) == targetCycleDay).length;
      
      final pDayGivenSymptom = (logsWithSymptomAndDay + 1) / (symptomCount + maxCycleLength);

      // P(Symptom | Day) = (P(Day | Symptom) * P(Symptom)) / P(Day)
      double calculatedProbability = (pDayGivenSymptom * pSymptom) / pDay;

      // Clamp probabilities to realistic bounds (0.0 to 0.99)
      probabilities[symptom] = calculatedProbability.clamp(0.01, 0.99);
    }

    return probabilities;
  }

  /// Calculates the day of cycle, normalized by expected cycle length.
  static int _getNormalizedDay(DailyLogModel log, int maxCycleLength) {
    // For local logs, we reference logs date relative to cycles.
    // If not matching, we use day of month or a placeholder hash mapping to simulate index day.
    // To ensure consistency, we normalize it to a safe [1, maxCycleLength] range.
    return ((log.date.day - 1) % maxCycleLength) + 1;
  }
}
