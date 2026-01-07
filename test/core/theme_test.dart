import 'package:flutter_test/flutter_test.dart';
import 'package:meddeck/core/theme.dart';

void main() {
  test('buildPlayfulTheme does not throw', () {
    final t = buildPlayfulTheme();
    expect(t, isNotNull);
  });

  test('buildMedicalTheme does not throw', () {
    final t = buildMedicalTheme();
    expect(t, isNotNull);
  });
}
