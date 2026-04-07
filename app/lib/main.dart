import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'theme.dart';

// Screen imports
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
import 'screens/shield_sync_screen.dart';
import 'screens/laconic_parser_screen.dart';
import 'screens/phalanx_toggle_screen.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Providers
import 'providers/workout_provider.dart';
import 'providers/ingestion_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/exercise_provider.dart';

// Services
import 'services/dom_rl_engine.dart';
import 'services/ai_plan_service.dart';
import 'services/state_persistence_service.dart';
import 'config/supabase_config.dart';

// Widgets
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => IngestionProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
      ],
      child: MaterialApp(
        title: 'Neospartan',
        debugShowCheckedModeBanner: false,
        theme: LaconicTheme.theme,
        home: servicesInitialized
            ? const AuthGate()
            : InitializationErrorScreen(error: initError),
        // Named routes for all screens
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/agoge': (context) => const AgogeScreen(),
          '/weekly_schedule': (context) => const WeeklyScheduleScreen(),
          '/exercise_library': (context) => const ExerciseLibraryScreen(),
          '/garrison': (context) => const GarrisonScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/stoic': (context) => const StoicScreen(),
          '/phalanx': (context) => const PhalanxScreen(),
          '/stadion': (context) => const StadionScreen(),
          '/analytics': (context) => const AnalyticsDashboard(),
          '/shield_sync': (context) => const ShieldSyncScreen(),
          '/laconic_parser': (context) => const LaconicParserScreen(),
          '/phalanx_toggle': (context) => const PhalanxToggleScreen(),
        },
        // Dynamic routes with arguments
        onGenerateRoute: (settings) {
          return null; // Let routes map or onUnknownRoute handle it
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: LaconicTheme.background,
              appBar: AppBar(
                backgroundColor: LaconicTheme.surfaceContainerLow,
                title: Text(
                  'NOT FOUND',
                  style: GoogleFonts.spaceGrotesk(
                    color: LaconicTheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: LaconicTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Route not found',
                      style: GoogleFonts.spaceGrotesk(
                        color: LaconicTheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      settings.name ?? 'Unknown route',
                      style: GoogleFonts.inter(
                        color: LaconicTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/agoge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LaconicTheme.secondary,
                        foregroundColor: LaconicTheme.onSecondary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'RETURN TO BASE',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// AuthGate - Handles authentication state and navigation
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
              Navigator.of(context).pushReplacementNamed('/agoge');
            },
          );
        }

        // Authenticated and onboarded - show main app
        return const MainNavigation();
      },
    );
  }
}

/// MainNavigation - 4-tab bottom navigation
/// Shield (Agoge) | Swords (Schedule) | Fort (Garrison/Analytics) | Psychology (Stoic)
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // 4-tab navigation: Shield | Swords | Fort | Psychology
  final List<NavItem> _navItems = const [
    NavItem(
      icon: Icons.shield_outlined,
      label: 'Shield',
    ), // Agoge - Main dashboard
    NavItem(icon: Icons.fitness_center, label: 'Swords'), // Schedule/Workouts
    NavItem(icon: Icons.fort_outlined, label: 'Fort'), // Garrison - Analytics
    NavItem(
      icon: Icons.psychology_outlined,
      label: 'Mind',
    ), // Stoic - Psychology
  ];

  final List<Widget> _screens = [
    const AgogeScreen(), // Shield - Agoge Dashboard
    const WeeklyScheduleScreen(), // Swords - Schedule & Workouts
    const GarrisonScreen(), // Fort - Garrison Analytics
    const StoicScreen(), // Psychology - Stoic Mind Tracking
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AnimatedNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

/// InitializationErrorScreen - Blood & Bronze themed error screen
class InitializationErrorScreen extends StatelessWidget {
  final String? error;

  const InitializationErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: LaconicTheme.surfaceContainerLow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: LaconicTheme.errorContainer,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: LaconicTheme.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SYSTEM FAILURE',
                  style: GoogleFonts.spaceGrotesk(
                    color: LaconicTheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to initialize required services.',
                  style: GoogleFonts.inter(
                    color: LaconicTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LaconicTheme.error.withValues(alpha: 0.1),
                      border: Border.all(
                        color: LaconicTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      error!,
                      style: GoogleFonts.inter(
                        color: LaconicTheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Restart the app
                      main();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LaconicTheme.secondary,
                      foregroundColor: LaconicTheme.onSecondary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'RETRY',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
