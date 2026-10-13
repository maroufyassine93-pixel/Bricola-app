/// Algerian wilayas (code → name). Used by filters, registration, booking.
class Wilaya {
  final int code;
  final String name;
  const Wilaya(this.code, this.name);
}

const List<Wilaya> wilayas = [
  Wilaya(1, 'أدرار'),
  Wilaya(2, 'الشلف'),
  Wilaya(3, 'الأغواط'),
  Wilaya(4, 'أم البواقي'),
  Wilaya(5, 'باتنة'),
  Wilaya(6, 'بجاية'),
  Wilaya(7, 'بسكرة'),
  Wilaya(8, 'بشار'),
  Wilaya(9, 'البليدة'),
  Wilaya(10, 'البويرة'),
  Wilaya(11, 'تمنراست'),
  Wilaya(12, 'تبسة'),
  Wilaya(13, 'تلمسان'),
  Wilaya(14, 'تيارت'),
  Wilaya(15, 'تيزي وزو'),
  Wilaya(16, 'الجزائر'),
  Wilaya(17, 'الجلفة'),
  Wilaya(18, 'جيجل'),
  Wilaya(19, 'سطيف'),
  Wilaya(20, 'سعيدة'),
  Wilaya(21, 'سكيكدة'),
  Wilaya(22, 'سيدي بلعباس'),
  Wilaya(23, 'عنابة'),
  Wilaya(24, 'قالمة'),
  Wilaya(25, 'قسنطينة'),
  Wilaya(26, 'المدية'),
  Wilaya(27, 'مستغانم'),
  Wilaya(28, 'المسيلة'),
  Wilaya(29, 'معسكر'),
  Wilaya(30, 'ورقلة'),
  Wilaya(31, 'وهران'),
  Wilaya(32, 'البيض'),
  Wilaya(33, 'إليزي'),
  Wilaya(34, 'برج بوعريريج'),
  Wilaya(35, 'بومرداس'),
  Wilaya(36, 'الطارف'),
  Wilaya(37, 'تندوف'),
  Wilaya(38, 'تيسمسيلت'),
  Wilaya(39, 'الوادي'),
  Wilaya(40, 'خنشلة'),
  Wilaya(41, 'سوق أهراس'),
  Wilaya(42, 'تيبازة'),
  Wilaya(43, 'ميلة'),
  Wilaya(44, 'عين الدفلى'),
  Wilaya(45, 'النعامة'),
  Wilaya(46, 'عين تموشنت'),
  Wilaya(47, 'غرداية'),
  Wilaya(48, 'غليزان'),
  Wilaya(49, 'تيميمون'),
  Wilaya(50, 'برج باجي مختار'),
  Wilaya(51, 'أولاد جلال'),
  Wilaya(52, 'بني عباس'),
  Wilaya(53, 'عين صالح'),
  Wilaya(54, 'عين قزام'),
  Wilaya(55, 'تقرت'),
  Wilaya(56, 'جانت'),
  Wilaya(57, 'المغير'),
  Wilaya(58, 'المنيعة'),
];

String wilayaName(int code) {
  for (final w in wilayas) {
    if (w.code == code) return w.name;
  }
  return 'ولاية $code';
}
