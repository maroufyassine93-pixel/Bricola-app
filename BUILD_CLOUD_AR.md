# بناء APK بريكولا الأصلي من الهاتف (بلا حاسوب) 📱

الفكرة بسيطة: ترفع الكود على GitHub، وخدمة سحابية مجانية تجمّع لك الـAPK، ثم تحمّله على هاتفك.

## الطريقة 1: GitHub Actions (مجانية)

**1. أنشئ حساب GitHub** من متصفح الهاتف: github.com

**2. أنشئ مستودعاً جديداً** باسم `bricola-app` — اجعله **عاماً (Public)** باش الـActions تكون مجانية.

**3. أنشئ رمز الدخول** (كلمة سر للرفع):
- صورتك الشخصية (أعلى) → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Generate new token → امنحه صلاحية `repo` → **انسخ الرمز فوراً** (يظهر مرة واحدة فقط).

**4. ارفع الكود من Termux:**
```bash
pkg install git unzip
cd ~/downloads
unzip bricola-flutter.zip
cd bricola-flutter
git init
git add .
git commit -m "bricola v1"
git branch -M main
git remote add origin https://github.com/USERNAME/bricola-app.git
git push -u origin main
```
استبدل `USERNAME` باسم حسابك. عند الطلب: اسم المستخدم = حسابك، وكلمة السر = **الرمز** الذي نسخته في الخطوة 3.

**5. البناء التلقائي:** افتح المستودع في المتصفح → تبويب **Actions** → سترى البناء يعمل (أول مرة تأخذ 10–20 دقيقة) → ادخل عليه → في الأسفل حمّل **bricola-apk** من Artifacts.

**6.** ثبّت الـAPK على هاتفك. مبروك 🎉

## الطريقة 2: Codemagic (بديل سهل)

1. سجّل في codemagic.io **بحساب GitHub**.
2. Add application → اختر مستودع `bricola-app`.
3. Start new build → انتظر → حمّل الـAPK من Artifacts.

## ملاحظات مهمة

- **وضع تجريبي:** النسخة الحالية تفتح وتتصفح كل الشاشات، لكن مزايا Firebase (الدخول بالهاتف، الحجز الحقيقي، الدردشة) تحتاج إعداد Firebase عبر `flutterfire configure` — خطوة لاحقة نشرحها عند الحاجة.
- **التوقيع:** الـAPK موقّع بمفتاح تجريبي — يكفي للتجربة والعرض على الشركاء. للنشر على Play Store يلزم مفتاح توقيع خاص (نجهزه لاحقاً).
- أي تعديل على الكود + `git push` = بناء APK جديد تلقائياً.
