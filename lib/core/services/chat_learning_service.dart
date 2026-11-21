// lib/core/services/chat_learning_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../features/nutrients/domain/entities/nutrient_advice.dart';

class ChatLearningService {
  static const String _boxName = 'chatbot_weights_box';
  static Box? _box;

  // Categories of recommendations
  static const String catHydration = 'hydration';
  static const String catNutrition = 'nutrition';
  static const String catRecovery = 'recovery';
  static const String catEnergy = 'energy';

  static const List<String> categories = [
    catHydration,
    catNutrition,
    catRecovery,
    catEnergy,
  ];

  /// Initializes the Hive box for chatbot learning weights.
  static Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    
    // Seed default baseline weights (value of 10) if empty
    for (final cat in categories) {
      if (_box!.get(cat) == null) {
        await _box!.put(cat, 10);
      }
    }
  }

  /// Gets the current learning weights for each category.
  static Map<String, int> getWeights() {
    if (_box == null) {
      return {for (var cat in categories) cat: 10};
    }
    return {
      for (var cat in categories)
        cat: (_box!.get(cat, defaultValue: 10) as int),
    };
  }

  /// Reinforce weight positively upon user liking/logging suggestion.
  static Future<void> reinforcePositive(String category) async {
    if (_box == null) return;
    final curr = _box!.get(category, defaultValue: 10) as int;
    await _box!.put(category, curr + 2); // incremental boost
    debugPrint("AI Chatbot Self-Learnt (+$category): New Weight = ${curr + 2}");
  }

  /// Reinforce weight negatively when user flags unhelpful.
  static Future<void> reinforceNegative(String category) async {
    if (_box == null) return;
    final curr = _box!.get(category, defaultValue: 10) as int;
    final newVal = max(2, curr - 1); // decrement, min limit 2
    await _box!.put(category, newVal);
    debugPrint("AI Chatbot Self-Learnt (-$category): New Weight = $newVal");
  }

  /// Generates a recommendation based on active phase, symptoms, and self-learning weights.
  static Map<String, String> generateRecommendation({
    required MenstrualPhase phase,
    required List<String> todaySymptoms,
  }) {
    final weights = getWeights();

    // Adjust temporary evaluation weights based on active symptoms
    final evalWeights = Map<String, int>.from(weights);
    if (todaySymptoms.isNotEmpty) {
      for (final sym in todaySymptoms) {
        final lowSym = sym.toLowerCase();
        if (lowSym.contains('cramp') || lowSym.contains('pain') || lowSym.contains('back')) {
          evalWeights[catRecovery] = evalWeights[catRecovery]! + 5; 
          evalWeights[catNutrition] = evalWeights[catNutrition]! + 2;
        }
        if (lowSym.contains('bloat') || lowSym.contains('digest')) {
          evalWeights[catHydration] = evalWeights[catHydration]! + 4;
          evalWeights[catNutrition] = evalWeights[catNutrition]! + 3;
        }
        if (lowSym.contains('fatigue') || lowSym.contains('tired') || lowSym.contains('low energy')) {
          evalWeights[catEnergy] = evalWeights[catEnergy]! + 4;
          evalWeights[catRecovery] = evalWeights[catRecovery]! + 3;
        }
        if (lowSym.contains('headache') || lowSym.contains('migraine')) {
          evalWeights[catHydration] = evalWeights[catHydration]! + 5;
          evalWeights[catRecovery] = evalWeights[catRecovery]! + 3;
        }
      }
    }

    // Pick top weighted category (adds slight randomness to avoid repetitive loop)
    final totalWeight = evalWeights.values.fold(0, (sum, w) => sum + w);
    final randomVal = Random().nextInt(totalWeight == 0 ? 1 : totalWeight);

    String chosenCategory = catRecovery;
    int accumulator = 0;
    for (final entry in evalWeights.entries) {
      accumulator += entry.value;
      if (randomVal < accumulator) {
        chosenCategory = entry.key;
        break;
      }
    }

    // Get recommendations pool
    final pool = _getRecommendationsPool(phase);
    final text = pool[chosenCategory] ?? "Please prioritize rest and stay hydrated today.";
    
    return {
      'category': chosenCategory,
      'text': text,
    };
  }

  static Map<String, String> _getRecommendationsPool(MenstrualPhase phase) {
    switch (phase) {
      case MenstrualPhase.menstrual:
        return {
          catHydration: "Hydrate: Drink warm ginger-lemon water to ease cramps and reduce inflammation.",
          catNutrition: "Nutrition: Eat dark chocolate (70%+) or pumpkin seeds to replenish lost magnesium.",
          catRecovery: "Recovery: Apply a warm heating pad to your lower back and rest. Skip heavy tasks.",
          catEnergy: "Energy: Keep activities exceptionally light. Focus on gentle box-breathing exercises.",
        };
      case MenstrualPhase.follicular:
        return {
          catHydration: "Hydrate: Sip green tea or electrolyte water to fuel rising estrogen and energy levels.",
          catNutrition: "Nutrition: Incorporate fermented foods like kimchi or kefir to support estrogen metabolism.",
          catRecovery: "Recovery: Your cognitive focus is peak. Perfect time for journaling or planning projects.",
          catEnergy: "Energy: Fuel your stamina with a jog or full-body dumbbell workout.",
        };
      case MenstrualPhase.ovulatory:
        return {
          catHydration: "Hydrate: Aim for at least 2.5L of pure filtered water. Cellular repair needs water support.",
          catNutrition: "Nutrition: Eat fiber-rich broccoli and brussels sprouts to assist liver clearance of estrogen.",
          catRecovery: "Recovery: Balance peak social energy with deep, restorative sleep in a cool room.",
          catEnergy: "Energy: Estrogen is peak! Go for a HIIT training session or high-density cardio.",
        };
      case MenstrualPhase.luteal:
        return {
          catHydration: "Hydrate: Drink warm dandelion or hibiscus tea to reduce water retention bloating.",
          catNutrition: "Nutrition: Eat complex carbs (sweet potatoes or brown rice) to avoid blood sugar crashes.",
          catRecovery: "Recovery: Take a soothing Epsom salt bath to ease lower back tension and alleviate anxiety.",
          catEnergy: "Energy: Phase out high-intensity workouts. Move to restorative yoga or walk in nature.",
        };
    }
  }

  /// Purges local weights (reset function).
  static Future<void> clearAll() async {
    if (_box != null) {
      await _box!.clear();
    }
  }
}
