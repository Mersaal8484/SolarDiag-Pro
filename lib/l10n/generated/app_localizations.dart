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

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeSetting.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSetting;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @digitPreference.
  ///
  /// In en, this message translates to:
  /// **'Digit preference'**
  String get digitPreference;

  /// No description provided for @westernDigits.
  ///
  /// In en, this message translates to:
  /// **'Western (0–9)'**
  String get westernDigits;

  /// No description provided for @arabicIndicDigits.
  ///
  /// In en, this message translates to:
  /// **'Arabic-Indic (٠–٩)'**
  String get arabicIndicDigits;

  /// No description provided for @workshopMode.
  ///
  /// In en, this message translates to:
  /// **'Workshop mode'**
  String get workshopMode;

  /// No description provided for @workshopModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Use controls at least 56 points high and keep the display active during sessions.'**
  String get workshopModeDescription;

  /// No description provided for @outdoorMode.
  ///
  /// In en, this message translates to:
  /// **'Outdoor high contrast'**
  String get outdoorMode;

  /// No description provided for @outdoorModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast and separator strength for bright environments.'**
  String get outdoorModeDescription;

  /// No description provided for @timeAxisDirection.
  ///
  /// In en, this message translates to:
  /// **'Time axis left to right'**
  String get timeAxisDirection;

  /// No description provided for @timeAxisDirectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep technical time charts progressing left to right.'**
  String get timeAxisDirectionDescription;

  /// No description provided for @reduceTransparency.
  ///
  /// In en, this message translates to:
  /// **'Reduce transparency'**
  String get reduceTransparency;

  /// No description provided for @reduceTransparencyDescription.
  ///
  /// In en, this message translates to:
  /// **'Use opaque navigation and overlay surfaces.'**
  String get reduceTransparencyDescription;

  /// No description provided for @voltageUnit.
  ///
  /// In en, this message translates to:
  /// **'V'**
  String get voltageUnit;

  /// No description provided for @pipelineValidate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get pipelineValidate;

  /// No description provided for @pipelineIdentify.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get pipelineIdentify;

  /// No description provided for @pipelineBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get pipelineBackup;

  /// No description provided for @pipelineAuthorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get pipelineAuthorize;

  /// No description provided for @pipelineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm diff'**
  String get pipelineConfirm;

  /// No description provided for @pipelineWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get pipelineWrite;

  /// No description provided for @pipelineReadback.
  ///
  /// In en, this message translates to:
  /// **'Read back'**
  String get pipelineReadback;

  /// No description provided for @pipelineVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get pipelineVerify;

  /// No description provided for @pipelineAudit.
  ///
  /// In en, this message translates to:
  /// **'Append audit'**
  String get pipelineAudit;

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
  /// **'16-cell LiFePO₄ · nominal scenario'**
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

  /// No description provided for @technicianAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Technician Authentication'**
  String get technicianAuthentication;

  /// No description provided for @technicianPin.
  ///
  /// In en, this message translates to:
  /// **'Technician PIN'**
  String get technicianPin;

  /// No description provided for @pinAuthorizationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to authorize write operations'**
  String get pinAuthorizationHint;

  /// No description provided for @authenticateAction.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticateAction;

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

  /// No description provided for @auditKeyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audit key unavailable. Write operations are locked.'**
  String get auditKeyUnavailable;

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

  /// No description provided for @measurementStale.
  ///
  /// In en, this message translates to:
  /// **'Stale measurement'**
  String get measurementStale;

  /// No description provided for @measurementCapturedAt.
  ///
  /// In en, this message translates to:
  /// **'Captured at {timestamp}'**
  String measurementCapturedAt(String timestamp);

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

  /// No description provided for @cycleValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{formattedCount} cycles} =1{{formattedCount} cycle} =2{{formattedCount} cycles} few{{formattedCount} cycles} many{{formattedCount} cycles} other{{formattedCount} cycles}}'**
  String cycleValue(int count, String formattedCount);

  /// No description provided for @frameValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{formattedCount} frames} =1{{formattedCount} frame} =2{{formattedCount} frames} few{{formattedCount} frames} many{{formattedCount} frames} other{{formattedCount} frames}}'**
  String frameValue(int count, String formattedCount);

  /// No description provided for @sampleValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{formattedCount} samples} =1{{formattedCount} sample} =2{{formattedCount} samples} few{{formattedCount} samples} many{{formattedCount} samples} other{{formattedCount} samples}}'**
  String sampleValue(int count, String formattedCount);

  /// No description provided for @sampleCoverage.
  ///
  /// In en, this message translates to:
  /// **'{reportedCount, plural, =0{No reported samples out of {formattedTotal}} =1{{formattedReported} of {formattedTotal} sample} =2{{formattedReported} of {formattedTotal} samples} few{{formattedReported} of {formattedTotal} samples} many{{formattedReported} of {formattedTotal} samples} other{{formattedReported} of {formattedTotal} samples}}'**
  String sampleCoverage(
    int reportedCount,
    String formattedReported,
    String formattedTotal,
  );

  /// No description provided for @unitAmpere.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get unitAmpere;

  /// No description provided for @unitWatt.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get unitWatt;

  /// No description provided for @unitPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get unitPercent;

  /// No description provided for @unitCelsius.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get unitCelsius;

  /// No description provided for @unitMillivolt.
  ///
  /// In en, this message translates to:
  /// **'mV'**
  String get unitMillivolt;

  /// No description provided for @unitMillisecond.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get unitMillisecond;

  /// No description provided for @unitSecond.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get unitSecond;

  /// No description provided for @unitHertz.
  ///
  /// In en, this message translates to:
  /// **'Hz'**
  String get unitHertz;

  /// No description provided for @unitCycle.
  ///
  /// In en, this message translates to:
  /// **'cycle'**
  String get unitCycle;

  /// No description provided for @unitFrame.
  ///
  /// In en, this message translates to:
  /// **'frame'**
  String get unitFrame;

  /// No description provided for @unitSample.
  ///
  /// In en, this message translates to:
  /// **'sample'**
  String get unitSample;

  /// No description provided for @timestampedFrameValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No timestamped frames} =1{{formattedCount} timestamped frame} =2{{formattedCount} timestamped frames} few{{formattedCount} timestamped frames} many{{formattedCount} timestamped frames} other{{formattedCount} timestamped frames}}'**
  String timestampedFrameValue(int count, String formattedCount);

  /// No description provided for @framesLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No frames loaded} =1{{formattedCount} frame loaded successfully} =2{{formattedCount} frames loaded successfully} few{{formattedCount} frames loaded successfully} many{{formattedCount} frames loaded successfully} other{{formattedCount} frames loaded successfully}}'**
  String framesLoaded(int count, String formattedCount);

  /// No description provided for @frameReferences.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No frame references} =1{{formattedCount} frame reference} =2{{formattedCount} frame references} few{{formattedCount} frame references} many{{formattedCount} frame references} other{{formattedCount} frame references}}'**
  String frameReferences(int count, String formattedCount);

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

  /// No description provided for @studioPersistenceError.
  ///
  /// In en, this message translates to:
  /// **'Studio persistence is unavailable or failed. Imported research may not be saved.'**
  String get studioPersistenceError;

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

  /// No description provided for @productionTrustAnchorMissing.
  ///
  /// In en, this message translates to:
  /// **'No valid production trust anchor is configured. Signed library updates and physical writes remain blocked.'**
  String get productionTrustAnchorMissing;

  /// No description provided for @libraryWriteBlockedMissing.
  ///
  /// In en, this message translates to:
  /// **'No verified device library is installed. Physical library writes remain blocked.'**
  String get libraryWriteBlockedMissing;

  /// No description provided for @libraryWriteBlockedRevoked.
  ///
  /// In en, this message translates to:
  /// **'The active library pack or profile is revoked. Physical library writes remain blocked.'**
  String get libraryWriteBlockedRevoked;

  /// No description provided for @libraryWriteBlockedStale.
  ///
  /// In en, this message translates to:
  /// **'The revocation data is stale. Refresh it before physical writes can be enabled.'**
  String get libraryWriteBlockedStale;

  /// No description provided for @libraryWriteBlockedExpired.
  ///
  /// In en, this message translates to:
  /// **'The revocation list has expired. Refresh it before physical writes can be enabled.'**
  String get libraryWriteBlockedExpired;

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
  /// **'Low voltage cutoff'**
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

  /// No description provided for @cellVoltagesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cell voltages unavailable'**
  String get cellVoltagesUnavailable;

  /// No description provided for @cellVoltagesUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'No usable cell voltages were reported; cell balance cannot be assessed.'**
  String get cellVoltagesUnavailableDetail;

  /// No description provided for @cellCountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Cell count does not match profile'**
  String get cellCountMismatch;

  /// No description provided for @cellCountMismatchDetail.
  ///
  /// In en, this message translates to:
  /// **'The number of reported cell voltages differs from the active profile topology.'**
  String get cellCountMismatchDetail;

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

  /// No description provided for @inverter.
  ///
  /// In en, this message translates to:
  /// **'Inverter'**
  String get inverter;

  /// No description provided for @inverterDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Inverter diagnostics'**
  String get inverterDiagnostics;

  /// No description provided for @inverterDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Adapter-reported simulator telemetry and honest research-profile limitations.'**
  String get inverterDiagnosticsDescription;

  /// No description provided for @simulatedInverterProfile.
  ///
  /// In en, this message translates to:
  /// **'SolarDiag simulated inverter'**
  String get simulatedInverterProfile;

  /// No description provided for @simulatedInverterEvidence.
  ///
  /// In en, this message translates to:
  /// **'Deterministic Modbus simulator · simulated evidence'**
  String get simulatedInverterEvidence;

  /// No description provided for @freconResearchProfile.
  ///
  /// In en, this message translates to:
  /// **'FRECON PV100/PV200 · research target'**
  String get freconResearchProfile;

  /// No description provided for @waitingForInverterTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Waiting for inverter telemetry.'**
  String get waitingForInverterTelemetry;

  /// No description provided for @dcVoltage.
  ///
  /// In en, this message translates to:
  /// **'DC voltage'**
  String get dcVoltage;

  /// No description provided for @dcCurrent.
  ///
  /// In en, this message translates to:
  /// **'DC current'**
  String get dcCurrent;

  /// No description provided for @dcPower.
  ///
  /// In en, this message translates to:
  /// **'DC power'**
  String get dcPower;

  /// No description provided for @acVoltage.
  ///
  /// In en, this message translates to:
  /// **'AC voltage'**
  String get acVoltage;

  /// No description provided for @acCurrent.
  ///
  /// In en, this message translates to:
  /// **'AC current'**
  String get acCurrent;

  /// No description provided for @acPower.
  ///
  /// In en, this message translates to:
  /// **'AC power'**
  String get acPower;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @simulatedTelemetryActive.
  ///
  /// In en, this message translates to:
  /// **'Simulated telemetry active'**
  String get simulatedTelemetryActive;

  /// No description provided for @batteryBmsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Battery / BMS diagnostics'**
  String get batteryBmsDiagnostics;

  /// No description provided for @liveTelemetryActive.
  ///
  /// In en, this message translates to:
  /// **'Live telemetry active'**
  String get liveTelemetryActive;

  /// No description provided for @telemetryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Telemetry unavailable'**
  String get telemetryUnavailable;

  /// No description provided for @linkEvidenceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Communication evidence available'**
  String get linkEvidenceAvailable;

  /// No description provided for @verificationStatusVisible.
  ///
  /// In en, this message translates to:
  /// **'Verification status shown per profile'**
  String get verificationStatusVisible;

  /// No description provided for @savedSessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No saved sessions} =1{1 saved session} other{{count} saved sessions}}'**
  String savedSessionCount(int count);

  /// No description provided for @recentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get recentSessions;

  /// No description provided for @batteryWorkspaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Live battery evidence organized for inspection without inferred values.'**
  String get batteryWorkspaceDescription;

  /// No description provided for @cellMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Cell monitoring'**
  String get cellMonitoring;

  /// No description provided for @faultDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Fault diagnostics'**
  String get faultDiagnostics;

  /// No description provided for @power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// No description provided for @stateOfHealth.
  ///
  /// In en, this message translates to:
  /// **'State of health'**
  String get stateOfHealth;

  /// No description provided for @cycleCount.
  ///
  /// In en, this message translates to:
  /// **'Cycle count'**
  String get cycleCount;

  /// No description provided for @noCellReadings.
  ///
  /// In en, this message translates to:
  /// **'No cell readings were reported by the device.'**
  String get noCellReadings;

  /// No description provided for @minimumCell.
  ///
  /// In en, this message translates to:
  /// **'Minimum cell'**
  String get minimumCell;

  /// No description provided for @maximumCell.
  ///
  /// In en, this message translates to:
  /// **'Maximum cell'**
  String get maximumCell;

  /// No description provided for @cellVoltageValue.
  ///
  /// In en, this message translates to:
  /// **'Cell {index}: {value} V'**
  String cellVoltageValue(int index, String value);

  /// No description provided for @cellNumber.
  ///
  /// In en, this message translates to:
  /// **'Cell {index}'**
  String cellNumber(int index);

  /// No description provided for @rawAlarmCode.
  ///
  /// In en, this message translates to:
  /// **'Raw alarm code: {code}'**
  String rawAlarmCode(String code);

  /// No description provided for @cellBalancing.
  ///
  /// In en, this message translates to:
  /// **'Cell balancing'**
  String get cellBalancing;

  /// No description provided for @batteryHealth.
  ///
  /// In en, this message translates to:
  /// **'Battery health'**
  String get batteryHealth;

  /// No description provided for @serviceFunctions.
  ///
  /// In en, this message translates to:
  /// **'Service functions'**
  String get serviceFunctions;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @parallelBank.
  ///
  /// In en, this message translates to:
  /// **'Parallel bank'**
  String get parallelBank;

  /// No description provided for @balancingMask.
  ///
  /// In en, this message translates to:
  /// **'Balancing mask'**
  String get balancingMask;

  /// No description provided for @balancingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Balancing state was not reported'**
  String get balancingUnavailable;

  /// No description provided for @noCellsBalancing.
  ///
  /// In en, this message translates to:
  /// **'No cells are reported as balancing'**
  String get noCellsBalancing;

  /// No description provided for @balancingReportedActive.
  ///
  /// In en, this message translates to:
  /// **'The device reports active cell balancing'**
  String get balancingReportedActive;

  /// No description provided for @balancingEvidenceNote.
  ///
  /// In en, this message translates to:
  /// **'This status is decoded only from the reported balancing bitmask.'**
  String get balancingEvidenceNote;

  /// No description provided for @fullChargeCapacity.
  ///
  /// In en, this message translates to:
  /// **'Full-charge capacity'**
  String get fullChargeCapacity;

  /// No description provided for @healthMethodNote.
  ///
  /// In en, this message translates to:
  /// **'SOH is shown only when device-reported. SolarDiag does not infer battery health from a single snapshot.'**
  String get healthMethodNote;

  /// No description provided for @configurationParameters.
  ///
  /// In en, this message translates to:
  /// **'Configuration parameters'**
  String get configurationParameters;

  /// No description provided for @simulatedWriteOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified writes are available only against the simulator profile.'**
  String get simulatedWriteOnly;

  /// No description provided for @calibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration'**
  String get calibration;

  /// No description provided for @noVerifiedCalibrationProcedure.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: no hardware-verified calibration procedure is bundled.'**
  String get noVerifiedCalibrationProcedure;

  /// No description provided for @factoryFunctions.
  ///
  /// In en, this message translates to:
  /// **'Factory functions'**
  String get factoryFunctions;

  /// No description provided for @factoryFunctionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: manufacturer authorization and verified documentation are required.'**
  String get factoryFunctionsUnavailable;

  /// No description provided for @reportsAvailableFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Generate integrity-checked JSON and PDF reports from Diagnostic history.'**
  String get reportsAvailableFromHistory;

  /// No description provided for @parallelModuleTelemetryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Per-module parallel-bank telemetry was not reported by the active adapter.'**
  String get parallelModuleTelemetryUnavailable;

  /// No description provided for @onboardingPurpose.
  ///
  /// In en, this message translates to:
  /// **'Diagnose energy systems with evidence'**
  String get onboardingPurpose;

  /// No description provided for @onboardingPurposeDetail.
  ///
  /// In en, this message translates to:
  /// **'SolarDiag organizes reported inverter and battery data without inventing unavailable values.'**
  String get onboardingPurposeDetail;

  /// No description provided for @onboardingReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only comes first'**
  String get onboardingReadOnly;

  /// No description provided for @onboardingReadOnlyDetail.
  ///
  /// In en, this message translates to:
  /// **'Connections start passive. Any supported change requires authorization, review, confirmation and readback.'**
  String get onboardingReadOnlyDetail;

  /// No description provided for @onboardingConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect an isolated gateway'**
  String get onboardingConnect;

  /// No description provided for @onboardingConnectDetail.
  ///
  /// In en, this message translates to:
  /// **'Verify the interface, connector pinout and termination from trusted documentation before connecting hardware.'**
  String get onboardingConnectDetail;

  /// No description provided for @startDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Start diagnostics'**
  String get startDiagnostics;

  /// No description provided for @compareLatestBackup.
  ///
  /// In en, this message translates to:
  /// **'Compare latest backup'**
  String get compareLatestBackup;

  /// No description provided for @backupComparison.
  ///
  /// In en, this message translates to:
  /// **'Backup comparison'**
  String get backupComparison;

  /// No description provided for @backupComparisonValues.
  ///
  /// In en, this message translates to:
  /// **'Backup: {backup} · Current: {current}'**
  String backupComparisonValues(String backup, String current);

  /// No description provided for @changed.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get changed;

  /// No description provided for @unchanged.
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get unchanged;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @sessionTimeline.
  ///
  /// In en, this message translates to:
  /// **'Session timeline'**
  String get sessionTimeline;

  /// No description provided for @noTimelineEvents.
  ///
  /// In en, this message translates to:
  /// **'No timeline events were recorded.'**
  String get noTimelineEvents;

  /// No description provided for @rawSessionEvidence.
  ///
  /// In en, this message translates to:
  /// **'Raw session evidence'**
  String get rawSessionEvidence;

  /// No description provided for @sessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Session started'**
  String get sessionStarted;

  /// No description provided for @linkStateChanged.
  ///
  /// In en, this message translates to:
  /// **'Link state changed'**
  String get linkStateChanged;

  /// No description provided for @alarmsChanged.
  ///
  /// In en, this message translates to:
  /// **'Alarm state changed'**
  String get alarmsChanged;

  /// No description provided for @sessionEvent.
  ///
  /// In en, this message translates to:
  /// **'Session event'**
  String get sessionEvent;

  /// No description provided for @previewReport.
  ///
  /// In en, this message translates to:
  /// **'Preview report'**
  String get previewReport;

  /// No description provided for @reportPreview.
  ///
  /// In en, this message translates to:
  /// **'Engineering report preview'**
  String get reportPreview;

  /// No description provided for @reportContentsDescription.
  ///
  /// In en, this message translates to:
  /// **'The export includes identification, firmware, profile status, timestamps, readings, alarms, parameters, findings and the verified session hash.'**
  String get reportContentsDescription;

  /// No description provided for @reportLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose export language'**
  String get reportLanguage;

  /// No description provided for @bilingual.
  ///
  /// In en, this message translates to:
  /// **'Bilingual'**
  String get bilingual;

  /// No description provided for @compatibilityCannotDetermine.
  ///
  /// In en, this message translates to:
  /// **'Cannot determine'**
  String get compatibilityCannotDetermine;

  /// No description provided for @requiredEvidenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Required evidence is unavailable; compatibility cannot be claimed.'**
  String get requiredEvidenceUnavailable;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @chargeVoltage.
  ///
  /// In en, this message translates to:
  /// **'Charge voltage'**
  String get chargeVoltage;

  /// No description provided for @chargeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Charge current'**
  String get chargeCurrent;

  /// No description provided for @dischargeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Discharge current'**
  String get dischargeCurrent;

  /// No description provided for @chemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get chemistry;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// No description provided for @requiredVoltageEvidenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Required voltage evidence is unavailable.'**
  String get requiredVoltageEvidenceUnavailable;

  /// No description provided for @requiredCurrentEvidenceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Required current evidence is unavailable.'**
  String get requiredCurrentEvidenceUnavailable;

  /// No description provided for @chemistryCompatibilityUnproven.
  ///
  /// In en, this message translates to:
  /// **'Chemistry compatibility cannot be proven.'**
  String get chemistryCompatibilityUnproven;

  /// No description provided for @protocolIntersectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No verified protocol intersection can be evaluated.'**
  String get protocolIntersectionUnavailable;

  /// No description provided for @researchSession.
  ///
  /// In en, this message translates to:
  /// **'Research session'**
  String get researchSession;

  /// No description provided for @syntheticCanStudy.
  ///
  /// In en, this message translates to:
  /// **'Synthetic CAN study'**
  String get syntheticCanStudy;

  /// No description provided for @isolatedSessionNoHardware.
  ///
  /// In en, this message translates to:
  /// **'One isolated session · no hardware attached'**
  String get isolatedSessionNoHardware;

  /// No description provided for @frames.
  ///
  /// In en, this message translates to:
  /// **'Frames'**
  String get frames;

  /// No description provided for @identifiers.
  ///
  /// In en, this message translates to:
  /// **'Identifiers'**
  String get identifiers;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @synthetic.
  ///
  /// In en, this message translates to:
  /// **'Synthetic'**
  String get synthetic;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @capture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get capture;

  /// No description provided for @frameExplorer.
  ///
  /// In en, this message translates to:
  /// **'Frame explorer'**
  String get frameExplorer;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @differential.
  ///
  /// In en, this message translates to:
  /// **'Differential'**
  String get differential;

  /// No description provided for @hypotheses.
  ///
  /// In en, this message translates to:
  /// **'Hypotheses'**
  String get hypotheses;

  /// No description provided for @profileBuilder.
  ///
  /// In en, this message translates to:
  /// **'Profile builder'**
  String get profileBuilder;

  /// No description provided for @mappingEditor.
  ///
  /// In en, this message translates to:
  /// **'Mapping editor'**
  String get mappingEditor;

  /// No description provided for @validation.
  ///
  /// In en, this message translates to:
  /// **'Validation'**
  String get validation;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @operatingMode.
  ///
  /// In en, this message translates to:
  /// **'Operating mode'**
  String get operatingMode;

  /// No description provided for @activeRead.
  ///
  /// In en, this message translates to:
  /// **'Active read'**
  String get activeRead;

  /// No description provided for @writeMode.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get writeMode;

  /// No description provided for @noTransmissionAttempted.
  ///
  /// In en, this message translates to:
  /// **'No transmission attempted'**
  String get noTransmissionAttempted;

  /// No description provided for @guardAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get guardAllowed;

  /// No description provided for @guardBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get guardBlocked;

  /// No description provided for @allowedFrames.
  ///
  /// In en, this message translates to:
  /// **'Allowed frames'**
  String get allowedFrames;

  /// No description provided for @blockedFrames.
  ///
  /// In en, this message translates to:
  /// **'Blocked frames'**
  String get blockedFrames;

  /// No description provided for @droppedFrames.
  ///
  /// In en, this message translates to:
  /// **'Dropped frames'**
  String get droppedFrames;

  /// No description provided for @observedBusLoad.
  ///
  /// In en, this message translates to:
  /// **'Observed bus load'**
  String get observedBusLoad;

  /// No description provided for @negotiationState.
  ///
  /// In en, this message translates to:
  /// **'Negotiation state'**
  String get negotiationState;

  /// No description provided for @notNegotiated.
  ///
  /// In en, this message translates to:
  /// **'Not negotiated'**
  String get notNegotiated;

  /// No description provided for @passiveNegotiated.
  ///
  /// In en, this message translates to:
  /// **'Passive session accepted'**
  String get passiveNegotiated;

  /// No description provided for @activeReadNegotiated.
  ///
  /// In en, this message translates to:
  /// **'Active-read session accepted'**
  String get activeReadNegotiated;

  /// No description provided for @writeNegotiated.
  ///
  /// In en, this message translates to:
  /// **'Write session accepted'**
  String get writeNegotiated;

  /// No description provided for @lastGuardDecision.
  ///
  /// In en, this message translates to:
  /// **'Last guard decision'**
  String get lastGuardDecision;

  /// No description provided for @compatibilityCompatible.
  ///
  /// In en, this message translates to:
  /// **'Compatible'**
  String get compatibilityCompatible;

  /// No description provided for @compatibilityCompatibleWithLimits.
  ///
  /// In en, this message translates to:
  /// **'Compatible with limits'**
  String get compatibilityCompatibleWithLimits;

  /// No description provided for @compatibilityIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Incompatible profile'**
  String get compatibilityIncompatible;

  /// No description provided for @compatibilityStateCompatible.
  ///
  /// In en, this message translates to:
  /// **'Compatible'**
  String get compatibilityStateCompatible;

  /// No description provided for @compatibilityStateAttention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get compatibilityStateAttention;

  /// No description provided for @compatibilityStateIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Incompatible'**
  String get compatibilityStateIncompatible;
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
