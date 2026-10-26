import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/theme.dart';
import 'package:solardiag_pro/design/components.dart';
import 'package:solardiag_pro/design/solar_icon.dart';
import 'package:solardiag_pro/design/solar_icons.g.dart';
import 'package:solardiag_pro/design/tokens.g.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      theme: solarTheme(
        brightness: brightness,
        highContrast: false,
        reduceTransparency: false,
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('SolarIcon renders without an explicit color in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const SolarIcon(SolarIcons.battery)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SolarIcon), findsOneWidget);
  });

  testWidgets('SolarSurface is flat: no backdrop blur layer', (tester) async {
    await tester.pumpWidget(_host(const SolarSurface(child: Text('x'))));
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('x'), findsOneWidget);
  });

  testWidgets('SolarSurface accepts a hero gradient and radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SolarSurface(
          radius: SolarRadius.hero,
          gradient: LinearGradient(colors: [Colors.blue, Colors.teal]),
          child: Text('hero'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('hero'), findsOneWidget);
  });
}
