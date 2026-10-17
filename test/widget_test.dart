import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/solardiag_app.dart';

void main() {
  testWidgets('shows simulator, read-only mode, and honest missing data', (
    tester,
  ) async {
    await tester.pumpWidget(const SolarDiagApp());
    expect(find.text('SIMULATED'), findsOneWidget);
    expect(find.text('READ-ONLY'), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not reported by device'), findsOneWidget);
  });

  testWidgets('switches to Arabic RTL and dark theme', (tester) async {
    await tester.pumpWidget(const SolarDiagApp());
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    expect(find.text('الطاقة، بوضوح كامل.'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الطاقة، بوضوح كامل.'))),
      TextDirection.rtl,
    );
    await tester.tap(find.byIcon(Icons.contrast));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('الطاقة، بوضوح كامل.'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('opens evidence-based advanced diagnostics', (tester) async {
    await tester.pumpWidget(const SolarDiagApp());
    await tester.tap(find.text('Open advanced diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Advanced diagnostics'), findsOneWidget);
    expect(find.text('State of health: not available'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Temperature unavailable'), 250);
    expect(find.text('Temperature unavailable'), findsOneWidget);
  });

  testWidgets('workspace navigation opens device library', (tester) async {
    await tester.pumpWidget(const SolarDiagApp());
    await tester.tap(find.byIcon(Icons.library_books_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Device library'), findsOneWidget);
    expect(find.text('Pylontech'), findsOneWidget);
    expect(find.text('SolarDiag deterministic BMS'), findsOneWidget);
  });

  testWidgets('mobile layout tolerates large accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const SolarDiagApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Energy, made legible.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('simulator scenario can be selected in the UI', (tester) async {
    tester.view.physicalSize = const Size(1440, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SolarDiagApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('scenario-selector')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('scenario-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('highTemperature').last);
    await tester.pumpAndSettle();
    expect(find.text('highTemperature'), findsWidgets);
  });
}
