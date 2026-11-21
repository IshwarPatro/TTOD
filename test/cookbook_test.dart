import 'package:flutter_test/flutter_test.dart';
import 'package:thattimeofday/features/nutrients/data/datasources/recipes_data.dart';

void main() {
  group('Cookbook Dataset Integrity Tests', () {
    test('Verify total count is exactly 100 recipes', () {
      final recipes = RecipesData.recipes;
      expect(recipes.length, 100);
    });

    test('Verify category list distribution is equal (20 per category)', () {
      final recipes = RecipesData.recipes;
      final stages = ['Menstruation', 'Follicular', 'Ovulation', 'Luteal', 'Hydration'];
      
      for (final st in stages) {
        final count = recipes.where((r) => r.phase == st).length;
        expect(count, 20, reason: "Stage $st must have exactly 20 recipes");
      }
    });

    test('Verify monetization locks: first 4 in each category are Free (total 20), rest 16 are Premium (total 80)', () {
      final recipes = RecipesData.recipes;
      final stages = ['Menstruation', 'Follicular', 'Ovulation', 'Luteal', 'Hydration'];

      for (final st in stages) {
        final categoryRecipes = recipes.where((r) => r.phase == st).toList();
        for (int i = 0; i < 20; i++) {
          final r = categoryRecipes[i];
          if (i < 4) {
            expect(r.isPremium, isFalse, reason: "Recipe #${i} of $st must be FREE");
          } else {
            expect(r.isPremium, isTrue, reason: "Recipe #${i} of $st must be PREMIUM");
          }
        }
      }
    });
  });
}
