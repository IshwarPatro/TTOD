// lib/features/nutrients/domain/entities/nutrient_advice.dart
import 'package:equatable/equatable.dart';

enum MenstrualPhase { menstrual, follicular, ovulatory, luteal }

class NutrientAdvice extends Equatable {
  final MenstrualPhase phase;
  final String title;
  final String description;
  final List<String> recommendedFoods;
  final List<String> keyNutrients;

  const NutrientAdvice({
    required this.phase,
    required this.title,
    required this.description,
    required this.recommendedFoods,
    required this.keyNutrients,
  });

  @override
  List<Object?> get props => [phase, title, description, recommendedFoods, keyNutrients];

  static String phaseToHumanString(MenstrualPhase phase) {
    switch (phase) {
      case MenstrualPhase.menstrual:
        return 'Menstrual Phase (Days 1-5)';
      case MenstrualPhase.follicular:
        return 'Follicular Phase (Days 6-11)';
      case MenstrualPhase.ovulatory:
        return 'Ovulatory Phase (Days 12-16)';
      case MenstrualPhase.luteal:
        return 'Luteal Phase (Days 17-28)';
    }
  }

  static NutrientAdvice getAdviceForPhase(MenstrualPhase phase) {
    switch (phase) {
      case MenstrualPhase.menstrual:
        return const NutrientAdvice(
          phase: MenstrualPhase.menstrual,
          title: "Replenish & Restore",
          description: "Focus on replacing iron lost during menstruation and keeping energy levels stable with warming, comforting meals.",
          recommendedFoods: ["Spinach", "Lentils", "Red Meat", "Pumpkin Seeds", "Salmon", "Ginger Tea"],
          keyNutrients: ["Iron", "Vitamin B12", "Omega-3", "Magnesium"],
        );
      case MenstrualPhase.follicular:
        return const NutrientAdvice(
          phase: MenstrualPhase.follicular,
          title: "Energize & Build",
          description: "Estrogen is rising. Support healthy follicle development and hormone metabolism with light, fresh, fiber-rich, and fermented foods.",
          recommendedFoods: ["Broccoli", "Kimchi", "Sauerkraut", "Oats", "Avocado", "Chicken", "Grapefruit"],
          keyNutrients: ["Probiotics", "Fiber", "Zinc", "Vitamin C"],
        );
      case MenstrualPhase.ovulatory:
        return const NutrientAdvice(
          phase: MenstrualPhase.ovulatory,
          title: "Vibrant & Hydrated",
          description: "Estrogen peaks. Support liver detoxification of hormones and maintain high energy using raw veg, fruits, and antioxidants.",
          recommendedFoods: ["Quinoa", "Berries", "Leafy Greens", "Walnuts", "Chia Seeds", "Bell Peppers", "Eggs"],
          keyNutrients: ["Antioxidants", "Folate", "Fiber", "Surfactants"],
        );
      case MenstrualPhase.luteal:
        return const NutrientAdvice(
          phase: MenstrualPhase.luteal,
          title: "Calm & Balance",
          description: "Progesterone dominates. Beat water retention, sugar cravings, and PMS symptoms with complex carbohydrates, magnesium, and healthy fats.",
          recommendedFoods: ["Sweet Potatoes", "Dark Chocolate (70%+)", "Bananas", "Nuts", "Brown Rice", "Camomile Tea"],
          keyNutrients: ["Magnesium", "Vitamin B6", "Complex Carbs", "Potassium"],
        );
    }
  }

  static MenstrualPhase getPhaseFromDayOfCycle(int day) {
    if (day >= 1 && day <= 5) return MenstrualPhase.menstrual;
    if (day >= 6 && day <= 11) return MenstrualPhase.follicular;
    if (day >= 12 && day <= 16) return MenstrualPhase.ovulatory;
    return MenstrualPhase.luteal;
  }
}
