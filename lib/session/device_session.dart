import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

import '../audit/audit_chain.dart';
import '../auth/authorization_controller.dart';
import '../core/battery_models.dart';
import '../core/inverter_models.dart';
import '../core/simulation_clock.dart';
import '../integration/compatibility_engine.dart';
import '../integration/compatibility_models.dart';
import '../integration/link_diagnostics.dart';
import '../gateway/gateway_contract.dart';
import '../parameters/parameter_backup.dart';
import '../parameters/parameter_models.dart' hide RestorePlan;
import '../parameters/write_pipeline.dart';
import '../persistence/local_database.dart';
import '../protocol/bms_adapter.dart';
import '../protocol/inverter_adapter.dart';
import '../simulator/simulation_scenario.dart';
import '../transport/safe_frame_transport.dart';

enum DeviceSessionMode { readOnly, writeAuthorized }

enum DeviceSessionLinkState { connecting, online, unavailable }

class DeviceSession extends ChangeNotifier {
  DeviceSession({
    SimulationScenario scenario = SimulationScenario.communicationFaults,
    this.pollInterval = const Duration(milliseconds: 500),
    this.database,
    this.auditSecretStore,
    TechnicianAuthenticator? authenticator,
    LoopbackGatewayTransport? gatewayTransport,
    bool autoStart = true,
  }) : _scenario = scenario,
       _snapshot = ScenarioFactory.create(
         scenario,
         tick: _initialTick(scenario),
       ).snapshot,
       _adapter = SimulatedBmsAdapter(
         scenario: scenario,
         initialTick: _initialTick(scenario),
       ),
       _providedGatewayTransport = gatewayTransport,
       auth = AuthorizationController(authenticator: authenticator) {
    _beginSession();
    _gatewayTransport =
        _providedGatewayTransport ??
        LoopbackGatewayTransport(
          mode: GatewayOperatingMode.listenOnly,
          guard: const TransmissionGuard(
            activeSession: true,
            profileVerifiedForHardware: false,
          ),
          maxFramesPerSecond: 1,
          busLoadCap: 0.1,
          audit: _audit,
          negotiationState: GatewayNegotiationState.passiveAccepted,
        );
    auth.addListener(notifyListeners);
    if (database != null) _backups.addAll(database!.listBackups());
    if (autoStart) start();
  }

  final Duration pollInterval;
  final LocalDatabase? database;
  final SecretStore? auditSecretStore;
  final AuthorizationController auth;
  final LoopbackGatewayTransport? _providedGatewayTransport;
  late final LoopbackGatewayTransport _gatewayTransport;
  SimulationScenario _scenario;
  TelemetrySnapshot _snapshot;
  BmsAdapter _adapter;
  IdentificationResult? _lastIdentification;
  final InverterAdapter _inverterAdapter = SimulatedInverterAdapter();
  InverterTelemetrySnapshot? _inverterSnapshot;
  Timer? _pollTimer;
  bool _polling = false;
  bool _disposed = false;
  DeviceSessionLinkState _linkState = DeviceSessionLinkState.connecting;
  LinkHealth? _linkHealth;
  Set<String> _alarmCodes = const {};
  Map<String, num> _parameters = const {};
  final List<ParameterBackup> _backups = [];
  late AuditChain _audit;
  WriteResult? _lastWriteResult;
  int _writeSequence = 0;
  Object? _lastError;
  late String _sessionId;
  late DateTime _sessionStartedAt;
  bool _sessionStartedEventSaved = false;
  DeviceSessionLinkState? _persistedLinkState;
  Set<String>? _persistedAlarmCodes;
  bool _libraryWritesBlocked = false;

  SimulationScenario get scenario => _scenario;
  TelemetrySnapshot get snapshot => _snapshot;
  BmsAdapter get adapter => _adapter;
  DeviceSessionMode get mode => auth.isUnlocked
      ? DeviceSessionMode.writeAuthorized
      : DeviceSessionMode.readOnly;
  DeviceSessionLinkState get linkState => _linkState;
  LinkHealth? get linkHealth => _linkHealth;
  Set<String> get alarmCodes => _alarmCodes;
  Map<String, num> get parameters => _parameters;
  List<ParameterBackup> get backups => List.unmodifiable(_backups);
  AuditChain get audit => _audit;
  WriteResult? get lastWriteResult => _lastWriteResult;
  Object? get lastError => _lastError;
  AuditAvailability get auditAvailability => _audit.availability;
  bool get auditIntegrityAvailable =>
      auditAvailability == AuditAvailability.available;
  bool get simulated => true;
  InverterTelemetrySnapshot? get inverterSnapshot => _inverterSnapshot;
  GatewayRuntimeStatus get gatewayStatus => _gatewayTransport.status;
  List<DiagnosticSessionRecord> get history => database?.listSessions() ?? [];
  List<DiagnosticEventRecord> eventsFor(String sessionId) =>
      database?.listEvents(sessionId) ?? [];
  List<TelemetrySampleRecord> samplesFor(String sessionId) =>
      database?.listTelemetrySamples(sessionId) ?? [];
  String auditHeadFor(String sessionId) =>
      database?.loadAuditHead(sessionId) ?? 'GENESIS';
  String get activeProfileId => _adapter.profileIdentity.profileId;
  bool get libraryWritesBlocked => _libraryWritesBlocked;

  void setLibraryWriteBlocked(bool blocked) {
    if (_libraryWritesBlocked == blocked) return;
    _libraryWritesBlocked = blocked;
    notifyListeners();
  }

  static const parameterDefinitions = <String, ParameterDefinition>{
    'charge_limit': ParameterDefinition(
      id: 'charge_limit',
      unit: 'V',
      minimum: 50,
      maximum: 56,
      step: .1,
      scale: .1,
      riskTier: ParameterRiskTier.advanced,
      requiredAuthorization: AuthorizationTier.technician,
      writeVerifiedOnHardware: false,
      dependencies: [
        ParameterDependency(parameterId: 'service_mode', allowedValues: {1}),
      ],
    ),
    'service_mode': ParameterDefinition(
      id: 'service_mode',
      unit: '',
      minimum: 0,
      maximum: 1,
      step: 1,
      riskTier: ParameterRiskTier.standard,
      requiredAuthorization: AuthorizationTier.technician,
      writeVerifiedOnHardware: false,
    ),
  };

  CompatibilityAssessment get compatibilityAssessment {
    final battery = BatteryIntegrationProfile(
      chargeVoltageWindow: _snapshot.chargeVoltageLimit.value == null
          ? const SourcedValue.unavailable('not_reported')
          : SourcedValue.reported(
              VoltageWindow(
                minimum: _snapshot.voltage.value ?? 0,
                maximum: _snapshot.chargeVoltageLimit.value!,
              ),
              EvidenceSource.deviceReported,
            ),
      dischargeVoltageWindow: const SourcedValue.unavailable('not_reported'),
      maximumChargeCurrent: _snapshot.chargeCurrentLimit.value == null
          ? const SourcedValue.unavailable('not_reported')
          : SourcedValue.reported(
              _snapshot.chargeCurrentLimit.value!,
              EvidenceSource.deviceReported,
            ),
      maximumDischargeCurrent: _snapshot.dischargeCurrentLimit.value == null
          ? const SourcedValue.unavailable('not_reported')
          : SourcedValue.reported(
              _snapshot.dischargeCurrentLimit.value!,
              EvidenceSource.deviceReported,
            ),
      chemistry: const SourcedValue.unavailable('profile_required'),
      spokenProtocols: const {},
    );
    const inverter = InverterIntegrationProfile(
      configuredChargeVoltage: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      configuredLowVoltageCutoff: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      configuredChargeCurrent: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      configuredDischargeCurrent: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      supportedChemistries: {},
      supportedBatteryProtocols: {},
    );
    return const CompatibilityEngine().assess(
      battery: battery,
      inverter: inverter,
    );
  }

  LinkDiagnosticResult get linkDiagnostics {
    // يُشتق عدد الرسائل المتوقعة من معدل الاستطلاع الفعلي:
    // بافتراض رسالتين لكل دورة استطلاع (telemetry + alarms) وفق الـ protocol
    // المحاكى. عند توفر profile حقيقي، يُمرَّر هذا الرقم من الـ adapter.
    final expectedMessages = pollInterval.inMilliseconds > 0
        ? (const Duration(seconds: 1).inMilliseconds ~/
                  pollInterval.inMilliseconds) *
              2
        : 2;
    final receivedMessages = _linkState == DeviceSessionLinkState.online
        ? (expectedMessages * (1 - (_linkHealth?.errorRate ?? 0))).round()
        : 0;
    final batterySoc = _snapshot.soc.value == null
        ? const SourcedValue<double>.unavailable('not_reported')
        : SourcedValue<double>.reported(
            _snapshot.soc.value!,
            EvidenceSource.deviceReported,
          );
    return const LinkDiagnostics().analyze(
      LinkObservation(
        window: Duration(seconds: 1),
        expectedMessages: expectedMessages,
        receivedMessages: receivedMessages,
        timeouts: _linkHealth?.timeouts ?? 0,
        crcFailures: _linkHealth?.crcFailures ?? 0,
        inverterSoc: const SourcedValue.unavailable('inverter_not_connected'),
        batterySoc: batterySoc,
      ),
    );
  }

  List<IntegrationRecommendation> get integrationRecommendations =>
      const CompatibilityEngine().recommendations(compatibilityAssessment);

  static int _initialTick(SimulationScenario scenario) =>
      scenario == SimulationScenario.communicationFaults ? 2 : 0;

  void _beginSession() {
    _sessionStartedAt = DateTime.now().toUtc();
    _sessionId = 'sim-${_sessionStartedAt.microsecondsSinceEpoch}';
    _sessionStartedEventSaved = false;
    _persistedLinkState = null;
    _persistedAlarmCodes = null;
    auth.lock('session switch');
    _lastIdentification = null;
    _audit = AuditChain(
      store: database == null
          ? null
          : DatabaseAuditChainStore(
              database: database!,
              sessionId: _sessionId,
            ),
      secretStore: auditSecretStore,
    );
  }

  void start() {
    if (_pollTimer != null) return;
    unawaited(refresh());
    unawaited(refreshParameters());
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  Future<void> selectScenario(SimulationScenario scenario) async {
    if (_scenario == scenario) return;
    _scenario = scenario;
    final initialTick = _initialTick(scenario);
    _adapter = SimulatedBmsAdapter(
      scenario: scenario,
      initialTick: initialTick,
    );
    _snapshot = ScenarioFactory.create(scenario, tick: initialTick).snapshot;
    _linkState = DeviceSessionLinkState.connecting;
    _linkHealth = null;
    _alarmCodes = const {};
    _parameters = const {};
    _lastError = null;
    _beginSession();
    notifyListeners();
    await refresh();
    await refreshParameters();
  }

  Future<void> refreshParameters() async {
    try {
      _parameters = Map.unmodifiable(await _adapter.readParameters());
      _lastError = null;
    } catch (error) {
      _lastError = error;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  ParameterBackup createParameterBackup() {
    if (_parameters.isEmpty) {
      throw StateError('Parameters must be read before creating a backup.');
    }
    final profile = _adapter.profileIdentity;
    final backup = ParameterBackup(
      schemaVersion: 1,
      profileId: profile.profileId,
      deviceIdentity: profile.deviceId,
      firmware: profile.firmware,
      capturedAt: DateTime.now().toUtc(),
      values: Map.unmodifiable(_parameters),
    );
    _backups.insert(0, backup);
    database?.saveBackup(backup);
    notifyListeners();
    return backup;
  }

  DeviceWriteContext createWriteContext() {
    final ident = _lastIdentification;
    final profile = _adapter.profileIdentity;
    final String? connectedModel = ident?.model;
    final String? connectedFirmware = ident?.firmware;
    final DeviceWriteState state;
    final bool writeLocked;

    if (ident == null || connectedModel == null || connectedFirmware == null) {
      state = DeviceWriteState.unknownVerify;
      writeLocked = true;
    } else if (connectedModel != profile.model ||
        connectedFirmware != profile.firmware) {
      state = DeviceWriteState.identityMismatch;
      writeLocked = true;
    } else {
      state = DeviceWriteState.known;
      writeLocked =
          !auth.isUnlocked ||
          _linkState != DeviceSessionLinkState.online ||
          _lastError != null ||
          !auditIntegrityAvailable ||
          _libraryWritesBlocked;
    }

    return DeviceWriteContext(
      deviceId: connectedModel != null ? profile.deviceId : 'UNIDENTIFIED',
      sessionId: _sessionId,
      profileModel: profile.model,
      profileFirmware: profile.firmware,
      connectedModel: connectedModel,
      connectedFirmware: connectedFirmware,
      linkHealthy: _linkState == DeviceSessionLinkState.online,
      writeLocked: writeLocked,
      state: state,
    );
  }

  RestorePlan planRestore(ParameterBackup backup) => backup.createRestorePlan(
    activeProfileId: _adapter.profileIdentity.profileId,
    activeDeviceIdentity: _adapter.profileIdentity.deviceId,
    activeFirmware: _adapter.profileIdentity.firmware,
    definitions: parameterDefinitions,
    current: ParameterSnapshot(_parameters, capturedAt: DateTime.now().toUtc()),
  );

  /// استعادة نسخة احتياطية من المعاملات وفق خطة استعادة [RestorePlan].
  ///
  /// يتطلب تفويضاً صريحاً [authorization]، وتوكينات تأكيد لكل خطوة [confirmations]،
  /// وموافقة المستخدم الصريحة [safetyAcknowledged].
  /// يتوقف عند أول خطوة تفشل أو لا تُطبَّق ولا يُكمل تلقائياً.
  Future<List<WriteResult>> restoreParameterBackup({
    required RestorePlan plan,
    required AuthorizationSession authorization,
    required List<ConfirmationToken> confirmations,
    required bool safetyAcknowledged,
  }) async {
    if (_parameters.isEmpty) await refreshParameters();
    final results = <WriteResult>[];
    for (var i = 0; i < plan.changes.length; i++) {
      if (i >= confirmations.length) break;
      final change = plan.changes[i];
      final confirmation = confirmations[i];
      final result = await applySimulatedParameterChange(
        parameterId: change.definition.id,
        requestedValue: change.requestedValue,
        authorization: authorization,
        confirmation: confirmation,
        safetyAcknowledged: safetyAcknowledged,
      );
      results.add(result);
      if (result.outcome != WriteOutcome.applied) {
        break;
      }
    }
    return List.unmodifiable(results);
  }

  Future<WriteResult> applySimulatedParameterChange({
    required String parameterId,
    required num requestedValue,
    required AuthorizationSession authorization,
    required ConfirmationToken confirmation,
    required bool safetyAcknowledged,
  }) async {
    final definition = parameterDefinitions[parameterId];
    final before = _parameters[parameterId];
    if (definition == null || before == null) {
      throw ArgumentError.value(parameterId, 'parameterId');
    }
    _lastIdentification ??= await _adapter.identify();
    final context = createWriteContext();
    final change = ParameterChange(
      definition: definition,
      requestedValue: requestedValue,
    );
    final result =
        await VerifiedWritePipeline(
          transport: _adapter.parameterTransport(),
          audit: _audit,
        ).execute(
          change: change,
          authorization: authorization,
          safetyAcknowledged: safetyAcknowledged,
          context: context,
          confirmation: confirmation,
          idempotencyKey: 'sim-${_writeSequence++}-$parameterId',
        );
    _lastWriteResult = result;
    await refreshParameters();
    return result;
  }

  Future<void> refresh() async {
    if (_polling) return;
    _polling = true;
    try {
      _lastIdentification ??= await _adapter.identify();
      final next = await _adapter.readTelemetry();
      final health = await _adapter.health();
      final alarms = await _adapter.readAlarms();
      _inverterSnapshot = await _inverterAdapter.readTelemetry();
      final inverterAdapter = _inverterAdapter;
      if (inverterAdapter is SimulationClock) inverterAdapter.advance();
      _snapshot = next;
      _linkHealth = health;
      _alarmCodes = Set.unmodifiable(alarms);
      _linkState = DeviceSessionLinkState.online;
      _lastError = null;
      _persistSnapshot(next);
    } catch (error) {
      _linkState = DeviceSessionLinkState.unavailable;
      _lastError = error;
      _persistStateEvents();
    } finally {
      final adapter = _adapter;
      if (adapter is SimulationClock) adapter.advance();
      _polling = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _persistSnapshot(TelemetrySnapshot snapshot) {
    final store = database;
    if (store == null) return;
    final snapshotJson = jsonEncode({
      'timestamp': snapshot.timestamp.toUtc().toIso8601String(),
      'staleAfterMs': snapshot.staleAfter.inMilliseconds,
      'voltage': _measurementJson(snapshot.voltage),
      'current': _measurementJson(snapshot.current),
      'power': _measurementJson(snapshot.power),
      'soc': _measurementJson(snapshot.soc),
      'soh': _measurementJson(snapshot.soh),
      'remainingCapacity': _measurementJson(snapshot.remainingCapacity),
      'fullChargeCapacity': _measurementJson(snapshot.fullChargeCapacity),
      'cycleCount': _measurementJson(snapshot.cycleCount),
      'cells': snapshot.cellMeasurements.map(_measurementJson).toList(),
      'temperatures': [
        for (final sensor in snapshot.temperatureSensors)
          {
            'label': sensor.label,
            'kind': sensor.kind.name,
            'measurement': _measurementJson(sensor.measurement),
          },
      ],
      'chargeMosfet': _measurementJson(snapshot.chargeMosfet),
      'dischargeMosfet': _measurementJson(snapshot.dischargeMosfet),
      'contactor': _measurementJson(snapshot.contactor),
      'balancingMask': _measurementJson(snapshot.balancingMask),
      'chargeCurrentLimit': _measurementJson(snapshot.chargeCurrentLimit),
      'dischargeCurrentLimit': _measurementJson(snapshot.dischargeCurrentLimit),
      'chargeVoltageLimit': _measurementJson(snapshot.chargeVoltageLimit),
      'rawAlarmBits': _measurementJson(snapshot.rawAlarmBits),
      'rawProtectionBits': _measurementJson(snapshot.rawProtectionBits),
      'linkStatus': _measurementJson(snapshot.linkStatus),
      'alarms': _alarmCodes.toList()..sort(),
    });
    store.saveSession(
      DiagnosticSessionRecord(
        id: _sessionId,
        startedAt: _sessionStartedAt,
        updatedAt: DateTime.now().toUtc(),
        scenario: _scenario.name,
        simulated: true,
        snapshotJson: snapshotJson,
        dataHash: sha256.convert(utf8.encode(snapshotJson)).toString(),
      ),
    );
    store.saveTelemetrySample(
      sessionId: _sessionId,
      capturedAt: snapshot.timestamp,
      snapshotJson: snapshotJson,
      qualityFlags: {
        'voltage': snapshot.voltage.quality.name,
        'current': snapshot.current.quality.name,
        'soc': snapshot.soc.quality.name,
        'soh': snapshot.soh.quality.name,
        'cells': [
          for (final cell in snapshot.cellMeasurements) cell.quality.name,
        ],
        'temperatures': [
          for (final sensor in snapshot.temperatureSensors)
            sensor.measurement.quality.name,
        ],
      },
    );
    _persistStateEvents();
  }

  void _persistStateEvents() {
    final store = database;
    if (store == null) return;
    final now = DateTime.now().toUtc();
    if (!_sessionStartedEventSaved) {
      if (store.listSessions().any((record) => record.id == _sessionId)) {
        store.saveEvent(
          sessionId: _sessionId,
          occurredAt: _sessionStartedAt,
          type: 'session_started',
          payload: {'scenario': _scenario.name, 'simulated': true},
        );
        _sessionStartedEventSaved = true;
      } else {
        return;
      }
    }
    if (_persistedLinkState != _linkState) {
      store.saveEvent(
        sessionId: _sessionId,
        occurredAt: now,
        type: 'link_state_changed',
        payload: {'state': _linkState.name},
      );
      _persistedLinkState = _linkState;
    }
    if (_persistedAlarmCodes == null ||
        !_sameSet(_persistedAlarmCodes!, _alarmCodes)) {
      store.saveEvent(
        sessionId: _sessionId,
        occurredAt: now,
        type: 'alarms_changed',
        payload: {'codes': _alarmCodes.toList()..sort()},
      );
      _persistedAlarmCodes = Set.of(_alarmCodes);
    }
  }

  static bool _sameSet(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);

  static Map<String, Object?> _measurementJson(Measurement measurement) => {
    'value': measurement.value,
    'unit': measurement.unit,
    'timestamp': measurement.timestamp?.toUtc().toIso8601String(),
    'quality': measurement.quality.name,
    'absenceReason': measurement.absenceReason?.name,
  };

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    auth.removeListener(notifyListeners);
    auth.dispose();
    super.dispose();
  }
}

class DeviceSessionScope extends InheritedNotifier<DeviceSession> {
  const DeviceSessionScope({
    super.key,
    required DeviceSession session,
    required super.child,
  }) : super(notifier: session);

  static DeviceSession of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DeviceSessionScope>();
    assert(scope != null, 'DeviceSessionScope is missing above this context.');
    return scope!.notifier!;
  }
}
