import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'services/firestore_service.dart';
import 'services/firebase_sync_service.dart';
import 'widgets/guest_mode_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  String? initError;

  try {
    await Firebase.initializeApp();

    // Enable Crashlytics for error tracking
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Enable offline persistence for Firestore
    await FirestoreService.enableOfflinePersistence();

    FirebaseSyncService().initialize();
    await DomRlEngine().initialize();
    await AIPlanService().initialize();
    firebaseInitialized = true;
    debugPrint('Firebase and AI services initialized successfully');
  } catch (e) {
    initError = e.toString();
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => IngestionProvider()),
      ],
      child: NeospartanApp(
        firebaseInitialized: firebaseInitialized,
        initError: initError,
      ),
    ),
  );
}

class NeospartanApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? initError;

  const NeospartanApp({
    super.key,
    required this.firebaseInitialized,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    if (!firebaseInitialized) {
      return MaterialApp(
        title: 'Neospartan',
        theme: LaconicTheme.theme,
        debugShowCheckedModeBanner: false,
        home: FirebaseInitErrorScreen(error: initError),
      );
    }

    return MaterialApp(
      title: 'Neospartan',
      theme: LaconicTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

/// Auth Gate - Handles routing between auth screens and main app
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Show loading while initializing
    if (!authProvider.isInitialized) {
      return const Scaffold(
        backgroundColor: LaconicTheme.deepBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 64,
                color: LaconicTheme.spartanBronze,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  LaconicTheme.spartanBronze,
                ),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'INITIALIZING...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not authenticated - show login
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Check if onboarding is needed
    final profile = authProvider.userProfile;
    final needsOnboarding =
        profile == null ||
        profile.experienceLevel == null ||
        profile.philosophicalBaseline == null ||
        !profile.hasCompletedOnboarding;

    if (needsOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          // Onboarding complete - will rebuild and show main app
        },
      );
    }

    // Authenticated and onboarded - show main app
    return const NeospartanShell();
  }
}

class NeospartanShell extends StatefulWidget {
  const NeospartanShell({super.key});

  @override
  State<NeospartanShell> createState() => _NeospartanShellState();
}

class _NeospartanShellState extends State<NeospartanShell>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = [
    const AgogeScreen(), // Training - Combat Conditioning
    const WeeklyScheduleScreen(), // Schedule - Weekly Plan
    const AnalyticsDashboard(), // Analytics - Progress & Insights
    const GarrisonScreen(), // Recovery - Readiness & Armor
    const StadionScreen(), // Exercises - Movement Library
    const StoicScreen(), // Mindset - Mental Conditioning
    const PhalanxScreen(), // Import - Plan Ingestion
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _previousIndex = _selectedIndex;
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildMinimalistDrawer(),
      body: Column(
        children: [
          // Show guest mode banner if user is anonymous
          if (authProvider.isAnonymous)
            GuestModeBanner(
              onUpgrade: () {
                // TODO: Navigate to sign up flow
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          // Main content
          Expanded(
            child: Stack(
              children: [
                // Previous screen (fading out)
                if (_previousIndex != _selectedIndex)
                  AnimatedOpacity(
                    opacity: 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: _screens[_previousIndex],
                  ),
                // Current screen (fading in)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _screens[_selectedIndex],
                ),
                // Minimalist Floating Menu Button
                Positioned(
                  top: authProvider.isAnonymous ? 100 : 40,
                  left: 20,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(
                      authProvider.isAnonymous ? 0 : -10,
                      0,
                      0,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: LaconicTheme.spartanBronze,
                        size: 30,
                      ),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalistDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                "A S P A R T A N",
                style: TextStyle(
                  color: LaconicTheme.spartanBronze,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ),
          ),
          _drawerItem(0, "TRAINING", Icons.auto_awesome, "Combat Conditioning"),
          _drawerItem(1, "SCHEDULE", Icons.calendar_today, "Weekly Plan"),
          _drawerItem(2, "ANALYTICS", Icons.show_chart, "Progress & Insights"),
          _drawerItem(
            3,
            "RECOVERY",
            Icons.shield_outlined,
            "Readiness & Armor",
          ),
          _drawerItem(4, "EXERCISES", Icons.directions_run, "Movement Library"),
          _drawerItem(5, "MINDSET", Icons.psychology, "Mental Conditioning"),
          _drawerItem(6, "IMPORT", Icons.document_scanner, "Plan Ingestion"),
          const Spacer(),
          // User section with sign out
          _buildUserSection(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "VICTORY OR DEATH",
              style: TextStyle(
                color: LaconicTheme.spartanBronze.withValues(alpha: 0.5),
                fontSize: 10,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, String title, IconData icon, String subtitle) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? LaconicTheme.spartanBronze : Colors.grey,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              letterSpacing: 2.0,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: isSelected
                  ? LaconicTheme.spartanBronze
                  : Colors.grey.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildUserSection() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isAuthenticated) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: LaconicTheme.spartanBronze.withValues(
                      alpha: 0.2,
                    ),
                    child: Text(
                      (auth.displayName ?? 'S').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: LaconicTheme.spartanBronze,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName ?? 'Spartan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (auth.isAnonymous) const GuestModeIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (auth.isAnonymous)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: LaconicTheme.spartanBronze),
                    ),
                    child: const Text(
                      'SAVE PROGRESS',
                      style: TextStyle(color: LaconicTheme.spartanBronze),
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await auth.signOut();
                },
                icon: const Icon(Icons.logout, size: 16, color: Colors.grey),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModulePlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  const ModulePlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: LaconicTheme.spartanBronze,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error screen shown when Firebase fails to initialize
class FirebaseInitErrorScreen extends StatelessWidget {
  final String? error;

  const FirebaseInitErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaconicTheme.deepBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 64),
              const SizedBox(height: 24),
              const Text(
                'FIREBASE CONNECTION FAILED',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error ??
                    'Unable to connect to Firebase.\nCheck your configuration and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Retry initialization
                  main();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('RETRY'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Continue in offline mode
                  runApp(
                    MultiProvider(
                      providers: [
                        ChangeNotifierProvider(create: (_) => AuthProvider()),
                        ChangeNotifierProvider(
                          create: (_) => WorkoutProvider(),
                        ),
                        ChangeNotifierProvider(
                          create: (_) => IngestionProvider(),
                        ),
                      ],
                      child: const NeospartanApp(
                        firebaseInitialized: true, // Pretend it's working
                        initError: null,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'CONTINUE OFFLINE',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
