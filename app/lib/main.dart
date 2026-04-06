import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'theme.dart';
import 'screens/stadion_screen.dart';
import 'screens/garrison_screen.dart';
import 'screens/agoge_screen.dart';
import 'screens/stoic_screen.dart';
import 'screens/phalanx_screen.dart';
import 'screens/weekly_schedule_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/analytics_dashboard.dart';
import 'screens/exercise_library_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/workout_provider.dart';
import 'providers/ingestion_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/exercise_provider.dart';
import 'services/dom_rl_engine.dart';
import 'services/ai_plan_service.dart';
import 'services/state_persistence_service.dart';
import 'config/supabase_config.dart';
import 'widgets/animated_nav_bar.dart';
import 'widgets/warrior_animations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool servicesInitialized = false;
  String? initError;
  bool firebaseInitialized = false;

  try {
    // Initialize Firebase for Analytics and Crashlytics (optional - app works without it)
    try {
      await Firebase.initializeApp();
      firebaseInitialized = true;

      // Enable Crashlytics for error tracking
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      debugPrint('Firebase initialized successfully');
    } catch (firebaseError) {
      debugPrint(
        'Firebase initialization failed (non-critical): $firebaseError',
      );
      // Continue without Firebase - app is still functional
    }

    // Initialize Supabase (required)
    await SupabaseConfig.initialize();

    // Initialize services
    await DomRlEngine().initialize();
    await AIPlanService().initialize();
    await StatePersistenceService().initialize();

    servicesInitialized = true;
    debugPrint('All required services initialized successfully');
  } catch (e) {
    initError = e.toString();
    debugPrint('Critical initialization error: $e');
  }

  runApp(
    NeospartanApp(
      servicesInitialized: servicesInitialized,
      initError: initError,
      firebaseInitialized: firebaseInitialized,
    ),
  );
}

class NeospartanApp extends StatelessWidget {
  final bool servicesInitialized;
  final String? initError;
  final bool firebaseInitialized;

  const NeospartanApp({
    super.key,
    required this.servicesInitialized,
    this.initError,
    this.firebaseInitialized = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => IngestionProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
      ],
      child: MaterialApp(
        title: 'Neospartan',
        theme: LaconicTheme.theme,
        home: servicesInitialized
            ? AuthGate()
            : InitializationErrorScreen(error: initError),
        debugShowCheckedModeBanner: false,
        // Custom page transitions for combat feel
        onGenerateRoute: (settings) {
          Widget? target;
          switch (settings.name) {
            case '/stadion':
              target = const StadionScreen();
              break;
            case '/garrison':
              target = const GarrisonScreen();
              break;
            case '/agoge':
              target = const AgogeScreen();
              break;
            case '/stoic':
              target = const StoicScreen();
              break;
            case '/phalanx':
              target = const PhalanxScreen();
              break;
            case '/weekly_schedule':
              target = const WeeklyScheduleScreen();
              break;
            case '/analytics':
              target = const AnalyticsDashboard();
              break;
            case '/exercise_library':
              target = const ExerciseLibraryScreen();
              break;
            case '/login':
              target = const LoginScreen();
              break;
          }

          if (target != null) {
            return CombatPageTransition(child: target);
          }
          return null;
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Still initializing - show loading
        if (!authProvider.isInitialized) {
          return const WarriorLoadingScreen(message: 'AUTHENTICATING');
        }

        // Not authenticated - show login
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Check onboarding status from profile
        final profile = authProvider.userProfile;
        if (profile == null || !profile.hasCompletedOnboarding) {
          return OnboardingScreen(
            onComplete: () {
              Navigator.of(context).pushReplacement(
                CombatPageTransition(child: const MainNavigation()),
              );
            },
          );
        }

        // Authenticated and onboarded - show main app
        return const MainNavigation();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.local_fire_department, label: 'Agoge'),
    NavItem(icon: Icons.calendar_view_week, label: 'Schedule'),
    NavItem(icon: Icons.fitness_center, label: 'Library'),
    NavItem(icon: Icons.monitor_heart, label: 'Garrison'),
    NavItem(icon: Icons.person, label: 'Profile'),
  ];

  final List<Widget> _screens = [
    const AgogeScreen(),
    const WeeklyScheduleScreen(),
    const ExerciseLibraryScreen(),
    const GarrisonScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: AnimatedNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class InitializationErrorScreen extends StatelessWidget {
  final String? error;

  const InitializationErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Initialization Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to initialize required services.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd4af37),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
