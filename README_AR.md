# بريكولا — دليل المشروع (Flutter + Firebase)

تطبيق جوال جزائري يربط الزبائن بالحرفيين. الواجهة عربية (RTL) مع المصطلحات
التقنية بالفرنسية بجانب العربية (مثال: كهربائي / Électricien).

## ما تم بناؤه

- **هيكل Flutter كامل** (Material 3، عربي RTL): أكثر من 35 ملف Dart.
- **الشاشات**: البداية، التعريف (3 صفحات)، الدخول برقم الهاتف (OTP)،
  الرئيسية (أزرار مصوّرة كبيرة + شريط المستعجل 🚨 + الأعلى تقييماً)،
  تفاصيل الفئة، قائمة الحرفيين (تصفية: ولاية، موثّق فقط، متاح الآن، بحث)،
  ملف الحرفي (شارة التحقق بثلاث حالات، المهارات، الأسعار الاسترشادية،
  معرض الأعمال، التوفر، التدخل المستعجل، التقييمات)، طلب الحجز (مع
  **ضمان بريكولا** 🛡️)، الدردشة (نص + صور + **رسائل صوتية**)،
  الإشعارات، المكافآت (رمز دعوة + نقاط + إبراز مجاني)، الحساب
  (حجوزاتي + زر "تم الدفع")، والتسجيل كحرفي (4 خطوات).
- **التحقق من الحرفي** (مبسّط حسب طلبك): في الخطوة 3 يرفع الحرفي بطاقة
  الحرفة **إما صورة بالكاميرا أو ملف PDF** — تُحفظ في
  `craftsmen/{uid}/verification/` — ويظهر ملفه بحالة **"قيد المراجعة"**
  حتى يعتمدها المشرف فيمنح شارة "حرفي موثّق ✓".
- **قواعد الأعمال**: عمولة 0% عند الانطلاق (لا توجد حقول عمولة أصلاً)،
  رقم الهاتف **مخفي** حتى قبول الحجز، التقييم **لا يُقبل بدون صورة**
  للعمل المنجز، الدفع نقداً عند الإنجاز مع زر "تم الدفع" داخل التطبيق.
- **Firebase**: قواعد Firestore وStorage جاهزة، ملف الفهارس
  (`firestore.indexes.json`)، وتوثيق كامل لنموذج البيانات
  (`firebase/DATA_MODEL.md`).

## إعداد Firebase (خطوة بخطوة)

1. أنشئ مشروعاً في [Firebase Console](https://console.firebase.google.com).
2. أضف تطبيق Android (اسم الحزمة `com.bricola.app`).
3. فعّل **Authentication ← Phone** (أضف أرقام تجريبية للاختبار).
4. أنشئ قاعدة **Firestore** (وضع production) وارفع `firebase/firestore.rules`
   والفهارس من `firebase/firestore.indexes.json`.
5. فعّل **Storage** وارفع `firebase/storage.rules`.
6. فعّل **Cloud Messaging** للإشعارات الفورية.
7. ثبّت FlutterFire ثم نفّذ:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   سيولّد هذا ملف `lib/firebase_options.dart` الحقيقي (الموجود حالياً
   نسخة مؤقتة فيها TODO).
8. شغّل:
   ```bash
   flutter pub get
   flutter run
   ```

## ملاحظات تقنية

- كل النصوص في ملف واحد: `lib/l10n/strings_ar.dart` (يسهّل الترجمة لاحقاً).
- الخدمات (`lib/services/`) تقرأ من Firestore مباشرة؛ الشاشات تعالج
  حالات التحميل والفراغ والخطأ.
- كشف رقم الهاتف بعد قبول الحجز مصمم كنقطة تكامل مع **Cloud Function**
  (دالة `revealBookingContact`) — لا يكشف العميل الرقم أبداً قبل القبول.
- منح نقاط الدعوة عند أول حجز للمدعو يُفترض أن يتم عبر Cloud Function
  (الدالة `grantInviteReward` جاهزة في `ReferralService`).

## خارطة الطريق

- **الدفع الإلكتروني**: Stripe لا يعمل في الجزائر — التكامل لاحقاً عبر
  **SATIM** (بطاقات CIB وEDAHABIA).
- **Firebase App Check** لحماية القواعد من الاستعمال المسيء.
- **نسخة خفيفة** للهواتف الضعيفة (تقليل حجم الحزمة، صور مضغوطة).
- **قانوني**: الإشعار في التطبيق يشير إلى القانون **18-07** المتعلق
  بحماية المعطيات ذات الطابع الشخصي — يُستكمل بصياغة قانونية نهائية
  قبل الإطلاق.

## البنية

```
lib/
  main.dart                 # التطبيق + التوجيه + حقن الخدمات
  core/                     # theme, wilayas (58 ولاية)
  l10n/strings_ar.dart      # كل نصوص الواجهة
  models/                   # craftsman (+VerificationDoc), category,
                            # review, booking, chat_message,
                            # app_notification, reward
  services/                 # auth, firestore, storage, messaging, referral
  widgets/                  # image_category_button, craftsman_card,
                            # rating_stars, verified_badge (3 حالات),
                            # price_range_chip, section_title
  screens/                  # 15 شاشة + become_craftsman (5 ملفات)
firebase/
  firestore.rules  firestore.indexes.json  storage.rules  DATA_MODEL.md
```
