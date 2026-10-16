import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/solardiag_app.dart';

void main() {
  testWidgets('shows simulator, read-only mode, and honest missing data', (
    tester,
  ) async {
    await tester.pumpWidget(const SolarDiagApp());
    expect(find.text('SIMULATED'), findsOneWidget);
    expect(find.text('Not reported by device'), findsOneWidget);
    expect(find.text('READ-ONLY'), findsOneWidget);
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
}
