import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';
import 'package:gym_tracker_app/widgets/app_bottom_sheet.dart';

Future<void> pumpOpener(
  WidgetTester tester, {
  required List<Widget> Function(BuildContext) children,
  void Function(Object? result)? onClosed,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(Brightness.dark),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await showAppSheet<String>(
              context: context,
              children: children,
            );
            onClosed?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping the scrim closes the sheet', (tester) async {
    var closed = false;
    await pumpOpener(
      tester,
      children: (_) => const [Text('Sheet content')],
      onClosed: (result) {
        closed = true;
        expect(result, isNull);
      },
    );
    expect(find.text('Sheet content'), findsOneWidget);

    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();
    expect(find.text('Sheet content'), findsNothing);
    expect(closed, isTrue);
  });

  testWidgets('a sheet can return a value', (tester) async {
    Object? result;
    await pumpOpener(
      tester,
      children: (context) => [
        TextButton(
          onPressed: () => Navigator.of(context).pop('saved'),
          child: const Text('Save'),
        ),
      ],
      onClosed: (value) => result = value,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, 'saved');
  });

  testWidgets('a short sheet hugs its content at the bottom of the screen',
      (tester) async {
    await pumpOpener(
      tester,
      children: (_) => const [SizedBox(height: 100, child: Text('Short'))],
    );

    final sheet = tester.getRect(find.byType(AppSheet));
    expect(sheet.bottom, 844);
    expect(sheet.width, 390);
    // 10 top padding + 5 handle + 18 gap + 100 content + 40 bottom padding.
    expect(sheet.height, 173);
  });

  testWidgets('a tall sheet stops at 800 and scrolls inside', (tester) async {
    await pumpOpener(
      tester,
      children: (_) => const [
        SizedBox(height: 700, child: Text('Top')),
        SizedBox(height: 700, child: Text('Bottom')),
      ],
    );

    expect(tester.getSize(find.byType(AppSheet)).height, 800);
    expect(find.text('Bottom').hitTestable(), findsNothing);

    await tester.drag(find.text('Top'), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Bottom').hitTestable(), findsOneWidget);
    // Scrolling the content does not dismiss the sheet.
    expect(find.byType(AppSheet), findsOneWidget);
  });
}
