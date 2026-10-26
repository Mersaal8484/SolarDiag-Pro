import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solardiag_pro/app/solardiag_app.dart';
import 'package:solardiag_pro/audit/audit_chain.dart';
import 'package:solardiag_pro/auth/authorization_controller.dart';
import 'package:solardiag_pro/gateway/gateway_contract.dart';
import 'package:solardiag_pro/features/device_library.dart';
import 'package:solardiag_pro/parameters/parameter_models.dart';
import 'package:solardiag_pro/parameters/write_pipeline.dart';
import 'package:solardiag_pro/session/device_session.dart';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';
import 'package:solardiag_pro/persistence/local_database.dart';
import 'package:solardiag_pro/transport/safe_frame_transport.dart';
import 'support/test_secret_store.dart';

/// Measurements show either the generic freshness label or an explicit
/// capture timestamp; both are honest freshness statements.
const _fresh = '(Updated now|Captured at .*)';

void main() {
  testWidgets('missing audit key preserves reads and shows a warning', (
    tester,
  ) async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
    );
    addTearDown(session.dispose);
    await session.refresh();
    await session.refreshParameters();

    await tester.pumpWidget(
      SolarDiagApp(session: session, initialRoute: '/parameters'),
    );
    await tester.pumpAndSettle();

    expect(session.parameters['charge_limit'], 55.2);
    expect(session.auditAvailability, AuditAvailability.keyUnavailable);
    expect(
      find.text('Audit key unavailable. Write operations are locked.'),
      findsOneWidget,
    );
  });

  testWidgets('three-step onboarding persists completion locally', (
    tester,
  ) async {
    final database = LocalDatabase.inMemory();
    await tester.pumpWidget(
      SolarDiagApp(
        database: database,
        auditSecretStore: TestSecretStore(),
        showOnboarding: true,
      ),
    );

    expect(find.text('Diagnose energy systems with evidence'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Read-only comes first'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Connect an isolated gateway'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(database.getBool('onboarding_complete'), isTrue);
    expect(find.byKey(const Key('connection-capsule')), findsOneWidget);
  });

  testWidgets('named deep link opens battery workspace directly', (
    tester,
  ) async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);
    await session.refresh();

    await tester.pumpWidget(
      SolarDiagApp(session: session, initialRoute: '/battery'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Battery / BMS diagnostics'), findsOneWidget);
    expect(find.textContaining('78 %'), findsOneWidget);
  });

  testWidgets('shows simulator, read-only mode, and honest missing data', (
    tester,
  ) async {
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    expect(find.byKey(const Key('connection-capsule')), findsOneWidget);
    expect(find.text('SIMULATED'), findsOneWidget);
    expect(find.text('READ-ONLY'), findsOneWidget);
    final dashboardScroll = find.descendant(
      of: find.byType(CustomScrollView).first,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Not reported by device'),
      300,
      scrollable: dashboardScroll,
    );
    expect(find.text('Not reported by device'), findsOneWidget);
  });

  final primaryReadingSemantics = <({String route, RegExp label})>[
    (route: '/', label: RegExp('PACK VOLTAGE, .*V.*, $_fresh')),
    (route: '/battery', label: RegExp('State of charge, .*%.*, $_fresh')),
    (route: '/inverter', label: RegExp('DC voltage, .*V.*, $_fresh')),
    (route: '/gateway', label: RegExp('Observed bus load, .*%.*, $_fresh')),
    (
      route: '/parameters',
      label: RegExp('Charge voltage limit, .*V.*, $_fresh'),
    ),
    (route: '/link', label: RegExp('message delivery, .*, $_fresh')),
  ];
  for (final screen in primaryReadingSemantics) {
    testWidgets('${screen.route} exposes its primary value to semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final session = DeviceSession(
        scenario: SimulationScenario.healthy,
        autoStart: false,
        auditSecretStore: TestSecretStore(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      if (screen.route == '/parameters') await session.refreshParameters();

      await tester.pumpWidget(
        SolarDiagApp(session: session, initialRoute: screen.route),
      );
      await tester.pumpAndSettle();

      try {
        if (screen.route == '/parameters') {
          final semanticsWidget = tester.widget<Semantics>(
            find.byKey(const ValueKey('parameter-inspector-semantics')),
          );
          expect(semanticsWidget.properties.label, matches(screen.label));
        } else {
          expect(find.bySemanticsLabel(screen.label), findsOneWidget);
        }
      } finally {
        // Must be disposed inside the test body: tear-downs run after the
        // framework's leaked-handle verification.
        semantics.dispose();
      }
    });
  }

  testWidgets('switches to Arabic RTL and dark theme', (tester) async {
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    await tester.tap(find.byKey(const Key('toggle-locale')));
    await tester.pumpAndSettle();
    expect(find.text('الطاقة، بوضوح كامل.'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الطاقة، بوضوح كامل.'))),
      TextDirection.rtl,
    );
    await tester.tap(find.byKey(const Key('toggle-theme')));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('الطاقة، بوضوح كامل.'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('opens evidence-based advanced diagnostics', (tester) async {
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    final dashboardScroll = find.descendant(
      of: find.byType(CustomScrollView).first,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Open advanced diagnostics'),
      200,
      scrollable: dashboardScroll,
    );
    await tester.tap(find.text('Open advanced diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Advanced diagnostics'), findsOneWidget);
    expect(find.text('State of health: not available'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Temperature unavailable'), 250);
    expect(find.text('Temperature unavailable'), findsOneWidget);
  });

  testWidgets('workspace navigation opens device library', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    await tester.tap(find.byKey(const ValueKey('workspace-nav-library')));
    await tester.pumpAndSettle();
    expect(find.text('Device library'), findsOneWidget);
    // Checked before scrolling: lazily built list items above the fold are
    // unmounted once scrolled away.
    expect(find.text('SolarDiag deterministic BMS'), findsOneWidget);
    final libraryScroll = find.descendant(
      of: find.byType(DeviceLibraryScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Pylontech'),
      240,
      scrollable: libraryScroll,
    );
    expect(find.text('Pylontech'), findsOneWidget);
  });

  testWidgets('home destination opens adapter-backed inverter diagnostics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);
    await session.refresh();
    await tester.pumpWidget(SolarDiagApp(session: session));

    final destination = find.byKey(
      const ValueKey('destination-Inverter diagnostics'),
    );
    final dashboardScroll = find.descendant(
      of: find.byType(CustomScrollView).first,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      destination,
      300,
      scrollable: dashboardScroll,
    );
    await tester.tap(destination);
    await tester.pumpAndSettle();

    expect(find.text('SolarDiag simulated inverter'), findsOneWidget);
    expect(find.textContaining('230.0 V'), findsOneWidget);
    expect(
      find.text('Register map required from manufacturer.'),
      findsOneWidget,
    );
  });

  testWidgets('battery workspace shows live cells and raw alarms', (
    tester,
  ) async {
    final session = DeviceSession(
      scenario: SimulationScenario.electricalEvents,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);
    await session.refresh();
    await tester.pumpWidget(SolarDiagApp(session: session));

    await tester.tap(find.byKey(const ValueKey('workspace-nav-battery')));
    await tester.pumpAndSettle();
    expect(find.text('Battery / BMS diagnostics'), findsOneWidget);

    await tester.tap(find.text('Cell monitoring'));
    await tester.pumpAndSettle();
    expect(find.text('Minimum cell'), findsOneWidget);
    expect(find.textContaining('mV'), findsOneWidget);

    final sectionScroll = find.descendant(
      of: find.byKey(const Key('battery-section-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Fault diagnostics'),
      200,
      scrollable: sectionScroll,
    );
    await tester.tap(find.text('Fault diagnostics'));
    await tester.pumpAndSettle();
    expect(find.text('Cell overvoltage alarm'), findsOneWidget);
    expect(find.textContaining('CELL_OVERVOLTAGE'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Battery health'),
      200,
      scrollable: sectionScroll,
    );
    await tester.tap(find.text('Battery health'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('does not infer battery health'),
      findsOneWidget,
    );
  });

  testWidgets('gateway status comes from the live read-only session', (
    tester,
  ) async {
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    await tester.tap(find.text('Gateway'));
    await tester.pumpAndSettle();

    expect(find.text('Transmission guard'), findsOneWidget);
    expect(find.text('No transmission attempted'), findsOneWidget);
    expect(find.text('Passive session accepted'), findsOneWidget);
    expect(find.text('ENFORCED'), findsNothing);
  });

  testWidgets('gateway shows a real blocked decision and counters', (
    tester,
  ) async {
    final transport = LoopbackGatewayTransport(
      mode: GatewayOperatingMode.activeRead,
      guard: const TransmissionGuard(
        activeSession: true,
        profileVerifiedForHardware: false,
        allowedReadIdentifiers: {0x100},
      ),
      maxFramesPerSecond: 5,
      busLoadCap: 0.2,
      audit: AuditChain(),
      negotiationState: GatewayNegotiationState.activeReadAccepted,
    );
    final session = DeviceSession(
      gatewayTransport: transport,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);

    await expectLater(
      transport.send(
        const BusFrame(identifier: 0x200, payload: [1]),
        TransmissionPurpose.documentedRead,
      ),
      throwsStateError,
    );
    await tester.pumpWidget(
      SolarDiagApp(session: session, initialRoute: '/gateway'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.byKey(const Key('gateway-last-decision-reason')),
      250,
    );
    expect(find.text('Frame is not in the read allow-list.'), findsOneWidget);
    expect(find.text('Active-read session accepted'), findsOneWidget);
  });

  testWidgets('parameters are read from adapter and backup is functional', (
    tester,
  ) async {
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    await tester.pump();
    await tester.tap(find.text('Parameters'));
    await tester.pumpAndSettle();

    // The value is shown in the parameter row and in the inspector pane.
    expect(find.textContaining('55.2 V'), findsNWidgets(2));
    final parametersScroll = find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('No backups saved'),
      200,
      scrollable: parametersScroll,
    );
    expect(find.text('No backups saved'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Create backup'),
      200,
      scrollable: parametersScroll,
    );
    await tester.tap(find.text('Create backup'));
    await tester.pump();
    expect(find.text('1 backup saved'), findsOneWidget);
    expect(
      find.text('Configuration backup created from the current readback.'),
      findsOneWidget,
    );
  });

  testWidgets('desktop parameters list drives the detail inspector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);
    await session.refreshParameters();

    await tester.pumpWidget(
      SolarDiagApp(session: session, initialRoute: '/parameters'),
    );
    await tester.pumpAndSettle();

    final inspector = find.byKey(const Key('parameter-inspector'));
    expect(inspector, findsOneWidget);
    expect(
      find.descendant(
        of: inspector,
        matching: find.text('Charge voltage limit'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Service mode').first);
    await tester.pump();
    expect(
      find.descendant(of: inspector, matching: find.text('Service mode')),
      findsOneWidget,
    );
  });

  testWidgets('tablet parameters layout includes the detail inspector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);
    await session.refreshParameters();

    await tester.pumpWidget(
      SolarDiagApp(session: session, initialRoute: '/parameters'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('parameter-inspector')), findsOneWidget);
  });

  testWidgets('simulated parameter review confirms through readback', (
    tester,
  ) async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
      authenticator: const DemoConfiguration(
        isDemoMode: true,
        demoPin: 'pin',
      ).createAuthenticator(),
    );
    addTearDown(session.dispose);
    await session.refresh();
    await session.refreshParameters();
    await tester.pumpWidget(SolarDiagApp(session: session));
    await tester.tap(find.text('Parameters'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('edit-charge-limit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-charge-limit')));
    await tester.pumpAndSettle();
    expect(find.text('Review changes'), findsOneWidget);
    expect(find.byKey(const Key('parameter-diff')), findsOneWidget);

    final slider = find.byKey(const Key('parameter-slider'));
    await tester.tapAt(tester.getCenter(slider) - const Offset(40, 0));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-parameter-write')));
    await tester.pumpAndSettle();
    expect(find.text('Technician Authentication'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pin');
    await tester.tap(find.text('Authenticate'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Applied and verified by readback:'),
      findsOneWidget,
    );
    expect(session.lastWriteResult?.readback, isNotNull);
  });

  testWidgets('latest backup can be restored through the verified UI flow', (
    tester,
  ) async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
      authenticator: const DemoConfiguration(
        isDemoMode: true,
        demoPin: 'pin',
      ).createAuthenticator(),
    );
    addTearDown(session.dispose);
    await session.refresh();
    await session.refreshParameters();
    session.createParameterBackup();
    await session.auth.unlock(
      tier: AuthorizationTier.technician,
      credentials: 'pin',
    );
    final before = session.parameters['charge_limit']!;
    final context = session.createWriteContext();
    final diffHash = VerifiedWritePipeline.previewHash(
      ParameterChange(
        definition: DeviceSession.parameterDefinitions['charge_limit']!,
        requestedValue: 54.8,
      ),
      before,
      context,
    );
    await session.applySimulatedParameterChange(
      parameterId: 'charge_limit',
      requestedValue: 54.8,
      authorization: session.auth.current!,
      confirmation: ConfirmationToken(
        diffHash: diffHash,
        deviceId: context.deviceId,
        sessionId: context.sessionId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      ),
      safetyAcknowledged: true,
    );
    session.auth.lock();
    await tester.pumpWidget(SolarDiagApp(session: session));
    await tester.tap(find.text('Parameters'));
    await tester.pumpAndSettle();

    final parametersScroll = find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('restore-latest-backup')),
      200,
      scrollable: parametersScroll,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('compare-latest-backup')),
      120,
      scrollable: parametersScroll,
    );
    await tester.drag(parametersScroll, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('compare-latest-backup')));
    await tester.pumpAndSettle();
    expect(find.text('Backup comparison'), findsOneWidget);
    expect(find.text('Changed'), findsOneWidget);
    expect(find.textContaining('55.2 V'), findsWidgets);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('restore-latest-backup')));
    await tester.pumpAndSettle();
    expect(find.text('Restore configuration backup'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-backup-restore')));
    await tester.pumpAndSettle();
    expect(find.text('Technician Authentication'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pin');
    await tester.tap(find.text('Authenticate'));
    await tester.pumpAndSettle();

    expect(session.parameters['charge_limit'], closeTo(55.2, 1e-9));
    expect(find.textContaining('Restored and verified 1'), findsOneWidget);
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
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
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
    await tester.pumpWidget(SolarDiagApp(auditSecretStore: TestSecretStore()));
    await tester.pumpAndSettle();
    final dashboardScroll = find.descendant(
      of: find.byType(CustomScrollView).first,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('scenario-selector')),
      400,
      scrollable: dashboardScroll,
    );
    await tester.tap(find.byKey(const Key('scenario-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('highTemperature').last);
    await tester.pumpAndSettle();
    expect(find.text('highTemperature'), findsWidgets);
  });

  testWidgets('live session refresh changes an on-screen measurement', (
    tester,
  ) async {
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(SolarDiagApp(session: session));
    expect(find.textContaining('78 %'), findsOneWidget);

    await session.refresh();
    await session.refresh();
    await tester.pump();

    expect(find.textContaining('77 %'), findsOneWidget);
    expect(find.textContaining('78 %'), findsNothing);
  });

  testWidgets('diagnostic history exposes persisted session evidence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = LocalDatabase.inMemory();
    final session = DeviceSession(
      scenario: SimulationScenario.healthy,
      autoStart: false,
      database: database,
      auditSecretStore: TestSecretStore(),
    );
    addTearDown(session.dispose);
    addTearDown(database.close);
    await session.refresh();
    await tester.pumpWidget(SolarDiagApp(session: session));

    await tester.tap(find.byKey(const ValueKey('workspace-nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Diagnostic history'), findsOneWidget);
    expect(find.textContaining('SHA-256:'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('history-${session.history.single.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Session evidence'), findsOneWidget);
    expect(find.text('Session timeline'), findsOneWidget);
    expect(find.text('Session started'), findsOneWidget);
    expect(find.textContaining('"soc"'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ValueKey('export-${session.history.single.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Engineering report preview'), findsOneWidget);
    expect(find.text('SIMULATED'), findsOneWidget);
    expect(find.text('Choose export language'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report-language-bilingual')),
      findsOneWidget,
    );
  });
}
