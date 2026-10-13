# ربط Firebase الحقيقي — دليل الهاتف 📱

> لا تحتاج حاسوباً. كل شيء من متصفح الهاتف + Termux.

## الخطوة 1: إنشاء المشروع (5 دقائق)

1. افتح [console.firebase.google.com](https://console.firebase.google.com) وسجّل بحساب Google.
2. **Add project** ← اسم المشروع: `bricola` ← **Continue**.
3. Google Analytics: **عطّله** (Not needed now) ← **Create project**.

## الخطوة 2: إضافة تطبيق Android

1. داخل المشروع: اضغط أيقونة **Android** (Add an app).
2. **Android package name:** `com.bricola.app` (مهم: بالضبط كما هو)
3. **App nickname:** `Bricola`
4. **Download google-services.json** ← احفظه في هاتفك (مجلد Downloads).
5. تخطَّ الخطوات التالية (Next / Continue) — الإعداد عندنا جاهز.

## الخطوة 3: نسخ القيم (دقيقة)

1. ⚙️ **Project settings** (أيقونة الترس بجانب Project Overview).
2. من قسم **General** انسخ:
   - **Web API Key**
   - **Project ID**
   - **Project number** (هو messagingSenderId)
3. من قسم **Your apps** ← تطبيق Android ← انسخ **App ID** (يبدأ بـ `1:`).

## الخطوة 4: تفعيل تسجيل الدخول بالهاتف

1. القائمة اليسرى: **Build ← Authentication ← Get started**.
2. تبويب **Sign-in method** ← فعّل **Phone** ← **Save**.

## الخطوة 5: إنشاء قاعدة البيانات

1. القائمة: **Build ← Firestore Database ← Create database**.
2. اختر **Start in production mode** ← الموقع: الأقرب (`europe-west`).
3. تبويب **Rules**: احذف الموجود والصق محتوى ملف `firebase/firestore.rules` من المستودع ← **Publish**.

## الخطوة 6: أرسل لي الملف

أرسل في المحادثة ملف **`google-services.json`** الذي حمّلته في الخطوة 2 (كمرفق).
سأجهز لك الحزمة النهائية: الملف في مكانه + القيم الحقيقية — ثم ترفع وتبني فقط.

## الخطوة 7 (لاحقاً): التخزين والصور

عندما نفعّل رفع الصور: **Upgrade** المشروع لخطة **Blaze** وأضف بطاقة RedotPay.
الاستهلاك يبقى **0$** ضمن 5GB المجانية — وسنضبط تنبيه ميزانية للأمان.
