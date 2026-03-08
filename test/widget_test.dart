import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:babaal_patro/main.dart';

void main() {
  testWidgets('App renders calendar title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BabaalPatroApp()));
    await tester.pumpAndSettle();

    // Verify the app bar title is displayed in Nepali.
    expect(find.text('नेपाली पात्रो'), findsWidgets);
  });
}
