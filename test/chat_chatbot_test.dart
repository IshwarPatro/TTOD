import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:thattimeofday/core/services/chat_learning_service.dart';
import 'package:thattimeofday/features/nutrients/domain/entities/nutrient_advice.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync();

  setUpAll(() async {
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Chatbot Self-Learning engine tests', () {
    setUp(() async {
      await ChatLearningService.clearAll();
      await ChatLearningService.initialize();
    });

    test('initializes default weights to 10', () {
      final weights = ChatLearningService.getWeights();
      expect(weights[ChatLearningService.catHydration], 10);
      expect(weights[ChatLearningService.catNutrition], 10);
      expect(weights[ChatLearningService.catRecovery], 10);
      expect(weights[ChatLearningService.catEnergy], 10);
    });

    test('positive reinforcement increases weights', () async {
      await ChatLearningService.reinforcePositive(ChatLearningService.catHydration);
      final weights = ChatLearningService.getWeights();
      expect(weights[ChatLearningService.catHydration], 12); // +2
      expect(weights[ChatLearningService.catNutrition], 10); // remains same
    });

    test('negative reinforcement decreases weights', () async {
      await ChatLearningService.reinforceNegative(ChatLearningService.catEnergy);
      final weights = ChatLearningService.getWeights();
      expect(weights[ChatLearningService.catEnergy], 9); // -1
    });

    test('generateRecommendation adjusts category weights with active symptoms', () {
      // If symptom is Severe Cramps -> recovery weight increases by 5
      final rec = ChatLearningService.generateRecommendation(
        phase: MenstrualPhase.menstrual,
        todaySymptoms: const ['Severe Cramps'],
      );

      expect(rec.containsKey('category'), isTrue);
      expect(rec.containsKey('text'), isTrue);
      expect(rec['text']!.isNotEmpty, isTrue);
    });
  });
}
