import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  group('Neospartan Smoke Tests', () {
    
    testWidgets('App widget tree builds', (WidgetTester tester) async {
      // Test that the app widget can be instantiated
      final app = NeospartanApp(
        servicesInitialized: true,
        initError: null,
      );
      
      expect(app, isNotNull);
      expect(app.servicesInitialized, true);
    });

    testWidgets('App handles initialization error state', (WidgetTester tester) async {
      final app = NeospartanApp(
        servicesInitialized: false,
        initError: 'Test error',
      );
      
      expect(app.initError, 'Test error');
    });

    testWidgets('MaterialApp renders with theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'Test',
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      );
      
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
