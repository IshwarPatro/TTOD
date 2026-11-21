import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/monetization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../period_tracker/domain/entities/cycle.dart';
import '../../../period_tracker/presentation/bloc/period_bloc.dart';
import '../../../period_tracker/presentation/bloc/period_state.dart';
import '../../data/datasources/recipes_data.dart';
import '../../domain/entities/nutrient_advice.dart';
import '../../domain/entities/recipe.dart';

class NutrientsTab extends StatefulWidget {
  const NutrientsTab({super.key});

  @override
  State<NutrientsTab> createState() => _NutrientsTabState();
}

class _NutrientsTabState extends State<NutrientsTab> {
  int _activeTopTab = 0; // 0 = For Your Phase, 1 = Recipes
  String _categoryFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isPremiumUnlocked = false;

  @override
  void initState() {
    super.initState();
    _isPremiumUnlocked = MonetizationService.isPremiumActive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshPremiumStatus() {
    setState(() {
      _isPremiumUnlocked = MonetizationService.isPremiumActive();
    });
  }

  Color _phaseColor(MenstrualPhase phase) {
    switch (phase) {
      case MenstrualPhase.menstrual:
        return AppColors.periodRose;
      case MenstrualPhase.follicular:
        return AppColors.ovulationSage;
      case MenstrualPhase.ovulatory:
        return AppColors.lutealAmber;
      case MenstrualPhase.luteal:
        return AppColors.primaryAccent2;
    }
  }

  Color _phaseSoftColor(MenstrualPhase phase) {
    switch (phase) {
      case MenstrualPhase.menstrual:
        return AppColors.periodRoseSoft;
      case MenstrualPhase.follicular:
        return AppColors.ovulationSageSoft;
      case MenstrualPhase.ovulatory:
        return AppColors.lutealAmberSoft;
      case MenstrualPhase.luteal:
        return AppColors.surfaceSubtle;
    }
  }

  Color _phaseColorByString(String phaseStr) {
    switch (phaseStr) {
      case 'Menstruation':
        return AppColors.periodRose;
      case 'Follicular':
        return AppColors.ovulationSage;
      case 'Ovulation':
        return AppColors.lutealAmber;
      case 'Luteal':
        return AppColors.primaryAccent2;
      default:
        return AppColors.primaryAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeriodBloc, PeriodState>(
      builder: (context, state) {
        MenstrualPhase currentPhase = MenstrualPhase.follicular;
        String cycleStatusText = "Log a period to tailor advice to your current cycle day.";

        if (state is PeriodLoaded && state.cycles.isNotEmpty) {
          final sorted = List<Cycle>.from(state.cycles)
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          final latestCycle = sorted.last;
          final today = DateTime.now();
          final startOnly = DateTime(latestCycle.startDate.year, latestCycle.startDate.month, latestCycle.startDate.day);
          final todayOnly = DateTime(today.year, today.month, today.day);

          final elapsedDays = todayOnly.difference(startOnly).inDays + 1;
          final cycleLength = state.averageCycleLength > 0 ? state.averageCycleLength : 28;
          final normalizedDay = elapsedDays > 0 ? ((elapsedDays - 1) % cycleLength) + 1 : 1;

          currentPhase = NutrientAdvice.getPhaseFromDayOfCycle(normalizedDay);
          cycleStatusText = "Day $normalizedDay of your $cycleLength-day cycle";
        }

        final advice = NutrientAdvice.getAdviceForPhase(currentPhase);
        final phaseHeadline = NutrientAdvice.phaseToHumanString(advice.phase);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSegmentButton(0, "For Your Phase"),
                    _buildSegmentButton(1, "Recipes"),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _activeTopTab == 0
                  ? _buildAdvisorView(advice, phaseHeadline, cycleStatusText)
                  : _buildCookbookView(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final active = _activeTopTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTopTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.onPrimary : AppColors.onBackground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorView(NutrientAdvice advice, String phaseHeadline, String cycleStatusText) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cycleStatusText,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _phaseSoftColor(advice.phase),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    phaseHeadline,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _phaseColor(advice.phase),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  advice.title,
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  advice.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const Divider(color: AppColors.outlineVariant, height: 28),
                Text(
                  "Foods to Enjoy",
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: advice.recommendedFoods.map((food) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Text(
                        food,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onBackground),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(color: AppColors.outlineVariant, height: 28),
                Text(
                  "Key Nutrients",
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: advice.keyNutrients.map((nutrient) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _phaseSoftColor(advice.phase),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        nutrient,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _phaseColor(advice.phase),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookbookView() {
    final filtered = RecipesData.recipes.where((recipe) {
      final matchesCategory = _categoryFilter == 'All' || recipe.phase == _categoryFilter;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          recipe.title.toLowerCase().contains(q) ||
          recipe.ingredients.any((ing) => ing.toLowerCase().contains(q));
      return matchesCategory && matchesSearch;
    }).toList();

    const phases = ['All', 'Menstruation', 'Follicular', 'Ovulation', 'Luteal', 'Hydration'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.onSurfaceVariant),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              hintText: "Search recipes or ingredients...",
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
              fillColor: AppColors.cardBackground,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: phases.length,
            itemBuilder: (context, idx) {
              final ph = phases[idx];
              final isSel = _categoryFilter == ph;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(ph),
                  selected: isSel,
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _categoryFilter = ph);
                  },
                  selectedColor: _phaseColorByString(ph),
                  backgroundColor: AppColors.cardBackground,
                  side: BorderSide(
                    color: isSel ? _phaseColorByString(ph) : AppColors.outline,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSel ? AppColors.onPrimary : AppColors.onBackground,
                  ),
                ),
              );
            },
          ),
        ),
        if (!_isPremiumUnlocked)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.periodRose, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Unlock All 100 Recipes",
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Text(
                          "Phase-matched meals & drinks",
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _showUpgradeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text("Unlock", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "${filtered.length} recipes",
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final recipe = filtered[index];
              final isLocked = recipe.isPremium && !_isPremiumUnlocked;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    onTap: () => isLocked ? _showUpgradeDialog() : _showRecipeDetails(recipe),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _phaseColorByString(recipe.phase).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline : Icons.restaurant_menu,
                        size: 18,
                        color: _phaseColorByString(recipe.phase),
                      ),
                    ),
                    title: Text(
                      recipe.title,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                    ),
                    subtitle: Text(
                      "${recipe.phase} · ${recipe.benefits.first}",
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.onSurfaceVariant),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _phaseColorByString(recipe.phase).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          recipe.phase,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _phaseColorByString(recipe.phase),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.title,
                    style: GoogleFonts.sora(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.benefits
                        .map((b) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Text(b, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onBackground)),
                            ))
                        .toList(),
                  ),
                  const Divider(color: AppColors.outlineVariant, height: 26),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          "Ingredients",
                          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                        ),
                        const SizedBox(height: 8),
                        ...recipe.ingredients.map((ing) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: Icon(Icons.check_circle_outline, size: 16, color: AppColors.ovulationSage),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(ing, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground)),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(color: AppColors.outlineVariant, height: 28),
                        Text(
                          "Directions",
                          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                        ),
                        const SizedBox(height: 8),
                        ...recipe.directions.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.surfaceSubtle,
                                  child: Text(
                                    "${entry.key + 1}",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.onBackground,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            "Unlock Full Cookbook",
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Get lifetime access to all 100 phase-matched recipes curated for every stage of your cycle.",
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Lifetime Access", style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text("\$4.99", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.periodRose)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Not now", style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await MonetizationService.purchasePremiumMock();
                if (success && mounted) {
                  _refreshPremiumStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cookbook unlocked!")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Unlock", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
