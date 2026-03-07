import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_calendar/main.dart';

void main() {
  testWidgets('App renders calendar title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NepaliCalendarApp()),
    );
    await tester.pumpAndSettle();

    // Verify the app bar title is displayed in Nepali.
    expect(find.text('नेपाली पात्रो'), findsWidgets);
  });
}
