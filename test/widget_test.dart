import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sudoku_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SudokuApp()),
    );

    // Verify the home screen renders with the title
    expect(find.text('SUDOKU'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
  });
}
