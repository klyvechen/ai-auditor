// Verifies the host side of the plugin-embedding contract (docs/plugin-contract.md): the
// framework imports a module's `Shell` and drops it into the content area / a pushed route with
// no extra provider setup, and the module's own `Scaffold`/`AppBar` shows up unmodified.
import 'package:ai_auditor/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Shell (email-assist) reads SharedPreferences on init; there's no real platform in a
    // widget test, so mock the channel the same way email-assist's own shell_test does.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('wide layout: side rail lists modules, content area embeds the selected Shell', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AiAuditorApp());
    await tester.pump(); // let Shell's SharedPreferences future resolve
    expect(tester.takeException(), isNull);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Gmail 整理助手'), findsWidgets); // rail label + content area title

    // With no backend token configured, email-assist's Shell lands on its Settings tab — same
    // text its own shell_test asserts on.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('後端連線'), findsOneWidget);
  });

  testWidgets('narrow layout: module list -> tap -> fullscreen Shell with an automatic back button', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AiAuditorApp());
    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(find.text('Gmail 整理助手'), findsOneWidget);
    expect(find.text('定時檢查 Gmail,用 AI 找出多餘的信件,經審核後移到垃圾桶或退訂。'), findsOneWidget);

    await tester.tap(find.text('Gmail 整理助手'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The framework added no back button itself — this is the module's own AppBar picking up
    // the pushed route's pop capability automatically.
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('後端連線'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('AI-Auditor'), findsOneWidget); // back on the module list
  });
}
