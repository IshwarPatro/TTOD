// lib/features/profile/presentation/pages/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thattimeofday/core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _selectedDateOfBirth = DateTime(1998, 6, 15);
  int _averageCycleLength = 28;

  static const _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileNotCreated &&
        profileState.defaultName != null &&
        profileState.defaultName != 'Guest') {
      _nameController.text = profileState.defaultName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${_months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileNotCreated &&
            state.defaultName != null &&
            state.defaultName != 'Guest' &&
            _nameController.text.isEmpty) {
          _nameController.text = state.defaultName!;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "Welcome to TTOD",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.periodRose,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Let's personalize your tracker",
                    style: GoogleFonts.sora(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your data stays private on your device.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What should we call you?",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your name";
                            }
                            return null;
                          },
                          style: GoogleFonts.inter(fontSize: 15, color: AppColors.onBackground),
                          decoration: InputDecoration(
                            hintText: "Your name or nickname",
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            fillColor: AppColors.background,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.outline),
                            ),
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
                        const SizedBox(height: 22),

                        Text(
                          "Date of Birth",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDateOfBirth(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(_selectedDateOfBirth),
                                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.onBackground),
                                ),
                                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Typical Cycle Length",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onBackground,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.periodRoseSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$_averageCycleLength days",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.periodRose,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.periodRose,
                            inactiveTrackColor: AppColors.outline,
                            thumbColor: AppColors.periodRose,
                            overlayColor: AppColors.periodRose.withValues(alpha: 0.15),
                          ),
                          child: Slider(
                            value: _averageCycleLength.toDouble(),
                            min: 21,
                            max: 35,
                            divisions: 14,
                            label: "$_averageCycleLength days",
                            onChanged: (val) {
                              setState(() => _averageCycleLength = val.round());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final authState = context.read<AuthBloc>().state;
                          final userId = authState is AuthSuccess ? authState.user.uid : null;
                          context.read<ProfileBloc>().add(
                                UpdateProfileDetails(
                                  name: _nameController.text.trim(),
                                  dateOfBirth: _selectedDateOfBirth,
                                  averageCycleLengthInput: _averageCycleLength,
                                  historicalCycleCount: 0,
                                  userId: userId,
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Get Started",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
