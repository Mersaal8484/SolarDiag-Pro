import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SolarDiag Pro'**
  String get appTitle;

  /// No description provided for @designLab.
  ///
  /// In en, this message translates to:
  /// **'Design Lab'**
  String get designLab;

  /// No description provided for @designLabIntro.
  ///
  /// In en, this message translates to:
  /// **'A living reference for the instrument language, components, symbols and accessible states.'**
  String get designLabIntro;

  /// No description provided for @foundations.
  ///
  /// In en, this message translates to:
  /// **'Foundations'**
  String get foundations;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @cells.
  ///
  /// In en, this message translates to:
  /// **'Cell views'**
  String get cells;

  /// No description provided for @safetyStates.
  ///
  /// In en, this message translates to:
  /// **'Safety states'**
  String get safetyStates;

  /// No description provided for @studioComponents.
  ///
  /// In en, this message translates to:
  /// **'Studio components'**
  String get studioComponents;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @gateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gateway;

  /// No description provided for @studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// No description provided for @contribute.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get contribute;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @simulatedScenario.
  ///
  /// In en, this message translates to:
  /// **'Simulated scenario'**
  String get simulatedScenario;

  /// No description provided for @openAdvancedDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Open advanced diagnostics'**
  String get openAdvancedDiagnostics;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get toggleTheme;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'READ-ONLY'**
  String get readOnly;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Energy, made legible.'**
  String get tagline;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'48V Battery Bank'**
  String get bank;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'16-cell LiFePO₄ · Connected'**
  String get healthy;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @cellDelta.
  ///
  /// In en, this message translates to:
  /// **'Cell delta'**
  String get cellDelta;

  /// No description provided for @notReportedByDevice.
  ///
  /// In en, this message translates to:
  /// **'Not reported by device'**
  String get notReportedByDevice;

  /// No description provided for @cellBalance.
  ///
  /// In en, this message translates to:
  /// **'Cell balance'**
  String get cellBalance;

  /// No description provided for @rawValues.
  ///
  /// In en, this message translates to:
  /// **'Raw values reported by the simulated BMS'**
  String get rawValues;

  /// No description provided for @simulatedGateway.
  ///
  /// In en, this message translates to:
  /// **'Simulator gateway'**
  String get simulatedGateway;

  /// No description provided for @virtualInterface.
  ///
  /// In en, this message translates to:
  /// **'Virtual bus'**
  String get virtualInterface;

  /// No description provided for @simulatedBms.
  ///
  /// In en, this message translates to:
  /// **'Simulated BMS'**
  String get simulatedBms;

  /// No description provided for @simulatedProfile.
  ///
  /// In en, this message translates to:
  /// **'LFP-16S-SIM'**
  String get simulatedProfile;

  /// No description provided for @readOnlyMode.
  ///
  /// In en, this message translates to:
  /// **'READ-ONLY'**
  String get readOnlyMode;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @linkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Link unavailable'**
  String get linkUnavailable;

  /// No description provided for @transmissionGuard.
  ///
  /// In en, this message translates to:
  /// **'Transmission guard'**
  String get transmissionGuard;

  /// No description provided for @transmissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Transmission blocked in read-only mode'**
  String get transmissionBlocked;

  /// No description provided for @serviceMode.
  ///
  /// In en, this message translates to:
  /// **'Service mode'**
  String get serviceMode;

  /// No description provided for @noParametersReported.
  ///
  /// In en, this message translates to:
  /// **'No parameters were reported by the active adapter.'**
  String get noParametersReported;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Configuration backup created from the current readback.'**
  String get backupCreated;

  /// No description provided for @backupsSaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No backups saved} =1{1 backup saved} other{{count} backups saved}}'**
  String backupsSaved(int count);

  /// No description provided for @editParameter.
  ///
  /// In en, this message translates to:
  /// **'Edit simulated parameter'**
  String get editParameter;

  /// No description provided for @reviewChanges.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get reviewChanges;

  /// No description provided for @parameterRiskAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Risk: advanced · verified simulator only'**
  String get parameterRiskAdvanced;

  /// No description provided for @safetyAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I reviewed the range, consequence, and current readback.'**
  String get safetyAcknowledgement;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmSimulatedWrite.
  ///
  /// In en, this message translates to:
  /// **'Confirm simulated write'**
  String get confirmSimulatedWrite;

  /// No description provided for @writeAppliedWithReadback.
  ///
  /// In en, this message translates to:
  /// **'Applied and verified by readback: {value}'**
  String writeAppliedWithReadback(String value);

  /// No description provided for @writeRejected.
  ///
  /// In en, this message translates to:
  /// **'The write was rejected by the safety pipeline.'**
  String get writeRejected;

  /// No description provided for @writeFailedVerify.
  ///
  /// In en, this message translates to:
  /// **'Write failed. Device state must be verified before another change.'**
  String get writeFailedVerify;

  /// No description provided for @symbols.
  ///
  /// In en, this message translates to:
  /// **'SolarDiag Symbols'**
  String get symbols;

  /// No description provided for @simulated.
  ///
  /// In en, this message translates to:
  /// **'SIMULATED'**
  String get simulated;

  /// No description provided for @monitor.
  ///
  /// In en, this message translates to:
  /// **'MONITOR'**
  String get monitor;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @updatedNow.
  ///
  /// In en, this message translates to:
  /// **'Updated now'**
  String get updatedNow;

  /// No description provided for @packVoltage.
  ///
  /// In en, this message translates to:
  /// **'Pack voltage'**
  String get packVoltage;

  /// No description provided for @stateOfCharge.
  ///
  /// In en, this message translates to:
  /// **'State of charge'**
  String get stateOfCharge;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @registerMapRequired.
  ///
  /// In en, this message translates to:
  /// **'Register map required from manufacturer.'**
  String get registerMapRequired;

  /// No description provided for @noActiveAlarms.
  ///
  /// In en, this message translates to:
  /// **'No active alarms reported'**
  String get noActiveAlarms;

  /// No description provided for @passiveNoTransmit.
  ///
  /// In en, this message translates to:
  /// **'PASSIVE — NO TRANSMIT'**
  String get passiveNoTransmit;

  /// No description provided for @evidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get evidence;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No session selected'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect a simulator or a verified device profile to begin.'**
  String get emptyMessage;

  /// No description provided for @cellCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No cells} =1{1 cell} =2{2 cells} few{{count} cells} many{{count} cells} other{{count} cells}}'**
  String cellCount(int count);

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @contributeSafely.
  ///
  /// In en, this message translates to:
  /// **'Contribute safely'**
  String get contributeSafely;

  /// No description provided for @contributionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves this device until redaction is previewed and granular consent is granted.'**
  String get contributionPrivacy;

  /// No description provided for @selectData.
  ///
  /// In en, this message translates to:
  /// **'Select data'**
  String get selectData;

  /// No description provided for @ownedDeviceLog.
  ///
  /// In en, this message translates to:
  /// **'Owned-device diagnostic log'**
  String get ownedDeviceLog;

  /// No description provided for @syntheticExcluded.
  ///
  /// In en, this message translates to:
  /// **'Simulated and synthetic captures are excluded automatically.'**
  String get syntheticExcluded;

  /// No description provided for @redactionPreview.
  ///
  /// In en, this message translates to:
  /// **'Redaction preview'**
  String get redactionPreview;

  /// No description provided for @consent.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get consent;

  /// No description provided for @shareLogs.
  ///
  /// In en, this message translates to:
  /// **'Share redacted diagnostic logs'**
  String get shareLogs;

  /// No description provided for @shareNotes.
  ///
  /// In en, this message translates to:
  /// **'Share engineer notes'**
  String get shareNotes;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @mockPortalOnly.
  ///
  /// In en, this message translates to:
  /// **'Mock portal only'**
  String get mockPortalOnly;

  /// No description provided for @packageReady.
  ///
  /// In en, this message translates to:
  /// **'Package is ready for the offline queue. Production upload is not configured.'**
  String get packageReady;

  /// No description provided for @selectConsent.
  ///
  /// In en, this message translates to:
  /// **'Select at least one consent category.'**
  String get selectConsent;

  /// No description provided for @libraryUpdates.
  ///
  /// In en, this message translates to:
  /// **'Library updates'**
  String get libraryUpdates;

  /// No description provided for @noProductionChannel.
  ///
  /// In en, this message translates to:
  /// **'No production channel configured · last-known-good remains active'**
  String get noProductionChannel;

  /// No description provided for @redactedFields.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sensitive fields redacted} =1{1 sensitive field redacted} other{{count} sensitive fields redacted}}'**
  String redactedFields(int count);

  /// No description provided for @identificationEvidence.
  ///
  /// In en, this message translates to:
  /// **'How we identified this device'**
  String get identificationEvidence;

  /// No description provided for @manualSelectionWarning.
  ///
  /// In en, this message translates to:
  /// **'Manually selected — verify model and firmware before trusting decoded data.'**
  String get manualSelectionWarning;

  /// No description provided for @noIdentificationEvidence.
  ///
  /// In en, this message translates to:
  /// **'No identification evidence is available.'**
  String get noIdentificationEvidence;

  /// No description provided for @protocolStudio.
  ///
  /// In en, this message translates to:
  /// **'Protocol Discovery Studio'**
  String get protocolStudio;

  /// No description provided for @timeMicroseconds.
  ///
  /// In en, this message translates to:
  /// **'TIME µs'**
  String get timeMicroseconds;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'DIRECTION'**
  String get direction;

  /// No description provided for @payload.
  ///
  /// In en, this message translates to:
  /// **'PAYLOAD'**
  String get payload;

  /// No description provided for @confidencePercent.
  ///
  /// In en, this message translates to:
  /// **'{value}% confidence'**
  String confidencePercent(int value);

  /// No description provided for @technicianPublicationDisabled.
  ///
  /// In en, this message translates to:
  /// **'TECHNICIAN PUBLICATION DISABLED'**
  String get technicianPublicationDisabled;

  /// No description provided for @studioDraft.
  ///
  /// In en, this message translates to:
  /// **'STUDIO-DRAFT'**
  String get studioDraft;

  /// No description provided for @studioEngineering.
  ///
  /// In en, this message translates to:
  /// **'STUDIO / ENGINEERING'**
  String get studioEngineering;

  /// No description provided for @replayLock.
  ///
  /// In en, this message translates to:
  /// **'REPLAY LOCK'**
  String get replayLock;

  /// No description provided for @deviceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Device library'**
  String get deviceLibrary;

  /// No description provided for @libraryVerificationNote.
  ///
  /// In en, this message translates to:
  /// **'Verification status is shown per profile. Planned is not supported.'**
  String get libraryVerificationNote;

  /// No description provided for @deterministicBms.
  ///
  /// In en, this message translates to:
  /// **'SolarDiag deterministic BMS'**
  String get deterministicBms;

  /// No description provided for @simulatorOnly.
  ///
  /// In en, this message translates to:
  /// **'LFP-16S-SIM · Simulator only'**
  String get simulatorOnly;

  /// No description provided for @researchTargets.
  ///
  /// In en, this message translates to:
  /// **'Research targets'**
  String get researchTargets;

  /// No description provided for @noVerifiedDefinition.
  ///
  /// In en, this message translates to:
  /// **'No verified definition is bundled'**
  String get noVerifiedDefinition;

  /// No description provided for @research.
  ///
  /// In en, this message translates to:
  /// **'RESEARCH'**
  String get research;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'PLANNED'**
  String get planned;

  /// No description provided for @diagnosticGateway.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic gateway'**
  String get diagnosticGateway;

  /// No description provided for @gatewayDescription.
  ///
  /// In en, this message translates to:
  /// **'Connection checklist and declared capabilities.'**
  String get gatewayDescription;

  /// No description provided for @defaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default mode'**
  String get defaultMode;

  /// No description provided for @listenOnly.
  ///
  /// In en, this message translates to:
  /// **'Listen-only'**
  String get listenOnly;

  /// No description provided for @connectionChecklist.
  ///
  /// In en, this message translates to:
  /// **'Connection checklist'**
  String get connectionChecklist;

  /// No description provided for @isolatedInterfaceCheck.
  ///
  /// In en, this message translates to:
  /// **'Use an isolated interface appropriate for the device.'**
  String get isolatedInterfaceCheck;

  /// No description provided for @pinoutCheck.
  ///
  /// In en, this message translates to:
  /// **'Confirm connector pinout from a verified profile.'**
  String get pinoutCheck;

  /// No description provided for @terminationCheck.
  ///
  /// In en, this message translates to:
  /// **'Confirm termination before enabling the bus.'**
  String get terminationCheck;

  /// No description provided for @transmissionBlockedCheck.
  ///
  /// In en, this message translates to:
  /// **'Transmission remains blocked without an active profile.'**
  String get transmissionBlockedCheck;

  /// No description provided for @parameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parameters;

  /// No description provided for @simulatorValuesNotice.
  ///
  /// In en, this message translates to:
  /// **'Simulator values. Physical writes remain unavailable.'**
  String get simulatorValuesNotice;

  /// No description provided for @simulatedWritePipeline.
  ///
  /// In en, this message translates to:
  /// **'SIMULATED WRITE PIPELINE · Readback required'**
  String get simulatedWritePipeline;

  /// No description provided for @chargeVoltageLimit.
  ///
  /// In en, this message translates to:
  /// **'Charge voltage limit'**
  String get chargeVoltageLimit;

  /// No description provided for @chargeCurrentLimit.
  ///
  /// In en, this message translates to:
  /// **'Charge current limit'**
  String get chargeCurrentLimit;

  /// No description provided for @lowVoltageCutoff.
  ///
  /// In en, this message translates to:
  /// **'Low-voltage cutoff'**
  String get lowVoltageCutoff;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get createBackup;

  /// No description provided for @physicalWriteLocked.
  ///
  /// In en, this message translates to:
  /// **'Physical write locked'**
  String get physicalWriteLocked;

  /// No description provided for @inverterBatteryLink.
  ///
  /// In en, this message translates to:
  /// **'Inverter ↔ Battery'**
  String get inverterBatteryLink;

  /// No description provided for @linkDescription.
  ///
  /// In en, this message translates to:
  /// **'Read-only compatibility and communication evidence.'**
  String get linkDescription;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @deliveryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Message delivery unavailable'**
  String get deliveryUnavailable;

  /// No description provided for @messageDelivery.
  ///
  /// In en, this message translates to:
  /// **'message delivery'**
  String get messageDelivery;

  /// No description provided for @recommendationsNeverApplied.
  ///
  /// In en, this message translates to:
  /// **'Recommendations are never applied automatically.'**
  String get recommendationsNeverApplied;

  /// No description provided for @advancedDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Advanced diagnostics'**
  String get advancedDiagnostics;

  /// No description provided for @evidenceBeforeConclusions.
  ///
  /// In en, this message translates to:
  /// **'Evidence before conclusions.'**
  String get evidenceBeforeConclusions;

  /// No description provided for @diagnosticEvidenceNote.
  ///
  /// In en, this message translates to:
  /// **'Every finding below is tied to a reported value or raw alarm. Missing evidence stays unavailable.'**
  String get diagnosticEvidenceNote;

  /// No description provided for @sohUnavailable.
  ///
  /// In en, this message translates to:
  /// **'State of health: not available'**
  String get sohUnavailable;

  /// No description provided for @sohUnavailableReason.
  ///
  /// In en, this message translates to:
  /// **'The device did not report SOH and available samples cannot prove it.'**
  String get sohUnavailableReason;

  /// No description provided for @cellsBalanced.
  ///
  /// In en, this message translates to:
  /// **'Cells are balanced'**
  String get cellsBalanced;

  /// No description provided for @cellImbalanceDetected.
  ///
  /// In en, this message translates to:
  /// **'Cell imbalance detected'**
  String get cellImbalanceDetected;

  /// No description provided for @temperatureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temperature unavailable'**
  String get temperatureUnavailable;

  /// No description provided for @temperatureNormal.
  ///
  /// In en, this message translates to:
  /// **'Temperature is normal'**
  String get temperatureNormal;

  /// No description provided for @temperatureHigh.
  ///
  /// In en, this message translates to:
  /// **'High temperature'**
  String get temperatureHigh;

  /// No description provided for @cellOvervoltageAlarm.
  ///
  /// In en, this message translates to:
  /// **'Cell overvoltage alarm'**
  String get cellOvervoltageAlarm;

  /// No description provided for @unrecognizedAlarm.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized device alarm'**
  String get unrecognizedAlarm;

  /// No description provided for @rawCodePreserved.
  ///
  /// In en, this message translates to:
  /// **'The raw code is preserved without guessing its meaning.'**
  String get rawCodePreserved;

  /// No description provided for @cellsBalancedDetail.
  ///
  /// In en, this message translates to:
  /// **'The reported cell spread is within the configured attention threshold.'**
  String get cellsBalancedDetail;

  /// No description provided for @cellImbalanceDetail.
  ///
  /// In en, this message translates to:
  /// **'The reported spread exceeds the configured threshold. Inspect raw cell values.'**
  String get cellImbalanceDetail;

  /// No description provided for @temperatureUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'No temperature value was reported; no thermal conclusion was made.'**
  String get temperatureUnavailableDetail;

  /// No description provided for @temperatureNormalDetail.
  ///
  /// In en, this message translates to:
  /// **'The reported temperature is below the configured warning threshold.'**
  String get temperatureNormalDetail;

  /// No description provided for @temperatureHighDetail.
  ///
  /// In en, this message translates to:
  /// **'The reported temperature exceeds a configured safety threshold.'**
  String get temperatureHighDetail;

  /// No description provided for @cellOvervoltageDetail.
  ///
  /// In en, this message translates to:
  /// **'The BMS raw alarm map reports cell overvoltage.'**
  String get cellOvervoltageDetail;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @diagnosticHistory.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic history'**
  String get diagnosticHistory;

  /// No description provided for @historyDescription.
  ///
  /// In en, this message translates to:
  /// **'Locally stored sessions with integrity hashes and captured evidence.'**
  String get historyDescription;

  /// No description provided for @noSavedSessions.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic sessions have been saved yet.'**
  String get noSavedSessions;

  /// No description provided for @scenarioValue.
  ///
  /// In en, this message translates to:
  /// **'Scenario: {value}'**
  String scenarioValue(String value);

  /// No description provided for @lastUpdatedValue.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {value}'**
  String lastUpdatedValue(String value);

  /// No description provided for @integrityHashValue.
  ///
  /// In en, this message translates to:
  /// **'SHA-256: {value}...'**
  String integrityHashValue(String value);

  /// No description provided for @sessionEvidence.
  ///
  /// In en, this message translates to:
  /// **'Session evidence'**
  String get sessionEvidence;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @exportJsonPdf.
  ///
  /// In en, this message translates to:
  /// **'Export JSON + PDF'**
  String get exportJsonPdf;

  /// No description provided for @reportExported.
  ///
  /// In en, this message translates to:
  /// **'Report exported: {pdfPath} · {jsonPath}'**
  String reportExported(String pdfPath, String jsonPath);

  /// No description provided for @reportExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Report export failed integrity or file checks.'**
  String get reportExportFailed;

  /// No description provided for @restoreLatestBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore latest backup'**
  String get restoreLatestBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore configuration backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Restore {count} changed parameters through the verified write and readback pipeline?'**
  String restoreBackupConfirmation(int count);

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm restore'**
  String get confirmRestore;

  /// No description provided for @backupAlreadyMatches.
  ///
  /// In en, this message translates to:
  /// **'The active configuration already matches this backup.'**
  String get backupAlreadyMatches;

  /// No description provided for @backupRestoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restored and verified {count} parameters.'**
  String backupRestoreComplete(int count);

  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore stopped because a write or readback verification failed.'**
  String get backupRestoreFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
