// lib/features/nutrients/domain/entities/recipe.dart
import 'package:equatable/equatable.dart';

class Recipe extends Equatable {
  final String id;
  final String title;
  final String phase; // Menstruation, Follicular, Ovulation, Luteal, Hydration
  final List<String> benefits;
  final List<String> ingredients;
  final List<String> directions;
  final bool isPremium;

  const Recipe({
    required this.id,
    required this.title,
    required this.phase,
    required this.benefits,
    required this.ingredients,
    required this.directions,
    required this.isPremium,
  });

  @override
  List<Object?> get props => [id, title, phase, benefits, ingredients, directions, isPremium];
}
