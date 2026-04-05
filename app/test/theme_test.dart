import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme.dart';

void main() {
  group('App Theme Tests', () {
    test('Theme colors are defined', () {
      expect(LaconicTheme.deepBlack, isNotNull);
      expect(LaconicTheme.ironGray, isNotNull);
      expect(LaconicTheme.spartanBronze, isNotNull);
    });

    test('Theme data is valid', () {
      final theme = LaconicTheme.theme;

      expect(theme, isNotNull);
      expect(theme.scaffoldBackgroundColor, LaconicTheme.deepBlack);
      expect(theme.primaryColor, LaconicTheme.spartanBronze);
    });
  });
}
