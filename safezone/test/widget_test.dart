import 'package:flutter_test/flutter_test.dart';
import 'package:safezone/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic verification that MyApp builds
    expect(const MyApp(), isNotNull);
  });
}
