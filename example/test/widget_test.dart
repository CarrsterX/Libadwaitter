import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libadwaitter/libadwaitter.dart';

void main() {
  testWidgets('AdwaitaDemoApplication renders initial demo window',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AdwaitaDemoApplication());
    await tester.pumpAndSettle();

    expect(find.byType(AdwApplication), findsOneWidget);
    expect(find.byType(AdwNavigationSplitView), findsOneWidget);
  });
}
