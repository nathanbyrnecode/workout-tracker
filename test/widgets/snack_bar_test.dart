import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/theme/app_theme.dart';
import 'package:gym_tracker_app/theme/app_tokens.dart';
import 'package:gym_tracker_app/widgets/app_shell.dart';
import 'package:gym_tracker_app/widgets/app_tab_bar.dart';

const _message = 'Workout saved';

/// [child] in the app theme, on a phone-sized surface.
Future<void> pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(Brightness.dark),
    home: child,
  ));
}

Future<void> showMessage(WidgetTester tester) async {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
      .showSnackBar(const SnackBar(content: Text(_message)));
  await tester.pumpAndSettle();
}

Rect snackBarRect(WidgetTester tester) => tester.getRect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.byType(Material),
      ),
    );

AppShell shell({Widget? floatingActions}) => AppShell(
      selected: AppTab.home,
      onSelected: (_) {},
      floatingActions: floatingActions,
      child: const SizedBox.expand(),
    );

void main() {
  testWidgets('floats above the floating actions, with a gap', (tester) async {
    await pump(
      tester,
      shell(
        floatingActions: const SizedBox(
          key: ValueKey('actions'),
          height: 58,
          width: double.infinity,
        ),
      ),
    );
    await showMessage(tester);

    final actions = tester.getRect(find.byKey(const ValueKey('actions')));
    final snackBar = snackBarRect(tester);
    expect(snackBar.bottom, lessThanOrEqualTo(actions.top - 12));
    expect(snackBar.bottom, greaterThan(actions.top - 40));
  });

  testWidgets('with no floating actions, floats just above the tab bar',
      (tester) async {
    await pump(tester, shell());
    await showMessage(tester);

    final tabBar = tester.getRect(find.byType(AppTabBar));
    final snackBar = snackBarRect(tester);
    expect(snackBar.bottom, lessThanOrEqualTo(tabBar.top - 12));
    expect(snackBar.bottom, greaterThan(tabBar.top - 40));
  });

  testWidgets('outside the shell, sits near the bottom with screen margins',
      (tester) async {
    await pump(tester, const Scaffold(body: SizedBox.expand()));
    await showMessage(tester);

    final snackBar = snackBarRect(tester);
    expect(snackBar.left, 20);
    expect(snackBar.right, 390 - 20);
    expect(snackBar.bottom, greaterThan(844 - 40));
  });

  testWidgets('is styled from the tokens', (tester) async {
    await pump(tester, const Scaffold(body: SizedBox.expand()));
    await showMessage(tester);

    final t = AppTokens.of(Brightness.dark);
    final theme = Theme.of(tester.element(find.text(_message)));
    expect(theme.snackBarTheme.backgroundColor, t.sheet);
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    final text = tester.widget<Text>(find.text(_message));
    final style = DefaultTextStyle.of(tester.element(find.text(_message)));
    expect(text.style, isNull);
    expect(style.style.color, t.fg);
  });
}
