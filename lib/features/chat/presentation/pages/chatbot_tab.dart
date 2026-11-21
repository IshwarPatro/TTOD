// lib/features/chat/presentation/pages/chatbot_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thattimeofday/core/theme/app_colors.dart';
import 'package:thattimeofday/core/services/chat_learning_service.dart';
import 'package:thattimeofday/features/nutrients/domain/entities/nutrient_advice.dart';
import 'package:thattimeofday/features/period_tracker/domain/entities/cycle.dart';
import 'package:thattimeofday/features/period_tracker/presentation/bloc/period_bloc.dart';
import 'package:thattimeofday/features/period_tracker/presentation/bloc/period_state.dart';


class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? category;
  bool? isHelpful; // null = no feedback, true = positive, false = negative

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.category,
    this.isHelpful,
  });
}

class ChatbotTab extends StatefulWidget {
  const ChatbotTab({super.key});

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showWeights = false;

  final List<String> _quickPrompts = [
    "Severe Cramps",
    "Feeling Bloated",
    "Low Energy",
    "Headache",
    "Water Intake Low",
    "Cycle Wellness Tip",
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: "Hi there! I am your offline AI Wellness Counselor. Choose a symptom below or ask for tips on your current cycle phase.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handlePromptSelect(String prompt, MenstrualPhase activePhase) {
    if (_isTyping) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(
          text: prompt,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    // Generate recommendation
    final isTip = prompt.contains("Tip");
    final symptomsList = isTip ? <String>[] : [prompt];

    final rec = ChatLearningService.generateRecommendation(
      phase: activePhase,
      todaySymptoms: symptomsList,
    );

    // Simulate typing delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: rec['text']!,
            isUser: false,
            timestamp: DateTime.now(),
            category: rec['category'],
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _submitFeedback(ChatMessage msg, bool helpful) async {
    if (msg.category == null) return;
    setState(() {
      msg.isHelpful = helpful;
    });

    if (helpful) {
      await ChatLearningService.reinforcePositive(msg.category!);
    } else {
      await ChatLearningService.reinforceNegative(msg.category!);
    }

    // Trigger state rebuild of local weights display
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine user's active cycle phase
    return BlocBuilder<PeriodBloc, PeriodState>(
      builder: (context, periodState) {
        MenstrualPhase currentPhase = MenstrualPhase.follicular; // default
        if (periodState is PeriodLoaded && periodState.cycles.isNotEmpty) {
          final sorted = List<Cycle>.from(periodState.cycles)
            ..sort((a, b) => a.startDate.compareTo(b.startDate));
          final latestCycle = sorted.last;
          final today = DateTime.now();
          final startOnly = DateTime(latestCycle.startDate.year, latestCycle.startDate.month, latestCycle.startDate.day);
          final todayOnly = DateTime(today.year, today.month, today.day);
          
          final elapsedDays = todayOnly.difference(startOnly).inDays + 1;
          final cycleLength = periodState.averageCycleLength > 0 ? periodState.averageCycleLength : 28;
          final normalizedDay = ((elapsedDays - 1) % cycleLength) + 1;

          currentPhase = NutrientAdvice.getPhaseFromDayOfCycle(normalizedDay);
        }

        final phaseString = currentPhase.toString().split('.').last.toUpperCase();

        return Column(
          children: [
            // Sub-header showing active learning status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      Text(
                        "OFFLINE AI AGENT ACTIVE ($phaseString)",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showWeights = !_showWeights),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.onBackground, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showWeights ? Icons.bug_report : Icons.developer_mode,
                            size: 10,
                            color: AppColors.onBackground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showWeights ? "HIDE VALUES" : "VIEW AI ENGINE",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Collapsible state debug board
            if (_showWeights) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.onBackground, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LOCAL ML WEIGHTS (SELF-LEARNED)",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final weights = ChatLearningService.getWeights();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: weights.entries.map((w) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.onBackground, width: 0.8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        w.key.toUpperCase(),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${w.value}",
                                        style: GoogleFonts.sora(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 6),

            // Messages chat list board
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.outline, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.outline.withValues(alpha: 0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) {
                          final msg = _messages[idx];
                          return _buildChatBubble(msg);
                        },
                      ),
                    ),
                    if (_isTyping)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: Text(
                              "Typing recommendation...",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: AppColors.secondaryAccent.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action Quick Prompt Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPrompts.map((prompt) {
                  return ActionChip(
                    label: Text(
                      prompt.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                    onPressed: () => _handlePromptSelect(prompt, currentPhase),
                    backgroundColor: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.outline, width: 1.0),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final blockBg = msg.isUser ? AppColors.primaryAccent : AppColors.cardBackground;
    final align = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final textStyle = GoogleFonts.inter(
      fontSize: 12,
      height: 1.4,
      color: msg.isUser ? AppColors.background : AppColors.onBackground,
    );

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: blockBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: msg.isUser ? const Radius.circular(18) : Radius.zero,
                  bottomRight: msg.isUser ? Radius.zero : const Radius.circular(18),
                ),
                border: Border.all(color: AppColors.outline, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.outline.withValues(alpha: 0.15),
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: textStyle,
              ),
            ),
            
            // AI Recommendation Feedback Row
            if (!msg.isUser && msg.category != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: msg.isHelpful == null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Was this helpful?",
                          style: GoogleFonts.spaceGrotesk(fontSize: 8, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _submitFeedback(msg, true),
                          child: const Icon(Icons.thumb_up_alt_outlined, size: 12, color: Colors.green),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _submitFeedback(msg, false),
                          child: const Icon(Icons.thumb_down_alt_outlined, size: 12, color: Colors.red),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          msg.isHelpful! ? Icons.check_circle : Icons.info,
                          size: 10,
                          color: msg.isHelpful! ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          msg.isHelpful! ? "Thanks! Model weights increased." : "Got it. Decreasing model weights.",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 8, 
                            fontWeight: FontWeight.bold,
                            color: msg.isHelpful! ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
