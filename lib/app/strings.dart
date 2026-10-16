import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;
  bool get ar => locale.languageCode == 'ar';
  String pick(String en, String arText) => ar ? arText : en;
  String get tagline => pick('Energy, made legible.', 'الطاقة، بوضوح كامل.');
  String get overview => pick('Overview', 'نظرة عامة');
  String get battery => pick('Battery', 'البطارية');
  String get gateway => pick('Gateway', 'البوابة');
  String get readOnly => pick('READ-ONLY', 'قراءة فقط');
  String get simulated => pick('SIMULATED', 'محاكاة');
  String get bank => pick('48V Battery Bank', 'حزمة بطارية 48 فولت');
  String get healthy =>
      pick('16-cell LiFePO₄ · Healthy link', 'LiFePO₄، 16 خلية · اتصال سليم');
  String get soc => pick('STATE OF CHARGE', 'حالة الشحن');
  String get packVoltage => pick('PACK VOLTAGE', 'جهد الحزمة');
  String get current => pick('Current', 'التيار');
  String get temperature => pick('Temperature', 'درجة الحرارة');
  String get cellDelta => pick('Cell delta', 'فرق الخلايا');
  String get missing => pick('Not reported by device', 'لم يبلغ عنه الجهاز');
  String get cellBalance => pick('Cell balance', 'توازن الخلايا');
  String get rawValues => pick(
    'Raw values reported by the simulated BMS',
    'القيم الخام المبلّغ عنها من محاكي BMS',
  );
  String get designLab => pick('Design Lab', 'مختبر التصميم');
  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));
}
