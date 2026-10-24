import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/solardiag_app.dart';
import 'package:solardiag_pro/config/feature_flags.dart';
import 'package:solardiag_pro/studio/profile_builder.dart';

void main() {
  const validDraft = StudioProfileDraft(
    id: 'draft-1',
    manufacturer: 'Research',
    family: 'Synthetic',
    referenceIds: ['ref-1'],
    mappings: [
      FieldMapping(
        field: 'voltage',
        frameIdentifier: 0x351,
        offset: 0,
        length: 2,
        dataType: FieldDataType.unsigned16,
        scale: .01,
        unit: 'V',
        evidenceReferences: ['capture-1:1'],
      ),
    ],
  );

  test('valid draft exports as technician-disabled studio draft', () {
    final builder = const ProfileBuilder();
    expect(builder.validate(validDraft).isValid, isTrue);
    final json =
        jsonDecode(builder.exportStudioDraft(validDraft))
            as Map<String, Object?>;
    expect(json['verification_status'], 'studio-draft');
    expect(json['loadable_in_technician_mode'], isFalse);
    expect(json['write_capability'], 'disabled');
  });
  test('mapping without evidence is rejected', () {
    const invalid = StudioProfileDraft(
      id: 'draft-2',
      manufacturer: 'Research',
      family: 'Synthetic',
      referenceIds: [],
      mappings: [
        FieldMapping(
          field: 'voltage',
          frameIdentifier: 1,
          offset: 0,
          length: 2,
          dataType: FieldDataType.unsigned16,
          scale: 1,
          unit: 'V',
          evidenceReferences: [],
        ),
      ],
    );
    final result = const ProfileBuilder().validate(invalid);
    expect(
      result.issues.map((item) => item.code),
      contains('missing_evidence'),
    );
    expect(
      () => const ProfileBuilder().exportStudioDraft(invalid),
      throwsStateError,
    );
  });
  testWidgets('Studio feature is absent by default', (tester) async {
    await tester.pumpWidget(const SolarDiagApp());
    expect(find.text('Protocol Discovery Studio'), findsNothing);
    expect(find.byTooltip('Studio'), findsNothing);
  });
  testWidgets('enabled Studio opens ten-section engineering workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const SolarDiagApp(flags: FeatureFlags(studioEnabled: true)),
    );
    await tester.tap(find.byTooltip('Studio'));
    await tester.pumpAndSettle();
    expect(find.text('Protocol Discovery Studio'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.textContaining('PASSIVE — NO TRANSMIT'), findsOneWidget);

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();
    expect(find.text('Import formats'), findsOneWidget);
    expect(find.text('.sdcap v1/v2'), findsOneWidget);

    await tester.tap(find.text('Analysis'));
    await tester.pumpAndSettle();
    expect(find.text('Protocol evidence'), findsOneWidget);

    await tester.tap(find.text('Differential'));
    await tester.pumpAndSettle();
    expect(find.text('A/B/A'), findsWidgets);

    await tester.tap(find.text('Frame explorer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('studio-monitor-pause')), findsOneWidget);
    expect(find.byKey(const Key('studio-jump-live')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('studio-frame-0')));
    await tester.pump();
    expect(find.textContaining('HEX / ASCII'), findsOneWidget);
    expect(find.text('Jump to live'), findsOneWidget);
  });
}
