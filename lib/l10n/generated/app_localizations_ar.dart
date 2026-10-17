// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'SolarDiag Pro';

  @override
  String get designLab => 'مختبر التصميم';

  @override
  String get designLabIntro =>
      'مرجع حي للغة أجهزة القياس والمكونات والرموز والحالات القابلة للوصول.';

  @override
  String get foundations => 'الأسس';

  @override
  String get measurements => 'القياسات';

  @override
  String get cells => 'طرق عرض الخلايا';

  @override
  String get safetyStates => 'حالات السلامة';

  @override
  String get studioComponents => 'مكونات الاستوديو';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get library => 'المكتبة';

  @override
  String get link => 'الرابط';

  @override
  String get gateway => 'البوابة';

  @override
  String get studio => 'الاستوديو';

  @override
  String get contribute => 'ساهم';

  @override
  String get battery => 'البطارية';

  @override
  String get simulatedScenario => 'سيناريو المحاكاة';

  @override
  String get openAdvancedDiagnostics => 'فتح التشخيص المتقدم';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get toggleTheme => 'تبديل المظهر';

  @override
  String get highContrast => 'تباين عالٍ';

  @override
  String get readOnly => 'للقراءة فقط';

  @override
  String get tagline => 'الطاقة، بوضوح كامل.';

  @override
  String get bank => 'حزمة بطارية 48 فولت';

  @override
  String get healthy => 'LiFePO₄، 16 خلية · متصل';

  @override
  String get current => 'التيار';

  @override
  String get temperature => 'درجة الحرارة';

  @override
  String get cellDelta => 'فرق الخلايا';

  @override
  String get notReportedByDevice => 'لم يبلغ عنه الجهاز';

  @override
  String get cellBalance => 'توازن الخلايا';

  @override
  String get rawValues =>
      'القيم الخام المبلّغ عنها من محاكي نظام إدارة البطارية';

  @override
  String get simulatedGateway => 'بوابة المحاكي';

  @override
  String get virtualInterface => 'ناقل افتراضي';

  @override
  String get simulatedBms => 'نظام إدارة بطارية محاكى';

  @override
  String get simulatedProfile => 'LFP-16S-SIM';

  @override
  String get readOnlyMode => 'للقراءة فقط';

  @override
  String get connecting => 'جارٍ الاتصال';

  @override
  String get online => 'متصل';

  @override
  String get linkUnavailable => 'الرابط غير متاح';

  @override
  String get transmissionGuard => 'حارس الإرسال';

  @override
  String get transmissionBlocked => 'الإرسال محظور في وضع القراءة فقط';

  @override
  String get serviceMode => 'وضع الخدمة';

  @override
  String get noParametersReported => 'لم يبلّغ المحول النشط عن أي معاملات.';

  @override
  String get backupCreated =>
      'أُنشئت نسخة احتياطية للإعدادات من القراءة الحالية.';

  @override
  String backupsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نسخة احتياطية محفوظة',
      many: '$count نسخة احتياطية محفوظة',
      few: '$count نسخ احتياطية محفوظة',
      two: 'نسختان احتياطيتان محفوظتان',
      one: 'نسخة احتياطية واحدة محفوظة',
      zero: 'لا توجد نسخ احتياطية محفوظة',
    );
    return '$_temp0';
  }

  @override
  String get editParameter => 'تعديل معامل محاكى';

  @override
  String get reviewChanges => 'مراجعة التغييرات';

  @override
  String get parameterRiskAdvanced => 'المخاطرة: متقدمة · للمحاكي الموثق فقط';

  @override
  String get safetyAcknowledgement => 'راجعت النطاق والأثر والقراءة الحالية.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirmSimulatedWrite => 'تأكيد الكتابة المحاكية';

  @override
  String writeAppliedWithReadback(String value) {
    return 'طُبق التغيير وتحقق بالقراءة الراجعة: $value';
  }

  @override
  String get writeRejected => 'رفض خط الأمان عملية الكتابة.';

  @override
  String get writeFailedVerify =>
      'فشلت الكتابة. يجب التحقق من حالة الجهاز قبل أي تغيير آخر.';

  @override
  String get symbols => 'رموز SolarDiag';

  @override
  String get simulated => 'محاكاة';

  @override
  String get monitor => 'مراقبة';

  @override
  String get connected => 'متصل';

  @override
  String get updatedNow => 'حُدّث الآن';

  @override
  String get packVoltage => 'جهد الحزمة';

  @override
  String get stateOfCharge => 'حالة الشحن';

  @override
  String get warning => 'تحذير';

  @override
  String get registerMapRequired =>
      'يلزم الحصول على خريطة السجلات من الشركة المصنعة.';

  @override
  String get noActiveAlarms => 'لم يُبلّغ عن إنذارات نشطة';

  @override
  String get passiveNoTransmit => 'سلبي — دون إرسال';

  @override
  String get evidence => 'الدليل';

  @override
  String get emptyTitle => 'لم تُحدد جلسة';

  @override
  String get emptyMessage => 'صِل المحاكي أو ملف جهاز موثّق للبدء.';

  @override
  String cellCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خلية',
      many: '$count خلية',
      few: '$count خلايا',
      two: 'خليتان',
      one: 'خلية واحدة',
      zero: 'لا خلايا',
    );
    return '$_temp0';
  }

  @override
  String get continueAction => 'متابعة';

  @override
  String get backAction => 'رجوع';

  @override
  String get contributeSafely => 'المساهمة بأمان';

  @override
  String get contributionPrivacy =>
      'لا تغادر البيانات هذا الجهاز حتى تعاين إزالة المعلومات الحساسة وتمنح موافقة تفصيلية.';

  @override
  String get selectData => 'اختيار البيانات';

  @override
  String get ownedDeviceLog => 'سجل تشخيص جهاز مملوك';

  @override
  String get syntheticExcluded =>
      'تُستبعد اللقطات المحاكية والاصطناعية تلقائيًا.';

  @override
  String get redactionPreview => 'معاينة إزالة المعلومات الحساسة';

  @override
  String get consent => 'الموافقة';

  @override
  String get shareLogs => 'مشاركة سجلات التشخيص المنقحة';

  @override
  String get shareNotes => 'مشاركة ملاحظات المهندس';

  @override
  String get submit => 'إرسال';

  @override
  String get mockPortalOnly => 'بوابة تجريبية فقط';

  @override
  String get packageReady =>
      'الحزمة جاهزة لقائمة الانتظار دون اتصال. الرفع الإنتاجي غير مهيأ.';

  @override
  String get selectConsent => 'اختر فئة موافقة واحدة على الأقل.';

  @override
  String get libraryUpdates => 'تحديثات المكتبة';

  @override
  String get noProductionChannel =>
      'لا توجد قناة إنتاج مهيأة · تظل آخر نسخة سليمة نشطة';

  @override
  String redactedFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُقّح $count حقل حساس',
      many: 'نُقّح $count حقلًا حساسًا',
      few: 'نُقّحت $count حقول حساسة',
      two: 'نُقّح حقلان حساسان',
      one: 'نُقّح حقل حساس واحد',
      zero: 'لم تُنقّح حقول حساسة',
    );
    return '$_temp0';
  }

  @override
  String get identificationEvidence => 'كيف تعرّفنا على هذا الجهاز';

  @override
  String get manualSelectionWarning =>
      'اختيار يدوي — تحقق من الطراز والبرنامج الثابت قبل الوثوق بالبيانات المفكوكة.';

  @override
  String get noIdentificationEvidence => 'لا يتوفر دليل تعرّف.';

  @override
  String get protocolStudio => 'استوديو اكتشاف البروتوكولات';

  @override
  String get timeMicroseconds => 'الوقت µs';

  @override
  String get direction => 'الاتجاه';

  @override
  String get payload => 'الحمولة';

  @override
  String confidencePercent(int value) {
    return 'الثقة $value%';
  }

  @override
  String get technicianPublicationDisabled => 'نشر الفني معطل';

  @override
  String get studioDraft => 'مسودة الاستوديو';

  @override
  String get studioEngineering => 'الاستوديو / هندسة';

  @override
  String get replayLock => 'قفل إعادة الإرسال';

  @override
  String get deviceLibrary => 'مكتبة الأجهزة';

  @override
  String get libraryVerificationNote =>
      'تظهر حالة التحقق لكل ملف. مخطط لا تعني مدعوم.';

  @override
  String get deterministicBms =>
      'محاكي نظام إدارة البطارية الحتمي من SolarDiag';

  @override
  String get simulatorOnly => 'LFP-16S-SIM · محاكاة فقط';

  @override
  String get researchTargets => 'أهداف البحث';

  @override
  String get noVerifiedDefinition => 'لا يوجد تعريف موثّق مضمّن';

  @override
  String get research => 'قيد البحث';

  @override
  String get planned => 'مخطط';

  @override
  String get diagnosticGateway => 'بوابة التشخيص';

  @override
  String get gatewayDescription => 'قائمة فحص الاتصال والقدرات المعلنة.';

  @override
  String get defaultMode => 'الوضع الافتراضي';

  @override
  String get listenOnly => 'استماع فقط';

  @override
  String get connectionChecklist => 'قائمة فحص الاتصال';

  @override
  String get isolatedInterfaceCheck => 'استخدم واجهة معزولة مناسبة للجهاز.';

  @override
  String get pinoutCheck => 'تحقق من أطراف الموصل من ملف موثّق.';

  @override
  String get terminationCheck => 'تحقق من المقاومة الطرفية قبل تمكين الناقل.';

  @override
  String get transmissionBlockedCheck => 'يبقى الإرسال محظورًا دون ملف نشط.';

  @override
  String get parameters => 'المعلمات';

  @override
  String get simulatorValuesNotice =>
      'قيم المحاكي. تظل الكتابة على الأجهزة الحقيقية غير متاحة.';

  @override
  String get simulatedWritePipeline =>
      'خط كتابة محاكى · القراءة الراجعة إلزامية';

  @override
  String get chargeVoltageLimit => 'حد جهد الشحن';

  @override
  String get chargeCurrentLimit => 'حد تيار الشحن';

  @override
  String get lowVoltageCutoff => 'فصل الجهد المنخفض';

  @override
  String get createBackup => 'إنشاء نسخة احتياطية';

  @override
  String get physicalWriteLocked => 'الكتابة الحقيقية مقفلة';

  @override
  String get inverterBatteryLink => 'العاكس ↔ البطارية';

  @override
  String get linkDescription => 'أدلة توافق واتصال للقراءة فقط.';

  @override
  String get live => 'مباشر';

  @override
  String get deliveryUnavailable => 'تسليم الرسائل غير متاح';

  @override
  String get messageDelivery => 'تسليم الرسائل';

  @override
  String get recommendationsNeverApplied => 'لا تُطبّق التوصيات تلقائيًا.';

  @override
  String get advancedDiagnostics => 'التشخيص المتقدم';

  @override
  String get evidenceBeforeConclusions => 'الدليل قبل الاستنتاج.';

  @override
  String get diagnosticEvidenceNote =>
      'كل نتيجة مرتبطة بقيمة مبلّغ عنها أو إنذار خام. عند غياب الدليل تبقى النتيجة غير متاحة.';

  @override
  String get sohUnavailable => 'حالة الصحة: غير متاحة';

  @override
  String get sohUnavailableReason =>
      'لم يبلغ الجهاز عن حالة الصحة ولا تكفي العينات المتاحة لإثباتها.';

  @override
  String get cellsBalanced => 'الخلايا متوازنة';

  @override
  String get cellImbalanceDetected => 'اكتُشف عدم توازن الخلايا';

  @override
  String get temperatureUnavailable => 'درجة الحرارة غير متاحة';

  @override
  String get temperatureNormal => 'درجة الحرارة طبيعية';

  @override
  String get temperatureHigh => 'درجة حرارة مرتفعة';

  @override
  String get cellOvervoltageAlarm => 'إنذار ارتفاع جهد خلية';

  @override
  String get unrecognizedAlarm => 'إنذار جهاز غير معروف';

  @override
  String get rawCodePreserved => 'تم الاحتفاظ بالرمز الخام دون تخمين معناه.';

  @override
  String get cellsBalancedDetail =>
      'فرق الخلايا المبلّغ عنه ضمن حد الانتباه المحدد.';

  @override
  String get cellImbalanceDetail =>
      'الفرق المبلّغ عنه يتجاوز الحد المحدد. راجع قيم الخلايا الخام.';

  @override
  String get temperatureUnavailableDetail =>
      'لم تُبلّغ قيمة لدرجة الحرارة؛ لذلك لم يصدر استنتاج حراري.';

  @override
  String get temperatureNormalDetail =>
      'درجة الحرارة المبلّغ عنها أدنى من حد التحذير المحدد.';

  @override
  String get temperatureHighDetail =>
      'درجة الحرارة المبلّغ عنها تتجاوز حد أمان محدد.';

  @override
  String get cellOvervoltageDetail =>
      'خريطة إنذارات نظام إدارة البطارية الخام تبلغ عن ارتفاع جهد خلية.';

  @override
  String get history => 'السجل';

  @override
  String get diagnosticHistory => 'سجل التشخيص';

  @override
  String get historyDescription =>
      'جلسات محفوظة محليًا مع بصمات سلامة وأدلة ملتقطة.';

  @override
  String get noSavedSessions => 'لم تُحفظ جلسات تشخيص بعد.';

  @override
  String scenarioValue(String value) {
    return 'السيناريو: $value';
  }

  @override
  String lastUpdatedValue(String value) {
    return 'آخر تحديث: $value';
  }

  @override
  String integrityHashValue(String value) {
    return 'SHA-256: $value…';
  }

  @override
  String get sessionEvidence => 'أدلة الجلسة';

  @override
  String get closeAction => 'إغلاق';

  @override
  String get exportJsonPdf => 'تصدير JSON وPDF';

  @override
  String reportExported(String pdfPath, String jsonPath) {
    return 'تم تصدير التقرير: $pdfPath · $jsonPath';
  }

  @override
  String get reportExportFailed =>
      'فشل تصدير التقرير بسبب فحص السلامة أو الملف.';

  @override
  String get restoreLatestBackup => 'استعادة أحدث نسخة احتياطية';

  @override
  String get restoreBackup => 'استعادة نسخة الإعدادات الاحتياطية';

  @override
  String restoreBackupConfirmation(int count) {
    return 'هل تريد استعادة $count من المعلمات المتغيرة عبر خط الكتابة والقراءة الراجعة الموثّق؟';
  }

  @override
  String get confirmRestore => 'تأكيد الاستعادة';

  @override
  String get backupAlreadyMatches =>
      'الإعداد النشط مطابق لهذه النسخة الاحتياطية بالفعل.';

  @override
  String backupRestoreComplete(int count) {
    return 'تمت استعادة $count من المعلمات والتحقق منها.';
  }

  @override
  String get backupRestoreFailed =>
      'توقفت الاستعادة بسبب فشل الكتابة أو التحقق بالقراءة الراجعة.';

  @override
  String get inverter => 'العاكس';

  @override
  String get inverterDiagnostics => 'تشخيص العاكس';

  @override
  String get inverterDiagnosticsDescription =>
      'بيانات محاكي مبلّغ عنها من المحول وحدود صادقة لملف البحث.';

  @override
  String get simulatedInverterProfile => 'عاكس SolarDiag المحاكى';

  @override
  String get simulatedInverterEvidence => 'محاكي Modbus حتمي · دليل محاكى';

  @override
  String get freconResearchProfile => 'FRECON PV100/PV200 · هدف بحثي';

  @override
  String get waitingForInverterTelemetry => 'بانتظار بيانات العاكس.';

  @override
  String get dcVoltage => 'جهد التيار المستمر';

  @override
  String get dcCurrent => 'تيار مستمر';

  @override
  String get dcPower => 'قدرة التيار المستمر';

  @override
  String get acVoltage => 'جهد التيار المتردد';

  @override
  String get acCurrent => 'تيار متردد';

  @override
  String get acPower => 'قدرة التيار المتردد';

  @override
  String get frequency => 'التردد';

  @override
  String get simulatedTelemetryActive => 'بيانات المحاكاة نشطة';

  @override
  String get batteryBmsDiagnostics => 'تشخيص البطارية / نظام إدارتها';

  @override
  String get liveTelemetryActive => 'البيانات المباشرة نشطة';

  @override
  String get telemetryUnavailable => 'البيانات غير متاحة';

  @override
  String get linkEvidenceAvailable => 'أدلة الاتصال متاحة';

  @override
  String get verificationStatusVisible => 'حالة التحقق ظاهرة لكل ملف';

  @override
  String savedSessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جلسة محفوظة',
      many: '$count جلسة محفوظة',
      few: '$count جلسات محفوظة',
      two: 'جلستان محفوظتان',
      one: 'جلسة محفوظة واحدة',
      zero: 'لا توجد جلسات محفوظة',
    );
    return '$_temp0';
  }

  @override
  String get recentSessions => 'الجلسات الأخيرة';

  @override
  String get batteryWorkspaceDescription =>
      'أدلة بطارية مباشرة منظّمة للفحص دون قيم مستنتجة.';

  @override
  String get cellMonitoring => 'مراقبة الخلايا';

  @override
  String get faultDiagnostics => 'تشخيص الأعطال';

  @override
  String get power => 'القدرة';

  @override
  String get stateOfHealth => 'حالة صحة البطارية';

  @override
  String get cycleCount => 'عدد الدورات';

  @override
  String get noCellReadings => 'لم يبلّغ الجهاز عن قراءات للخلايا.';

  @override
  String get minimumCell => 'أدنى خلية';

  @override
  String get maximumCell => 'أعلى خلية';

  @override
  String cellVoltageValue(int index, String value) {
    return 'الخلية $index: $value فولت';
  }

  @override
  String cellNumber(int index) {
    return 'الخلية $index';
  }

  @override
  String rawAlarmCode(String code) {
    return 'رمز الإنذار الخام: $code';
  }

  @override
  String get cellBalancing => 'موازنة الخلايا';

  @override
  String get batteryHealth => 'صحة البطارية';

  @override
  String get serviceFunctions => 'وظائف الخدمة';

  @override
  String get reports => 'التقارير';

  @override
  String get parallelBank => 'البنك المتوازي';

  @override
  String get balancingMask => 'قناع الموازنة';

  @override
  String get balancingUnavailable => 'لم يبلّغ الجهاز عن حالة الموازنة';

  @override
  String get noCellsBalancing => 'لا توجد خلايا مبلّغ عن موازنتها';

  @override
  String get balancingReportedActive => 'يبلّغ الجهاز عن موازنة خلايا نشطة';

  @override
  String get balancingEvidenceNote =>
      'تُفك هذه الحالة فقط من قناع بتات الموازنة المبلّغ عنه.';

  @override
  String get fullChargeCapacity => 'سعة الشحن الكاملة';

  @override
  String get healthMethodNote =>
      'تُعرض حالة الصحة فقط عندما يبلّغ عنها الجهاز. لا يستنتج SolarDiag صحة البطارية من لقطة واحدة.';

  @override
  String get configurationParameters => 'معلمات الإعداد';

  @override
  String get simulatedWriteOnly => 'الكتابة الموثقة متاحة فقط مع ملف المحاكي.';

  @override
  String get calibration => 'المعايرة';

  @override
  String get noVerifiedCalibrationProcedure =>
      'غير متاحة: لا يوجد إجراء معايرة متحقق على جهاز حقيقي ضمن التطبيق.';

  @override
  String get factoryFunctions => 'وظائف المصنع';

  @override
  String get factoryFunctionsUnavailable =>
      'غير متاحة: يلزم تفويض الشركة المصنعة ووثائق متحقق منها.';

  @override
  String get reportsAvailableFromHistory =>
      'أنشئ تقارير JSON وPDF المتحققة من السلامة من سجل التشخيص.';

  @override
  String get parallelModuleTelemetryUnavailable =>
      'لم يبلّغ المحول النشط عن بيانات منفصلة لوحدات البنك المتوازي.';

  @override
  String get onboardingPurpose => 'شخّص أنظمة الطاقة بالأدلة';

  @override
  String get onboardingPurposeDetail =>
      'ينظّم SolarDiag بيانات العاكس والبطارية المبلّغ عنها دون اختلاق القيم غير المتاحة.';

  @override
  String get onboardingReadOnly => 'القراءة فقط أولًا';

  @override
  String get onboardingReadOnlyDetail =>
      'تبدأ الاتصالات بصورة سلبية. يتطلب أي تغيير مدعوم تفويضًا ومراجعة وتأكيدًا وقراءة راجعة.';

  @override
  String get onboardingConnect => 'صِل بوابة معزولة';

  @override
  String get onboardingConnectDetail =>
      'تحقق من الواجهة وأطراف الموصل والمقاومة الطرفية من وثائق موثوقة قبل توصيل العتاد.';

  @override
  String get startDiagnostics => 'بدء التشخيص';
}
