// lib/features/nutrients/data/datasources/recipes_data.dart
import '../../domain/entities/recipe.dart';

class RecipesData {
  static final List<Recipe> recipes = _generate100Recipes();

  static List<Recipe> _generate100Recipes() {
    final List<Recipe> list = [];
    
    final categories = [
      _RecipeTemplate(
        phase: 'Menstruation',
        baseFoods: [
          'Iron-Rich Spinach Soup', 
          'Black Bean Chili', 
          'Grilled Wild Salmon', 
          'Red Lentil Curry', 
          'Cooked Beets Salad', 
          'Grass-fed Sirloin Bowl', 
          'Steamed Garlic Broccoli', 
          'Chia Seed Recovery Pudding', 
          'Roasted Pumpkin Seeds', 
          'Dark Chocolate Mousse'
        ],
        ingredientsTemplate: (food) => [food, 'Cold-pressed Olive Oil', 'Minced Garlic', 'Pink Himalayan Salt', 'Fresh Lemon Juice', 'Black Pepper'],
        directionsTemplate: (title) => [
          'Clean and chop all ingredients carefully.',
          'Sauté garlic in olive oil on medium heat in a pan.',
          'Stir in the base ingredents and simmer for 15 minutes.',
          'Garnish with lemon juice and serve warm to naturally alleviate uterine cramps.'
        ],
        benefits: ['Replenishes iron loss', 'Decreases inflammatory markers', 'Soothes cramp discomfort']
      ),
      _RecipeTemplate(
        phase: 'Follicular',
        baseFoods: [
          'Quinoa Power Salad', 
          'Cashew Rolled Oats', 
          'Probiotic Coconut Yogurt', 
          'Sprouted Toast with Egg', 
          'Kimchi Vegetable Stir-fry', 
          'Fresh Flaxseed Porridge', 
          'Citrus Asparagus Spears', 
          'Smashed Avocado Plate', 
          'Organic Tofu Scramble', 
          'Sesame Kale Bowls'
        ],
        ingredientsTemplate: (food) => [food, 'Golden Flaxseeds', 'Raw Honey', 'Apple Cider Vinegar', 'Fresh Mint Leaves', 'Himalayan Salt'],
        directionsTemplate: (title) => [
          'Combine the raw baseline ingredients in a bowl.',
          'Mix thoroughly with cold-pressed oils or probiotic yogurt bases.',
          'Top with grounded high-fiber seeds and mint leaves.',
          'Enjoy as a fresh, low-glycemic breakfast or quick lunch.'
        ],
        benefits: ['Builds healthy estrogen', 'Optimizes gut microbiome health', 'Sustains energy curves']
      ),
      _RecipeTemplate(
        phase: 'Ovulation',
        baseFoods: [
          'Pumpkin Seed Hummus Plate', 
          'Red Lentil fusilli Pasta', 
          'Millet Medley with Herbs', 
          'Seared Halibut Fillets', 
          'Zinc-rich Pecan Granola', 
          'Roasted Brussels Sprouts', 
          'Chilled Mango Berry smoothie', 
          'Basil Pesto Zucchini Ribbon', 
          'Sunflower Crunch Lettuce wrap', 
          'Sesame Crusted Salmon'
        ],
        ingredientsTemplate: (food) => [food, 'Sunflower Seed Butter', 'Extra Virgin Olive Oil', 'Garlic Paste', 'Crumbled Feta Cheese', 'Sprouts'],
        directionsTemplate: (title) => [
          'Preheat oven or cooking pan to medium temperature.',
          'Toss the active ingredients with olive oil and spices.',
          'Bake or stir until crispy on active edges.',
          'Serve with sprouts and sunflower seed toppings to assist with cellular energy.'
        ],
        benefits: ['Aids LH hormone production', 'Supplies bioavailable zinc', 'Promotes follicle vitality']
      ),
      _RecipeTemplate(
        phase: 'Luteal',
        baseFoods: [
          'Baked Sweet Potato boat', 
          'Brown Rice Stir-fry', 
          'Ginger Turmeric vegetable Broth', 
          'Miso Cauliflower Mash', 
          'Chickpea Vegetable Curry', 
          'Sautéed Kelp Salad', 
          'Root Vegetable Stew', 
          'Roasted Turkey Breast Slice', 
          'Carrot Ginger puree', 
          'Roasted Butternut Squash'
        ],
        ingredientsTemplate: (food) => [food, 'Fresh Ginger Slices', 'Turmeric Powder', 'Coconut Aminos', 'Black Pepper', 'Toasted Sesame Oil'],
        directionsTemplate: (title) => [
          'Cut vegetables into even cubes.',
          'Roast or cook at low heat to retain vital water soluble vitamins.',
          'Stir-in turmeric, ginger, sesame oil, and black pepper.',
          'Consume warm to combat luteal fluid retention and support progesterone.'
        ],
        benefits: ['Supports progesterone synthesis', 'Fights water retention & bloating', 'Prevents sugar cravings']
      ),
      _RecipeTemplate(
        phase: 'Hydration',
        baseFoods: [
          'Cucumber Watermelon Coolers', 
          'Coconut Mint Electrolyte drinks', 
          'Infused Mint Leaves Seltzer', 
          'Celery Ginger squeeze', 
          'Salted Citrus hydration boost', 
          'Aloe Cranberry refresher', 
          'Warm Fennel Seed tea', 
          'Strawberry Basil hydration mix', 
          'Pineapple Lime cooler', 
          'Grapefruit Rosemary splash'
        ],
        ingredientsTemplate: (food) => [food, 'Pure Coconut Water', 'Himalayan Pink Salt', 'Filtered Spring Water', 'Fresh Squeezed Lime juice'],
        directionsTemplate: (title) => [
          'Blend or press the fresh fruits and herbs.',
          'Stir in coconut water and pinch of Himalayan pink salt.',
          'Serve chilled over crushed ice blocks.',
          'Sip throughout the day to offset physical dehydration symptoms.'
        ],
        benefits: ['Restores intracellular hydration', 'Supplies broad-spectrum electrolytes', 'Balances fluid pressure']
      ),
    ];

    int globalId = 1;
    for (final template in categories) {
      for (int i = 0; i < 20; i++) {
        final baseFood = template.baseFoods[i % template.baseFoods.length];
        
        final prefixes = [
          'Premium', 'Nourishing', 'Signature', 'Vibrant', 'Optimal',
          'Healing', 'Warming', 'Enriched', 'Essential', 'Restorative',
          'Holistic', 'Balanced', 'Daily', 'Pure', 'Dynamic',
          'Anti-inflammatory', 'Zesty', 'Calming', 'Fortified', 'Supreme'
        ];
        final prefix = prefixes[i % prefixes.length];
        
        final title = '$prefix $baseFood';
        final isPremium = i >= 4; // First 4 are Free (total 20), rest 16 are Premium (total 80) = 100 recipes!

        list.add(Recipe(
          id: 'recipe_$globalId',
          title: title,
          phase: template.phase,
          benefits: template.benefits,
          ingredients: template.ingredientsTemplate(baseFood),
          directions: template.directionsTemplate(title),
          isPremium: isPremium,
        ));
        globalId++;
      }
    }
    return list;
  }
}

class _RecipeTemplate {
  final String phase;
  final List<String> baseFoods;
  final List<String> Function(String baseFood) ingredientsTemplate;
  final List<String> Function(String title) directionsTemplate;
  final List<String> benefits;

  _RecipeTemplate({
    required this.phase,
    required this.baseFoods,
    required this.ingredientsTemplate,
    required this.directionsTemplate,
    required this.benefits,
  });
}
