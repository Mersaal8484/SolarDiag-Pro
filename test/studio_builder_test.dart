import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/solardiag_app.dart';
import 'package:solardiag_pro/config/feature_flags.dart';
import 'package:solardiag_pro/persistence/local_database.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/studio/capture_models.dart';
import 'package:solardiag_pro/studio/profile_builder.dart';
import 'package:solardiag_pro/studio/research_repository.dart';
import 'package:solardiag_pro/studio/sdcap_codec.dart';
import 'support/test_secret_store.dart';

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
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    expect(find.text('Protocol Discovery Studio'), findsNothing);
    expect(find.byTooltip('Studio'), findsNothing);
  });
  testWidgets('enabled Studio opens ten-section engineering workspace', (
    tester,
  ) async {
    final database = LocalDatabase.inMemory();
    addTearDown(database.close);
    final session = DeviceSession(
      database: database,
      auditSecretStore: TestSecretStore(),
      autoStart: false,
    );
    addTearDown(session.dispose);
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SolarDiagApp(
        flags: const FeatureFlags(studioEnabled: true),
        database: database,
        session: session,
        auditSecretStore: TestSecretStore(),
      ),
    );
    await tester.tap(find.byTooltip('Studio'));
    await tester.pumpAndSettle();
    expect(find.text('Protocol Discovery Studio'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('REPLAY LOCK'), findsOneWidget);

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

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Capture Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SolarDiag Capture (.sdcap)').last);
    await tester.pumpAndSettle();
    final importedData = const SdcapCodec().encode(
      CaptureSession(
        id: 'persisted-polling-capture',
        interfaceType: CaptureInterface.can,
        source: CaptureSource.sdcap,
        startedAt: DateTime.utc(2026),
        frames: const [
          CapturedFrame(
            timestampNanos: 0,
            rawBytes: [1, 2, 3],
            direction: CaptureDirection.tx,
            channel: 'can0',
            identifier: 0x351,
          ),
          CapturedFrame(
            timestampNanos: 100000000,
            rawBytes: [1, 2, 3],
            direction: CaptureDirection.tx,
            channel: 'can0',
            identifier: 0x351,
          ),
          CapturedFrame(
            timestampNanos: 200000000,
            rawBytes: [1, 2, 3],
            direction: CaptureDirection.tx,
            channel: 'can0',
            identifier: 0x351,
          ),
        ],
        synthetic: true,
        containsNdaMaterial: false,
        notes: 'Imported capture persistence test',
      ),
    );
    await tester.enterText(find.byType(TextField), importedData);
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    final savedSessions = database.researchSessionDocuments();
    final savedFindings = database.researchFindingDocuments();
    expect(savedSessions, hasLength(1));
    expect(savedFindings, isNotEmpty);

    final repository = LocalResearchRepository(database);
    final restoredSessions = await repository.sessions();
    final restoredFindings = await repository.findings();
    expect(restoredSessions.single.synthetic, isTrue);
    expect(restoredFindings.single.title, 'Repeated polling command');

    await tester.pumpWidget(
      SolarDiagApp(
        key: const ValueKey('restored-studio-app'),
        flags: const FeatureFlags(studioEnabled: true),
        database: database,
        session: session,
        auditSecretStore: TestSecretStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Studio'));
    await tester.pumpAndSettle();
    expect(find.text(restoredSessions.single.id), findsOneWidget);
    await tester.tap(find.text('Hypotheses'));
    await tester.pumpAndSettle();
    expect(find.text(restoredFindings.first.title), findsOneWidget);
  });
}
