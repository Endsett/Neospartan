import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/stadion_screen.dart';
import 'screens/garrison_screen.dart';
import 'screens/agoge_screen.dart';
import 'screens/stoic_screen.dart';
import 'screens/phalanx_screen.dart';
import 'screens/weekly_schedule_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/analytics_dashboard.dart';
import 'screens/auth/login_screen.dart';
import 'providers/workout_provider.dart';
import 'providers/ingestion_provider.dart';
import 'providers/auth_provider.dart';
import 'services/dom_rl_engine.dart';
import 'services/ai_plan_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/supabase_database_service.dart';
import 'services/state_persistence_service.dart';
import 'config/supabase_config.dart';
import 'widgets/guest_mode_banner.dart';
import 'widgets/warrior_animations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool servicesInitialized = false;
  String? initError;

  try {
    // Initialize Firebase for Analytics and Crashlytics only
    await Firebase.initializeApp();

    // Enable Crashlytics for error tracking
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Initialize Supabase
    await SupabaseConfig.initialize();

    // Initialize services
    await DomRlEngine().initialize();
    await AIPlanService().initialize();
    await StatePersistenceService().initialize();

    servicesInitialized = true;
    debugPrint('All services initialized successfully');
  } catch (e) {
    initError = e.toString();
    debugPrint('Initialization error: $e');
  }

  runApp(
    NeospartanApp(
      servicesInitialized: servicesInitialized,
      initError: initError,
    ),
  );
}

class NeospartanApp extends StatelessWidget {
  final bool servicesInitialized;
  final String? initError;

  const NeospartanApp({
    super.key,
    required this.servicesInitialized,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => IngestionProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
          // Use CombatPageTransition for all routes
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
            case '/login':
              target = const LoginScreen();
              break;
          }

          if (target != null) {
            return CombatPageTransition(child: target);
          }
          return null;
        },
        routes: {
          '/stadion': (context) => const StadionScreen(),
          '/garrison': (context) => const GarrisonScreen(),
          '/agoge': (context) => const AgogeScreen(),
          '/stoic': (context) => const StoicScreen(),
          '/phalanx': (context) => const PhalanxScreen(),
          '/weekly_schedule': (context) => const WeeklyScheduleScreen(),
          '/analytics': (context) => const AnalyticsDashboard(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseAuthService().authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WarriorLoadingScreen(message: 'AUTHENTICATING');
        }

        final user = snapshot.data?.session?.user;

        if (user != null) {
          // User is authenticated
          return FutureBuilder<Map<String, dynamic>?>(
            future: SupabaseDatabaseService().getUserProfile(user.id),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const WarriorLoadingScreen(message: 'LOADING PROFILE');
              }

              final profile = profileSnapshot.data;

              if (profile != null &&
                  profile['has_completed_onboarding'] == true) {
                return const MainNavigation();
              } else {
                return OnboardingScreen(
                  onComplete: () {
                    // Navigate to main app after onboarding with combat transition
                    Navigator.of(context).pushReplacement(
                      CombatPageTransition(child: const MainNavigation()),
                    );
                  },
                );
              }
            },
          );
        } else {
          // User is not authenticated
          return const LoginScreen();
        }
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

  final List<Widget> _screens = [
    const StadionScreen(),
    const GarrisonScreen(),
    const AgogeScreen(),
    const WeeklyScheduleScreen(),
    const AnalyticsDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GuestModeBanner(),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2a2a2a),
        selectedItemColor: const Color(0xFFd4af37),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Stadion',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Garrison',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Agoge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
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
