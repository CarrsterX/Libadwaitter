import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libadwaitter/libadwaitter.dart';

void main() {
  testWidgets('libadwaitter re-exports Adwaitter widgets and platform helpers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const AdwApplication(
        home: AdwWindow(
          child: AdwToolbarView(
            topBar: AdwHeaderBar(
              title: Text('Libadwaitter Smoke Test'),
              showWindowControls: false,
            ),
            content: Center(
              child: AdwDragSource(
                text: 'Hello World!',
                child: Text('Draggable File'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Libadwaitter Smoke Test'), findsOneWidget);
    expect(find.text('Draggable File'), findsOneWidget);
  });
}
