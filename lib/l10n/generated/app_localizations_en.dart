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
  String get readOnly => 'READ-ONLY';

  @override
  String get tagline => 'Energy, made legible.';

  @override
  String get bank => '48V Battery Bank';

  @override
  String get healthy => '16-cell LiFePO₄ · Connected';

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
  String get lowVoltageCutoff => 'Low-voltage cutoff';

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
}
