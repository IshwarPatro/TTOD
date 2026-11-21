// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/chat_learning_service.dart';
import 'core/services/monetization_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme.dart';
import 'core/widgets/app_splash_screen.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/sign_in_screen.dart';
import 'features/community/data/repositories/firestore_community_repository.dart';
import 'features/group_chat/data/repositories/group_chat_repository.dart';
import 'features/group_chat/presentation/pages/groups_tab.dart';
import 'features/hydration/presentation/bloc/hydration_bloc.dart';
import 'features/period_tracker/data/datasources/period_local_datasource.dart';
import 'features/period_tracker/data/models/cycle_model.dart';
import 'features/period_tracker/data/models/daily_log_model.dart';
import 'features/period_tracker/data/repositories/period_repository_impl.dart';
import 'features/period_tracker/domain/usecases/delete_cycle.dart';
import 'features/period_tracker/domain/usecases/get_cycles.dart';
import 'features/period_tracker/domain/usecases/get_daily_logs.dart';
import 'features/period_tracker/domain/usecases/predict_cycle.dart';
import 'features/period_tracker/domain/usecases/save_cycle.dart';
import 'features/period_tracker/presentation/bloc/period_bloc.dart';
import 'features/period_tracker/presentation/bloc/period_event.dart';
import 'features/period_tracker/presentation/pages/period_tracker_tab.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/models/profile_model.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/pages/onboarding_screen.dart';
import 'features/profile/presentation/pages/profile_tab.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Core initialization skipped: $e");
  }
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CycleModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(DailyLogModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ProfileModelAdapter());
  }

  final cycleBox = await Hive.openBox<CycleModel>('cycles_box');
  final dailyLogsBox = await Hive.openBox<DailyLogModel>('daily_logs_box');
  final profileBox = await Hive.openBox<ProfileModel>('profile_box');

  await MonetizationService.initialize();
  await ChatLearningService.initialize();

  final periodLocalDataSource = PeriodLocalDataSourceImpl(
    cycleBox: cycleBox,
    dailyLogsBox: dailyLogsBox,
  );
  final periodRepository = PeriodRepositoryImpl(localDataSource: periodLocalDataSource);

  final profileLocalDataSource = ProfileLocalDataSourceImpl(
    profileBox: profileBox,
    cyclesBox: cycleBox,
    dailyLogsBox: dailyLogsBox,
  );
  final profileRepository = ProfileRepositoryImpl(localDataSource: profileLocalDataSource);

  final authRepository = FirebaseAuthRepository();
  final communityRepository = FirestoreCommunityRepository();
  final groupChatRepository = GroupChatRepository();

  runApp(MyApp(
    periodRepository: periodRepository,
    profileRepository: profileRepository,
    authRepository: authRepository,
    communityRepository: communityRepository,
    groupChatRepository: groupChatRepository,
  ));
}

class MyApp extends StatelessWidget {
  final PeriodRepositoryImpl periodRepository;
  final ProfileRepositoryImpl profileRepository;
  final AuthRepository authRepository;
  final FirestoreCommunityRepository communityRepository;
  final GroupChatRepository? groupChatRepository;

  const MyApp({
    super.key,
    required this.periodRepository,
    required this.profileRepository,
    required this.authRepository,
    required this.communityRepository,
    this.groupChatRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepository),
        RepositoryProvider<FirestoreCommunityRepository>(create: (_) => communityRepository),
        RepositoryProvider<GroupChatRepository>(
          create: (_) => groupChatRepository ?? GroupChatRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PeriodBloc>(
            create: (_) => PeriodBloc(
              getCyclesUseCase: GetCycles(periodRepository),
              saveCycleUseCase: SaveCycle(periodRepository),
              deleteCycleUseCase: DeleteCycle(periodRepository),
              predictCycleUseCase: PredictCycle(),
              getDailyLogsUseCase: GetDailyLogs(periodRepository),
            )..add(LoadAllCycles()),
          ),
          BlocProvider<HydrationBloc>(
            create: (_) => HydrationBloc()..add(LoadDailyIntake()),
          ),
          BlocProvider<ProfileBloc>(
            create: (_) => ProfileBloc(repository: profileRepository)..add(LoadProfile()),
          ),
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepository: authRepository)..add(AuthCheckRequested()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is AuthSuccess) {
              context.read<ProfileBloc>().add(
                    LoadProfile(
                      userId: authState.user.uid,
                      defaultName: authState.user.displayName,
                    ),
                  );
            } else if (authState is AuthUnauthenticated) {
              context.read<ProfileBloc>().add(const LoadProfile(userId: null));
            }
          },
          child: MaterialApp(
            title: 'TTOD',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthSuccess) {
                  return BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, profileState) {
                      if (profileState is ProfileLoaded) {
                        return const AppMainShell();
                      } else if (profileState is ProfileNotCreated) {
                        return const OnboardingScreen();
                      } else if (profileState is ProfileError) {
                        return _ProfileErrorView(
                          message: profileState.message,
                          onRetry: () {
                            context.read<ProfileBloc>().add(
                                  LoadProfile(
                                    userId: authState.user.uid,
                                    defaultName: authState.user.displayName,
                                  ),
                                );
                          },
                          onSignOut: () => context.read<AuthBloc>().add(AuthSignOut()),
                        );
                      }
                      return const AppSplashScreen();
                    },
                  );
                } else if (authState is AuthUnauthenticated || authState is AuthFailure) {
                  return const SignInScreen();
                }
                return const AppSplashScreen();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  const _ProfileErrorView({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.errorRed, size: 44),
              const SizedBox(height: 14),
              Text(
                "Could not load profile",
                style: GoogleFonts.sora(
                  color: AppColors.onBackground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onRetry,
                child: const Text("Try Again"),
              ),
              TextButton(
                onPressed: onSignOut,
                child: Text("Sign Out", style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppMainShell extends StatefulWidget {
  const AppMainShell({super.key});

  @override
  State<AppMainShell> createState() => _AppMainShellState();
}

class _AppMainShellState extends State<AppMainShell> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    "Cycle",
    "Groups",
    "Profile",
  ];

  static const List<Widget> _tabs = [
    PeriodTrackerTab(),
    GroupsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 18,
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 13, color: AppColors.ovulationSage),
                  const SizedBox(width: 4),
                  Text(
                    "Private",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.cardBackground,
          indicatorColor: AppColors.periodRoseSoft,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: AppColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.calendar_month, color: AppColors.periodRose),
              label: "Cycle",
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined, color: AppColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.groups, color: AppColors.periodRose),
              label: "Groups",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: AppColors.onSurfaceVariant),
              selectedIcon: Icon(Icons.person, color: AppColors.periodRose),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
