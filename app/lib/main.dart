import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'screens/stadion_screen.dart';
import 'screens/garrison_screen.dart';
import 'screens/agoge_screen.dart';
import 'screens/stoic_screen.dart';
import 'screens/phalanx_screen.dart';
import 'screens/weekly_schedule_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/workout_provider.dart';
import 'providers/ingestion_provider.dart';
import 'services/dom_rl_engine.dart';
import 'services/firebase_sync_service.dart';
import 'services/ai_plan_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  String? initError;
  
  try {
    await Firebase.initializeApp();
    
    // Enable offline persistence for Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    FirebaseSyncService().initialize();
    await FirebaseSyncService().ensureAuthenticated(); // Ensure user can store data
    await DomRlEngine().initialize();
    firebaseInitialized = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    initError = e.toString();
    debugPrint('Firebase initialization failed: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
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

class NeospartanApp extends StatefulWidget {
  final bool firebaseInitialized;
  final String? initError;
  
  const NeospartanApp({
    super.key,
    required this.firebaseInitialized,
    this.initError,
  });

  @override
  State<NeospartanApp> createState() => _NeospartanAppState();
}

class _NeospartanAppState extends State<NeospartanApp> {
  bool _hasCompletedOnboarding = true; // Default to true while checking
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseInitialized) {
      _checkOnboardingStatus();
    }
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final firebase = FirebaseSyncService();
      final hasCompleted = await firebase.hasCompletedOnboarding();
      setState(() {
        _hasCompletedOnboarding = hasCompleted;
        _isCheckingOnboarding = false;
      });
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      setState(() {
        _hasCompletedOnboarding = false; // Show onboarding if error
        _isCheckingOnboarding = false;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _hasCompletedOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget home;
    
    if (!widget.firebaseInitialized) {
      home = FirebaseInitErrorScreen(error: widget.initError);
    } else if (_isCheckingOnboarding) {
      home = const Scaffold(
        backgroundColor: LaconicTheme.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: LaconicTheme.spartanBronze),
        ),
      );
    } else if (!_hasCompletedOnboarding) {
      home = OnboardingScreen(onComplete: _onOnboardingComplete);
    } else {
      home = const NeospartanShell();
    }

    return MaterialApp(
      title: 'Neospartan',
      theme: LaconicTheme.theme,
      home: home,
      debugShowCheckedModeBanner: false,
    );
  }
}

class NeospartanShell extends StatefulWidget {
  const NeospartanShell({super.key});

  @override
  State<NeospartanShell> createState() => _NeospartanShellState();
}

class _NeospartanShellState extends State<NeospartanShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const AgogeScreen(),      // Training - Combat Conditioning
    const WeeklyScheduleScreen(), // Schedule - Weekly Plan
    const GarrisonScreen(),   // Recovery - Readiness & Armor
    const StadionScreen(),    // Exercises - Movement Library
    const StoicScreen(),      // Mindset - Mental Conditioning
    const PhalanxScreen(),    // Import - Plan Ingestion
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildMinimalistDrawer(),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Minimalist Floating Menu Button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.menu, color: LaconicTheme.spartanBronze, size: 30),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
          _drawerItem(2, "RECOVERY", Icons.shield_outlined, "Readiness & Armor"),
          _drawerItem(3, "EXERCISES", Icons.directions_run, "Movement Library"),
          _drawerItem(4, "MINDSET", Icons.psychology, "Mental Conditioning"),
          _drawerItem(5, "IMPORT", Icons.document_scanner, "Plan Ingestion"),
          const Spacer(),
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
      leading: Icon(icon, color: isSelected ? LaconicTheme.spartanBronze : Colors.grey),
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
              color: isSelected ? LaconicTheme.spartanBronze : Colors.grey.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }
}

class ModulePlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  const ModulePlaceholder({super.key, required this.title, required this.subtitle});

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
              const Icon(
                Icons.cloud_off,
                color: Colors.red,
                size: 64,
              ),
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
                error ?? 'Unable to connect to Firebase.\nCheck your configuration and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
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
                        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
                        ChangeNotifierProvider(create: (_) => IngestionProvider()),
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
