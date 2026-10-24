// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SolarDiag Pro';

  @override
  String get designLab => 'Design Lab';

  @override
  String get designLabIntro =>
      'A living reference for the instrument language, components, symbols and accessible states.';

  @override
  String get foundations => 'Foundations';

  @override
  String get measurements => 'Measurements';

  @override
  String get cells => 'Cell views';

  @override
  String get safetyStates => 'Safety states';

  @override
  String get studioComponents => 'Studio components';

  @override
  String get overview => 'Overview';

  @override
  String get library => 'Library';

  @override
  String get link => 'Link';

  @override
  String get gateway => 'Gateway';

  @override
  String get studio => 'Studio';

  @override
  String get contribute => 'Contribute';

  @override
  String get battery => 'Battery';

  @override
  String get simulatedScenario => 'Simulated scenario';

  @override
  String get openAdvancedDiagnostics => 'Open advanced diagnostics';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String get highContrast => 'High contrast';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get themeSetting => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get digitPreference => 'Digit preference';

  @override
  String get westernDigits => 'Western (0–9)';

  @override
  String get arabicIndicDigits => 'Arabic-Indic (٠–٩)';

  @override
  String get workshopMode => 'Workshop mode';

  @override
  String get workshopModeDescription =>
      'Use controls at least 56 points high and keep the display active during sessions.';

  @override
  String get outdoorMode => 'Outdoor high contrast';

  @override
  String get outdoorModeDescription =>
      'Increase contrast and separator strength for bright environments.';

  @override
  String get timeAxisDirection => 'Time axis left to right';

  @override
  String get timeAxisDirectionDescription =>
      'Keep technical time charts progressing left to right.';

  @override
  String get reduceTransparency => 'Reduce transparency';

  @override
  String get reduceTransparencyDescription =>
      'Use opaque navigation and overlay surfaces.';

  @override
  String get voltageUnit => 'V';

  @override
  String get pipelineValidate => 'Validate';

  @override
  String get pipelineIdentify => 'Verify identity';

  @override
  String get pipelineBackup => 'Create backup';

  @override
  String get pipelineAuthorize => 'Authorize';

  @override
  String get pipelineConfirm => 'Confirm diff';

  @override
  String get pipelineWrite => 'Write';

  @override
  String get pipelineReadback => 'Read back';

  @override
  String get pipelineVerify => 'Verify';

  @override
  String get pipelineAudit => 'Append audit';

  @override
  String get readOnly => 'READ-ONLY';

  @override
  String get tagline => 'Energy, made legible.';

  @override
  String get bank => '48V Battery Bank';

  @override
  String get healthy => '16-cell LiFePO₄ · nominal scenario';

  @override
  String get current => 'Current';

  @override
  String get temperature => 'Temperature';

  @override
  String get cellDelta => 'Cell delta';

  @override
  String get notReportedByDevice => 'Not reported by device';

  @override
  String get cellBalance => 'Cell balance';

  @override
  String get rawValues => 'Raw values reported by the simulated BMS';

  @override
  String get simulatedGateway => 'Simulator gateway';

  @override
  String get virtualInterface => 'Virtual bus';

  @override
  String get simulatedBms => 'Simulated BMS';

  @override
  String get simulatedProfile => 'LFP-16S-SIM';

  @override
  String get readOnlyMode => 'READ-ONLY';

  @override
  String get connecting => 'Connecting';

  @override
  String get online => 'Online';

  @override
  String get linkUnavailable => 'Link unavailable';

  @override
  String get transmissionGuard => 'Transmission guard';

  @override
  String get transmissionBlocked => 'Transmission blocked in read-only mode';

  @override
  String get serviceMode => 'Service mode';

  @override
  String get noParametersReported =>
      'No parameters were reported by the active adapter.';

  @override
  String get backupCreated =>
      'Configuration backup created from the current readback.';

  @override
  String backupsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count backups saved',
      one: '1 backup saved',
      zero: 'No backups saved',
    );
    return '$_temp0';
  }

  @override
  String get editParameter => 'Edit simulated parameter';

  @override
  String get technicianAuthentication => 'Technician Authentication';

  @override
  String get technicianPin => 'Technician PIN';

  @override
  String get pinAuthorizationHint => 'Enter PIN to authorize write operations';

  @override
  String get authenticateAction => 'Authenticate';

  @override
  String get reviewChanges => 'Review changes';

  @override
  String get parameterRiskAdvanced =>
      'Risk: advanced · verified simulator only';

  @override
  String get safetyAcknowledgement =>
      'I reviewed the range, consequence, and current readback.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmSimulatedWrite => 'Confirm simulated write';

  @override
  String writeAppliedWithReadback(String value) {
    return 'Applied and verified by readback: $value';
  }

  @override
  String get writeRejected => 'The write was rejected by the safety pipeline.';

  @override
  String get auditKeyUnavailable =>
      'Audit key unavailable. Write operations are locked.';

  @override
  String get writeFailedVerify =>
      'Write failed. Device state must be verified before another change.';

  @override
  String get symbols => 'SolarDiag Symbols';

  @override
  String get simulated => 'SIMULATED';

  @override
  String get monitor => 'MONITOR';

  @override
  String get connected => 'Connected';

  @override
  String get updatedNow => 'Updated now';

  @override
  String get packVoltage => 'Pack voltage';

  @override
  String get stateOfCharge => 'State of charge';

  @override
  String get warning => 'Warning';

  @override
  String get registerMapRequired => 'Register map required from manufacturer.';

  @override
  String get noActiveAlarms => 'No active alarms reported';

  @override
  String get passiveNoTransmit => 'PASSIVE — NO TRANSMIT';

  @override
  String get evidence => 'Evidence';

  @override
  String get emptyTitle => 'No session selected';

  @override
  String get emptyMessage =>
      'Connect a simulator or a verified device profile to begin.';

  @override
  String cellCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cells',
      many: '$count cells',
      few: '$count cells',
      two: '2 cells',
      one: '1 cell',
      zero: 'No cells',
    );
    return '$_temp0';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get backAction => 'Back';

  @override
  String get contributeSafely => 'Contribute safely';

  @override
  String get contributionPrivacy =>
      'Nothing leaves this device until redaction is previewed and granular consent is granted.';

  @override
  String get selectData => 'Select data';

  @override
  String get ownedDeviceLog => 'Owned-device diagnostic log';

  @override
  String get syntheticExcluded =>
      'Simulated and synthetic captures are excluded automatically.';

  @override
  String get redactionPreview => 'Redaction preview';

  @override
  String get consent => 'Consent';

  @override
  String get shareLogs => 'Share redacted diagnostic logs';

  @override
  String get shareNotes => 'Share engineer notes';

  @override
  String get submit => 'Submit';

  @override
  String get mockPortalOnly => 'Mock portal only';

  @override
  String get packageReady =>
      'Package is ready for the offline queue. Production upload is not configured.';

  @override
  String get selectConsent => 'Select at least one consent category.';

  @override
  String get libraryUpdates => 'Library updates';

  @override
  String get noProductionChannel =>
      'No production channel configured · last-known-good remains active';

  @override
  String redactedFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sensitive fields redacted',
      one: '1 sensitive field redacted',
      zero: 'No sensitive fields redacted',
    );
    return '$_temp0';
  }

  @override
  String get identificationEvidence => 'How we identified this device';

  @override
  String get manualSelectionWarning =>
      'Manually selected — verify model and firmware before trusting decoded data.';

  @override
  String get noIdentificationEvidence =>
      'No identification evidence is available.';

  @override
  String get protocolStudio => 'Protocol Discovery Studio';

  @override
  String get timeMicroseconds => 'TIME µs';

  @override
  String get direction => 'DIRECTION';

  @override
  String get payload => 'PAYLOAD';

  @override
  String confidencePercent(int value) {
    return '$value% confidence';
  }

  @override
  String get technicianPublicationDisabled => 'TECHNICIAN PUBLICATION DISABLED';

  @override
  String get studioDraft => 'STUDIO-DRAFT';

  @override
  String get studioEngineering => 'STUDIO / ENGINEERING';

  @override
  String get replayLock => 'REPLAY LOCK';

  @override
  String get deviceLibrary => 'Device library';

  @override
  String get libraryVerificationNote =>
      'Verification status is shown per profile. Planned is not supported.';

  @override
  String get deterministicBms => 'SolarDiag deterministic BMS';

  @override
  String get simulatorOnly => 'LFP-16S-SIM · Simulator only';

  @override
  String get researchTargets => 'Research targets';

  @override
  String get noVerifiedDefinition => 'No verified definition is bundled';

  @override
  String get research => 'RESEARCH';

  @override
  String get planned => 'PLANNED';

  @override
  String get diagnosticGateway => 'Diagnostic gateway';

  @override
  String get gatewayDescription =>
      'Connection checklist and declared capabilities.';

  @override
  String get defaultMode => 'Default mode';

  @override
  String get listenOnly => 'Listen-only';

  @override
  String get connectionChecklist => 'Connection checklist';

  @override
  String get isolatedInterfaceCheck =>
      'Use an isolated interface appropriate for the device.';

  @override
  String get pinoutCheck => 'Confirm connector pinout from a verified profile.';

  @override
  String get terminationCheck => 'Confirm termination before enabling the bus.';

  @override
  String get transmissionBlockedCheck =>
      'Transmission remains blocked without an active profile.';

  @override
  String get parameters => 'Parameters';

  @override
  String get simulatorValuesNotice =>
      'Simulator values. Physical writes remain unavailable.';

  @override
  String get simulatedWritePipeline =>
      'SIMULATED WRITE PIPELINE · Readback required';

  @override
  String get chargeVoltageLimit => 'Charge voltage limit';

  @override
  String get chargeCurrentLimit => 'Charge current limit';

  @override
  String get lowVoltageCutoff => 'Low voltage cutoff';

  @override
  String get createBackup => 'Create backup';

  @override
  String get physicalWriteLocked => 'Physical write locked';

  @override
  String get inverterBatteryLink => 'Inverter ↔ Battery';

  @override
  String get linkDescription =>
      'Read-only compatibility and communication evidence.';

  @override
  String get live => 'Live';

  @override
  String get deliveryUnavailable => 'Message delivery unavailable';

  @override
  String get messageDelivery => 'message delivery';

  @override
  String get recommendationsNeverApplied =>
      'Recommendations are never applied automatically.';

  @override
  String get advancedDiagnostics => 'Advanced diagnostics';

  @override
  String get evidenceBeforeConclusions => 'Evidence before conclusions.';

  @override
  String get diagnosticEvidenceNote =>
      'Every finding below is tied to a reported value or raw alarm. Missing evidence stays unavailable.';

  @override
  String get sohUnavailable => 'State of health: not available';

  @override
  String get sohUnavailableReason =>
      'The device did not report SOH and available samples cannot prove it.';

  @override
  String get cellsBalanced => 'Cells are balanced';

  @override
  String get cellImbalanceDetected => 'Cell imbalance detected';

  @override
  String get temperatureUnavailable => 'Temperature unavailable';

  @override
  String get temperatureNormal => 'Temperature is normal';

  @override
  String get temperatureHigh => 'High temperature';

  @override
  String get cellOvervoltageAlarm => 'Cell overvoltage alarm';

  @override
  String get unrecognizedAlarm => 'Unrecognized device alarm';

  @override
  String get rawCodePreserved =>
      'The raw code is preserved without guessing its meaning.';

  @override
  String get cellsBalancedDetail =>
      'The reported cell spread is within the configured attention threshold.';

  @override
  String get cellImbalanceDetail =>
      'The reported spread exceeds the configured threshold. Inspect raw cell values.';

  @override
  String get temperatureUnavailableDetail =>
      'No temperature value was reported; no thermal conclusion was made.';

  @override
  String get temperatureNormalDetail =>
      'The reported temperature is below the configured warning threshold.';

  @override
  String get temperatureHighDetail =>
      'The reported temperature exceeds a configured safety threshold.';

  @override
  String get cellOvervoltageDetail =>
      'The BMS raw alarm map reports cell overvoltage.';

  @override
  String get history => 'History';

  @override
  String get diagnosticHistory => 'Diagnostic history';

  @override
  String get historyDescription =>
      'Locally stored sessions with integrity hashes and captured evidence.';

  @override
  String get noSavedSessions => 'No diagnostic sessions have been saved yet.';

  @override
  String scenarioValue(String value) {
    return 'Scenario: $value';
  }

  @override
  String lastUpdatedValue(String value) {
    return 'Last updated: $value';
  }

  @override
  String integrityHashValue(String value) {
    return 'SHA-256: $value...';
  }

  @override
  String get sessionEvidence => 'Session evidence';

  @override
  String get closeAction => 'Close';

  @override
  String get exportJsonPdf => 'Export JSON + PDF';

  @override
  String reportExported(String pdfPath, String jsonPath) {
    return 'Report exported: $pdfPath · $jsonPath';
  }

  @override
  String get reportExportFailed =>
      'Report export failed integrity or file checks.';

  @override
  String get restoreLatestBackup => 'Restore latest backup';

  @override
  String get restoreBackup => 'Restore configuration backup';

  @override
  String restoreBackupConfirmation(int count) {
    return 'Restore $count changed parameters through the verified write and readback pipeline?';
  }

  @override
  String get confirmRestore => 'Confirm restore';

  @override
  String get backupAlreadyMatches =>
      'The active configuration already matches this backup.';

  @override
  String backupRestoreComplete(int count) {
    return 'Restored and verified $count parameters.';
  }

  @override
  String get backupRestoreFailed =>
      'Restore stopped because a write or readback verification failed.';

  @override
  String get inverter => 'Inverter';

  @override
  String get inverterDiagnostics => 'Inverter diagnostics';

  @override
  String get inverterDiagnosticsDescription =>
      'Adapter-reported simulator telemetry and honest research-profile limitations.';

  @override
  String get simulatedInverterProfile => 'SolarDiag simulated inverter';

  @override
  String get simulatedInverterEvidence =>
      'Deterministic Modbus simulator · simulated evidence';

  @override
  String get freconResearchProfile => 'FRECON PV100/PV200 · research target';

  @override
  String get waitingForInverterTelemetry => 'Waiting for inverter telemetry.';

  @override
  String get dcVoltage => 'DC voltage';

  @override
  String get dcCurrent => 'DC current';

  @override
  String get dcPower => 'DC power';

  @override
  String get acVoltage => 'AC voltage';

  @override
  String get acCurrent => 'AC current';

  @override
  String get acPower => 'AC power';

  @override
  String get frequency => 'Frequency';

  @override
  String get simulatedTelemetryActive => 'Simulated telemetry active';

  @override
  String get batteryBmsDiagnostics => 'Battery / BMS diagnostics';

  @override
  String get liveTelemetryActive => 'Live telemetry active';

  @override
  String get telemetryUnavailable => 'Telemetry unavailable';

  @override
  String get linkEvidenceAvailable => 'Communication evidence available';

  @override
  String get verificationStatusVisible =>
      'Verification status shown per profile';

  @override
  String savedSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved sessions',
      one: '1 saved session',
      zero: 'No saved sessions',
    );
    return '$_temp0';
  }

  @override
  String get recentSessions => 'Recent sessions';

  @override
  String get batteryWorkspaceDescription =>
      'Live battery evidence organized for inspection without inferred values.';

  @override
  String get cellMonitoring => 'Cell monitoring';

  @override
  String get faultDiagnostics => 'Fault diagnostics';

  @override
  String get power => 'Power';

  @override
  String get stateOfHealth => 'State of health';

  @override
  String get cycleCount => 'Cycle count';

  @override
  String get noCellReadings => 'No cell readings were reported by the device.';

  @override
  String get minimumCell => 'Minimum cell';

  @override
  String get maximumCell => 'Maximum cell';

  @override
  String cellVoltageValue(int index, String value) {
    return 'Cell $index: $value V';
  }

  @override
  String cellNumber(int index) {
    return 'Cell $index';
  }

  @override
  String rawAlarmCode(String code) {
    return 'Raw alarm code: $code';
  }

  @override
  String get cellBalancing => 'Cell balancing';

  @override
  String get batteryHealth => 'Battery health';

  @override
  String get serviceFunctions => 'Service functions';

  @override
  String get reports => 'Reports';

  @override
  String get parallelBank => 'Parallel bank';

  @override
  String get balancingMask => 'Balancing mask';

  @override
  String get balancingUnavailable => 'Balancing state was not reported';

  @override
  String get noCellsBalancing => 'No cells are reported as balancing';

  @override
  String get balancingReportedActive =>
      'The device reports active cell balancing';

  @override
  String get balancingEvidenceNote =>
      'This status is decoded only from the reported balancing bitmask.';

  @override
  String get fullChargeCapacity => 'Full-charge capacity';

  @override
  String get healthMethodNote =>
      'SOH is shown only when device-reported. SolarDiag does not infer battery health from a single snapshot.';

  @override
  String get configurationParameters => 'Configuration parameters';

  @override
  String get simulatedWriteOnly =>
      'Verified writes are available only against the simulator profile.';

  @override
  String get calibration => 'Calibration';

  @override
  String get noVerifiedCalibrationProcedure =>
      'Unavailable: no hardware-verified calibration procedure is bundled.';

  @override
  String get factoryFunctions => 'Factory functions';

  @override
  String get factoryFunctionsUnavailable =>
      'Unavailable: manufacturer authorization and verified documentation are required.';

  @override
  String get reportsAvailableFromHistory =>
      'Generate integrity-checked JSON and PDF reports from Diagnostic history.';

  @override
  String get parallelModuleTelemetryUnavailable =>
      'Per-module parallel-bank telemetry was not reported by the active adapter.';

  @override
  String get onboardingPurpose => 'Diagnose energy systems with evidence';

  @override
  String get onboardingPurposeDetail =>
      'SolarDiag organizes reported inverter and battery data without inventing unavailable values.';

  @override
  String get onboardingReadOnly => 'Read-only comes first';

  @override
  String get onboardingReadOnlyDetail =>
      'Connections start passive. Any supported change requires authorization, review, confirmation and readback.';

  @override
  String get onboardingConnect => 'Connect an isolated gateway';

  @override
  String get onboardingConnectDetail =>
      'Verify the interface, connector pinout and termination from trusted documentation before connecting hardware.';

  @override
  String get startDiagnostics => 'Start diagnostics';

  @override
  String get compareLatestBackup => 'Compare latest backup';

  @override
  String get backupComparison => 'Backup comparison';

  @override
  String backupComparisonValues(String backup, String current) {
    return 'Backup: $backup · Current: $current';
  }

  @override
  String get changed => 'Changed';

  @override
  String get unchanged => 'Unchanged';

  @override
  String get notAvailable => 'Not available';

  @override
  String get sessionTimeline => 'Session timeline';

  @override
  String get noTimelineEvents => 'No timeline events were recorded.';

  @override
  String get rawSessionEvidence => 'Raw session evidence';

  @override
  String get sessionStarted => 'Session started';

  @override
  String get linkStateChanged => 'Link state changed';

  @override
  String get alarmsChanged => 'Alarm state changed';

  @override
  String get sessionEvent => 'Session event';

  @override
  String get previewReport => 'Preview report';

  @override
  String get reportPreview => 'Engineering report preview';

  @override
  String get reportContentsDescription =>
      'The export includes identification, firmware, profile status, timestamps, readings, alarms, parameters, findings and the verified session hash.';

  @override
  String get reportLanguage => 'Choose export language';

  @override
  String get bilingual => 'Bilingual';

  @override
  String get compatibilityCannotDetermine => 'Cannot determine';

  @override
  String get requiredEvidenceUnavailable =>
      'Required evidence is unavailable; compatibility cannot be claimed.';

  @override
  String get unknown => 'Unknown';

  @override
  String get chargeVoltage => 'Charge voltage';

  @override
  String get chargeCurrent => 'Charge current';

  @override
  String get dischargeCurrent => 'Discharge current';

  @override
  String get chemistry => 'Chemistry';

  @override
  String get protocol => 'Protocol';

  @override
  String get requiredVoltageEvidenceUnavailable =>
      'Required voltage evidence is unavailable.';

  @override
  String get requiredCurrentEvidenceUnavailable =>
      'Required current evidence is unavailable.';

  @override
  String get chemistryCompatibilityUnproven =>
      'Chemistry compatibility cannot be proven.';

  @override
  String get protocolIntersectionUnavailable =>
      'No verified protocol intersection can be evaluated.';

  @override
  String get researchSession => 'Research session';

  @override
  String get syntheticCanStudy => 'Synthetic CAN study';

  @override
  String get isolatedSessionNoHardware =>
      'One isolated session · no hardware attached';

  @override
  String get frames => 'Frames';

  @override
  String get identifiers => 'Identifiers';

  @override
  String get source => 'Source';

  @override
  String get synthetic => 'Synthetic';

  @override
  String get locked => 'Locked';

  @override
  String get sessions => 'Sessions';

  @override
  String get capture => 'Capture';

  @override
  String get frameExplorer => 'Frame explorer';

  @override
  String get analysis => 'Analysis';

  @override
  String get differential => 'Differential';

  @override
  String get hypotheses => 'Hypotheses';

  @override
  String get profileBuilder => 'Profile builder';

  @override
  String get mappingEditor => 'Mapping editor';

  @override
  String get validation => 'Validation';

  @override
  String get export => 'Export';

  @override
  String get operatingMode => 'Operating mode';

  @override
  String get activeRead => 'Active read';

  @override
  String get writeMode => 'Write';

  @override
  String get noTransmissionAttempted => 'No transmission attempted';

  @override
  String get guardAllowed => 'Allowed';

  @override
  String get guardBlocked => 'Blocked';

  @override
  String get allowedFrames => 'Allowed frames';

  @override
  String get blockedFrames => 'Blocked frames';

  @override
  String get droppedFrames => 'Dropped frames';

  @override
  String get observedBusLoad => 'Observed bus load';

  @override
  String get negotiationState => 'Negotiation state';

  @override
  String get notNegotiated => 'Not negotiated';

  @override
  String get passiveNegotiated => 'Passive session accepted';

  @override
  String get activeReadNegotiated => 'Active-read session accepted';

  @override
  String get writeNegotiated => 'Write session accepted';

  @override
  String get lastGuardDecision => 'Last guard decision';

  @override
  String get compatibilityCompatible => 'Compatible';

  @override
  String get compatibilityCompatibleWithLimits => 'Compatible with limits';

  @override
  String get compatibilityIncompatible => 'Incompatible profile';

  @override
  String get compatibilityStateCompatible => 'Compatible';

  @override
  String get compatibilityStateAttention => 'Attention';

  @override
  String get compatibilityStateIncompatible => 'Incompatible';
}
