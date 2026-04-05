import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app/main.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/workout_provider.dart';
import 'package:app/providers/ingestion_provider.dart';
import 'package:app/screens/stadion_screen.dart';
import 'package:app/screens/auth/login_screen.dart';
import 'package:app/screens/garrison_screen.dart';
import 'package:app/screens/agoge_screen.dart';

void main() {
  group('Neospartan App Tests', () {
    // Test 1: App builds without errors
    testWidgets('App builds and shows initialization screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        NeospartanApp(servicesInitialized: true, initError: null),
      );

      // Should show either LoginScreen or loading
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    // Test 2: Main Navigation has all tabs
    testWidgets('MainNavigation has 5 bottom tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => WorkoutProvider()),
            ChangeNotifierProvider(create: (_) => IngestionProvider()),
          ],
          child: MaterialApp(home: MainNavigation()),
        ),
      );

      await tester.pumpAndSettle();

      // Check for 5 bottom navigation items
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.calendar_view_week), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    // Test 3: Stadion Screen renders
    testWidgets('StadionScreen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: StadionScreen()),
      );

      await tester.pumpAndSettle();

      // Should show the screen title
      expect(find.text('STADION'), findsOneWidget);
    });

    // Test 4: Garrison Screen renders
    testWidgets('GarrisonScreen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: GarrisonScreen()),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show loading initially or the screen content
      expect(find.byType(GarrisonScreen), findsOneWidget);
    });

    // Test 5: Agoge Screen renders
    testWidgets('AgogeScreen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: AgogeScreen()),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AgogeScreen), findsOneWidget);
    });

    // Test 6: Login Screen renders
    testWidgets('LoginScreen renders with email/password fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: LoginScreen()),
      );

      await tester.pumpAndSettle();

      // Should show email and password fields
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('SIGN IN'), findsOneWidget);
    });
  });
}
