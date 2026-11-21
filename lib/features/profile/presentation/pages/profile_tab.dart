import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../period_tracker/data/models/cycle_model.dart';
import '../../../period_tracker/presentation/bloc/period_bloc.dart';
import '../../../period_tracker/presentation/bloc/period_event.dart';
import '../../../period_tracker/presentation/bloc/period_state.dart';
import '../../data/models/profile_model.dart';
import '../bloc/profile_bloc.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime _dateOfBirth = DateTime(1998, 6, 15);
  int _averageCycleLength = 28;
  int _historicalCycleCount = 0;

  static const _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    String name = "";
    if (profileState is ProfileLoaded) {
      name = profileState.profile.name;
      _dateOfBirth = profileState.profile.dateOfBirth;
      _averageCycleLength = profileState.profile.averageCycleLengthInput.clamp(21, 35);
      _historicalCycleCount = profileState.profile.historicalCycleCount;
    }
    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${_months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _selectDOB(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _exportLocalBackup(BuildContext context) {
    final listCycles = <Map<String, dynamic>>[];
    if (Hive.isBoxOpen('cycles_box')) {
      final cyclesBox = Hive.box<CycleModel>('cycles_box');
      for (int i = 0; i < cyclesBox.length; i++) {
        final cycle = cyclesBox.getAt(i);
        if (cycle != null) {
          listCycles.add({
            "id": cycle.id,
            "start_date": cycle.startDate.toIso8601String(),
            "end_date": cycle.endDate.toIso8601String(),
            "intensity": cycle.flowIntensity.name,
            "symptoms": cycle.symptoms,
          });
        }
      }
    }

    ProfileModel? profileData;
    if (Hive.isBoxOpen('profile_box')) {
      final profileBox = Hive.box<ProfileModel>('profile_box');
      if (profileBox.isNotEmpty) {
        profileData = profileBox.values.first;
      }
    }

    final backup = {
      "backup_version": "1.0",
      "exported_at": DateTime.now().toIso8601String(),
      "profile": profileData == null
          ? null
          : {
              "name": profileData.name,
              "dob": profileData.dateOfBirth.toIso8601String(),
              "average_cycle_length": profileData.averageCycleLengthInput,
            },
      "cycles": listCycles,
    };

    final prettyJson = const JsonEncoder.withIndent('  ').convert(backup);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Backup Data",
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Copy your local data below to keep a personal backup.",
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    prettyJson,
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.onBackground),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Close", style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: prettyJson));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Backup copied to clipboard.")),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text("Copy", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Reset All Data?",
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.errorRed),
          ),
          content: Text(
            "This will permanently delete your profile and all logged cycles from this device. This cannot be undone.",
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ProfileBloc>().add(ResetAllLocalData());
                context.read<PeriodBloc>().add(LoadAllCycles());
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All local data cleared.")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Reset Data", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          _nameController.text = state.profile.name;
          setState(() {
            _dateOfBirth = state.profile.dateOfBirth;
            _averageCycleLength = state.profile.averageCycleLengthInput.clamp(21, 35);
            _historicalCycleCount = state.profile.historicalCycleCount;
          });
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }

        final periodState = context.watch<PeriodBloc>().state;
        final loggedCyclesCount = periodState is PeriodLoaded ? periodState.cycles.length : 0;
        final displayName = state is ProfileLoaded && state.profile.name.isNotEmpty
            ? state.profile.name
            : "Your Profile";

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.periodRose,
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: GoogleFonts.sora(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.sora(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$loggedCyclesCount ${loggedCyclesCount == 1 ? 'cycle' : 'cycles'} logged · Stored privately on device",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Editable Settings Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Personal Settings",
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Name",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.onBackground),
                        decoration: InputDecoration(
                          fillColor: AppColors.background,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter your name" : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Date of Birth",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _selectDOB(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(_dateOfBirth),
                                style: GoogleFonts.inter(fontSize: 15, color: AppColors.onBackground),
                              ),
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Typical Cycle Length",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                          ),
                          Text(
                            "$_averageCycleLength days",
                            style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.periodRose),
                          ),
                        ],
                      ),
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
                          onChanged: (v) => setState(() => _averageCycleLength = v.round()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final authState = context.read<AuthBloc>().state;
                              final userId = authState is AuthSuccess ? authState.user.uid : null;
                              context.read<ProfileBloc>().add(UpdateProfileDetails(
                                    name: _nameController.text.trim(),
                                    dateOfBirth: _dateOfBirth,
                                    averageCycleLengthInput: _averageCycleLength,
                                    historicalCycleCount: _historicalCycleCount,
                                    userId: userId,
                                  ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Profile saved.")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Save Changes", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data & Account Actions
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download_outlined, color: AppColors.onBackground),
                      title: Text("Backup Data", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
                      subtitle: Text("Export your cycles as JSON", style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                      onTap: () => _exportLocalBackup(context),
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.onBackground),
                      title: Text("Sign Out", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                      onTap: () => context.read<AuthBloc>().add(AuthSignOut()),
                    ),
                    const Divider(color: AppColors.outlineVariant, height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                      title: Text("Reset All Local Data", style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.errorRed)),
                      onTap: () => _confirmResetData(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
