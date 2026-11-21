import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../nutrients/domain/entities/nutrient_advice.dart';
import '../../domain/entities/cycle.dart';
import '../bloc/period_bloc.dart';
import '../bloc/period_event.dart';
import '../bloc/period_state.dart';

class PeriodTrackerTab extends StatelessWidget {
  const PeriodTrackerTab({super.key});

  static const _shortMonths = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  static String _formatShortDate(DateTime date) {
    return "${_shortMonths[date.month - 1]} ${date.day}";
  }

  static String _formatFullDate(DateTime date) {
    return "${_shortMonths[date.month - 1]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeriodBloc, PeriodState>(
      builder: (context, state) {
        if (state is PeriodLoading || state is PeriodInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }
        if (state is PeriodError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "Could not load cycles: ${state.message}",
                style: GoogleFonts.inter(color: AppColors.errorRed),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (state is PeriodLoaded) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSummaryCard(context, state),
                const SizedBox(height: 16),
                CustomPeriodCalendar(
                  cycles: state.cycles,
                  predictedStart: state.predictedNextStartDate,
                  predictedEnd: state.predictedNextEndDate,
                  ovulationStart: state.predictedFertilityStartDate,
                  ovulationEnd: state.predictedFertilityEndDate,
                ),
                const SizedBox(height: 16),
                _buildInsightsCard(state),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Cycle History",
                      style: GoogleFonts.sora(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showLogCycleSheet(context),
                      icon: const Icon(Icons.add, size: 18, color: AppColors.periodRose),
                      label: Text(
                        "Log Period",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.periodRose,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.cycles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 32, color: AppColors.onSurfaceVariant),
                        const SizedBox(height: 10),
                        Text(
                          "No periods logged yet",
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap 'Log Period' above to start tracking your cycle and get predictions.",
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.cycles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cycle = state.cycles[state.cycles.length - index - 1];
                      return _buildCycleRow(context, cycle);
                    },
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeroSummaryCard(BuildContext context, PeriodLoaded state) {
    String headline = "Ready to track?";
    String subtitle = "Log your last period to see your cycle day and upcoming predictions.";
    String? badge;

    if (state.cycles.isNotEmpty) {
      final sorted = List<Cycle>.from(state.cycles)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      final latest = sorted.last;
      final today = DateTime.now();
      final startOnly = DateTime(latest.startDate.year, latest.startDate.month, latest.startDate.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      final cycleLen = state.averageCycleLength > 0 ? state.averageCycleLength : 28;
      final elapsed = todayOnly.difference(startOnly).inDays + 1;
      final currentDay = elapsed > 0 ? ((elapsed - 1) % cycleLen) + 1 : 1;
      final phase = NutrientAdvice.getPhaseFromDayOfCycle(currentDay);

      headline = "Cycle Day $currentDay";
      badge = _friendlyPhaseLabel(phase);

      if (state.predictedNextStartDate != null) {
        final nextOnly = DateTime(
          state.predictedNextStartDate!.year,
          state.predictedNextStartDate!.month,
          state.predictedNextStartDate!.day,
        );
        final daysUntil = nextOnly.difference(todayOnly).inDays;
        if (daysUntil > 0) {
          subtitle = "Next period expected in $daysUntil ${daysUntil == 1 ? 'day' : 'days'} (${_formatShortDate(nextOnly)})";
        } else if (daysUntil == 0) {
          subtitle = "Your next period is expected today.";
        } else {
          subtitle = "Expected period was ${-daysUntil} ${-daysUntil == 1 ? 'day' : 'days'} ago.";
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.periodRose,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            headline,
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onPrimary.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showLogCycleSheet(context),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              "Log Period",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              foregroundColor: AppColors.primaryAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyPhaseLabel(MenstrualPhase phase) {
    switch (phase) {
      case MenstrualPhase.menstrual:
        return "Menstrual Phase";
      case MenstrualPhase.follicular:
        return "Follicular Phase";
      case MenstrualPhase.ovulatory:
        return "Ovulatory Phase";
      case MenstrualPhase.luteal:
        return "Luteal Phase";
    }
  }

  Widget _buildInsightsCard(PeriodLoaded state) {
    final nextPeriodText = state.predictedNextStartDate != null
        ? _formatShortDate(state.predictedNextStartDate!)
        : "Not enough data";

    final fertileText = (state.predictedFertilityStartDate != null &&
            state.predictedFertilityEndDate != null)
        ? "${_formatShortDate(state.predictedFertilityStartDate!)} – ${_formatShortDate(state.predictedFertilityEndDate!)}"
        : "Not enough data";

    String regularityLabel = "Learning";
    Color regularityColor = AppColors.onSurfaceVariant;
    Color regularityBg = AppColors.surfaceSubtle;
    if (state.cycles.length >= 3) {
      final sd = state.aiCycleLengthStandardDeviation;
      if (sd < 2.0) {
        regularityLabel = "Regular";
        regularityColor = AppColors.ovulationSage;
        regularityBg = AppColors.ovulationSageSoft;
      } else if (sd < 4.0) {
        regularityLabel = "Slight variation";
        regularityColor = AppColors.lutealAmber;
        regularityBg = AppColors.lutealAmberSoft;
      } else {
        regularityLabel = "Variable";
        regularityColor = AppColors.periodRose;
        regularityBg = AppColors.periodRoseSoft;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cycle Overview",
                style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: regularityBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  regularityLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: regularityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  icon: Icons.event_outlined,
                  iconColor: AppColors.periodRose,
                  label: "Next Period",
                  value: nextPeriodText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  icon: Icons.spa_outlined,
                  iconColor: AppColors.ovulationSage,
                  label: "Fertile Window",
                  value: fertileText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  icon: Icons.loop_rounded,
                  iconColor: AppColors.primaryAccent2,
                  label: "Avg. Cycle",
                  value: "${state.averageCycleLength} days",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  icon: Icons.water_drop_outlined,
                  iconColor: AppColors.periodRose,
                  label: "Avg. Period",
                  value: "${state.averagePeriodDuration} days",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleRow(BuildContext context, Cycle cycle) {
    final flowName = cycle.flowIntensity.name[0].toUpperCase() + cycle.flowIntensity.name.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.periodRose,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_formatFullDate(cycle.startDate)} – ${_formatShortDate(cycle.endDate)}",
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.periodRoseSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$flowName flow · ${cycle.durationInDays}d",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.periodRose,
                        ),
                      ),
                    ),
                    if (cycle.symptoms.isNotEmpty)
                      Text(
                        cycle.symptoms.join(", "),
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Delete cycle",
            onPressed: () => _confirmDelete(context, cycle),
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Cycle cycle) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Delete Cycle?",
            style: GoogleFonts.sora(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.onBackground),
          ),
          content: Text(
            "Remove the entry from ${_formatShortDate(cycle.startDate)} to ${_formatShortDate(cycle.endDate)}?",
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<PeriodBloc>().add(DeleteCycleRecord(cycle.id));
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showLogCycleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _LogCycleSheet(parentContext: context),
    );
  }
}

class _LogCycleSheet extends StatefulWidget {
  final BuildContext parentContext;

  const _LogCycleSheet({required this.parentContext});

  @override
  State<_LogCycleSheet> createState() => _LogCycleSheetState();
}

class _LogCycleSheetState extends State<_LogCycleSheet> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 4));
  DateTime _endDate = DateTime.now();
  FlowIntensity _intensity = FlowIntensity.medium;
  final List<String> _selectedSymptoms = [];
  static const List<String> _symptomsOptions = [
    "Cramps",
    "Bloating",
    "Headache",
    "Fatigue",
    "Mood Swings",
    "Back Pain",
  ];

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 4));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Log Period",
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDateButton("Start Date", _startDate, _selectStartDate),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton("End Date", _endDate, _selectEndDate),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                "Flow Intensity",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: FlowIntensity.values.map((intensity) {
                  final selected = _intensity == intensity;
                  final label = intensity.name[0].toUpperCase() + intensity.name.substring(1);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(label, textAlign: TextAlign.center),
                        ),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (val) {
                          if (val) setState(() => _intensity = intensity);
                        },
                        selectedColor: AppColors.periodRose,
                        backgroundColor: AppColors.background,
                        side: BorderSide(
                          color: selected ? AppColors.periodRose : AppColors.outline,
                        ),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.onPrimary : AppColors.onBackground,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Text(
                "Symptoms (Optional)",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _symptomsOptions.map((symptom) {
                  final selected = _selectedSymptoms.contains(symptom);
                  return FilterChip(
                    label: Text(symptom),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedSymptoms.add(symptom);
                        } else {
                          _selectedSymptoms.remove(symptom);
                        }
                      });
                    },
                    selectedColor: AppColors.primaryAccent,
                    checkmarkColor: AppColors.onPrimary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: selected ? AppColors.primaryAccent : AppColors.outline,
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: selected ? AppColors.onPrimary : AppColors.onBackground,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final newCycle = Cycle(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      startDate: _startDate,
                      endDate: _endDate,
                      flowIntensity: _intensity,
                      symptoms: List<String>.from(_selectedSymptoms),
                    );
                    widget.parentContext.read<PeriodBloc>().add(LogNewCycle(newCycle));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "Save Period",
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  PeriodTrackerTab._formatShortDate(date),
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomPeriodCalendar extends StatefulWidget {
  final List<Cycle> cycles;
  final DateTime? predictedStart;
  final DateTime? predictedEnd;
  final DateTime? ovulationStart;
  final DateTime? ovulationEnd;

  const CustomPeriodCalendar({
    super.key,
    required this.cycles,
    this.predictedStart,
    this.predictedEnd,
    this.ovulationStart,
    this.ovulationEnd,
  });

  @override
  State<CustomPeriodCalendar> createState() => _CustomPeriodCalendarState();
}

class _CustomPeriodCalendarState extends State<CustomPeriodCalendar> {
  late DateTime _displayedMonth;

  static const _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);

    final paddingOffset = firstDayOfMonth.weekday % 7;
    final totalCells = lastDayOfMonth.day + paddingOffset;
    final rowCount = (totalCells / 7).ceil();

    final isCurrentMonth =
        _displayedMonth.year == now.year && _displayedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, color: AppColors.onBackground),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: isCurrentMonth
                      ? null
                      : () => setState(() {
                            _displayedMonth = DateTime(now.year, now.month, 1);
                          }),
                  child: Text(
                    "${_months[_displayedMonth.month - 1]} ${_displayedMonth.year}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: AppColors.onBackground),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < paddingOffset || index >= totalCells) {
                return const SizedBox.shrink();
              }

              final dayNum = index - paddingOffset + 1;
              final targetDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNum);

              final isLoggedPeriod = _isInLoggedCycles(targetDate);
              final isPredictedPeriod = !isLoggedPeriod && _isInRange(targetDate, widget.predictedStart, widget.predictedEnd);
              final isOvulation = !isLoggedPeriod && !isPredictedPeriod && _isInRange(targetDate, widget.ovulationStart, widget.ovulationEnd);
              final isToday = targetDate.day == now.day &&
                  targetDate.month == now.month &&
                  targetDate.year == now.year;

              Color bg = Colors.transparent;
              Color txt = AppColors.onBackground;

              if (isLoggedPeriod) {
                bg = AppColors.periodRose;
                txt = AppColors.onPrimary;
              } else if (isPredictedPeriod) {
                bg = AppColors.periodRoseSoft;
                txt = AppColors.periodRose;
              } else if (isOvulation) {
                bg = AppColors.ovulationSageSoft;
                txt = AppColors.ovulationSage;
              }

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: AppColors.primaryAccent, width: 1.8)
                      : null,
                ),
                child: Text(
                  "$dayNum",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: (isLoggedPeriod || isPredictedPeriod || isOvulation || isToday)
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: txt,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.periodRose, "Period"),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.periodRoseSoft, "Predicted", borderColor: AppColors.periodRose),
              const SizedBox(width: 16),
              _buildLegendDot(AppColors.ovulationSageSoft, "Fertile", borderColor: AppColors.ovulationSage),
            ],
          ),
        ],
      ),
    );
  }

  bool _isInLoggedCycles(DateTime date) {
    for (final cycle in widget.cycles) {
      if (_isInRange(date, cycle.startDate, cycle.endDate)) return true;
    }
    return false;
  }

  bool _isInRange(DateTime date, DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  Widget _buildLegendDot(Color color, String label, {Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
