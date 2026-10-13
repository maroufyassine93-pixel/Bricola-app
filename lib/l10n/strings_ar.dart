/// Centralized UI strings — Modern Standard Arabic, RTL.
/// French technical terms are kept alongside Arabic labels where relevant.
class S {
  S._();

  // ── App ──────────────────────────────────────────────────────────────
  static const String appName = 'بريكولا';
  static const String appTagline = 'حرفيّك الموثوق… بضغطة زر';
  static const String appDescription =
      'بريكولا يربطك بأمهر الحرفيين في ولايتك: بناء، صيانة، تصليح أجهزة، وخدمات تكنولوجية.';

  // ── Onboarding ───────────────────────────────────────────────────────
  static const String ob1Title = 'اعثر على حرفي موثوق';
  static const String ob1Body =
      'كهربائي، بلومبي، نجّار… قيّم الحرفيين حسب التقييمات الحقيقية وصور أعمالهم.';
  static const String ob2Title = 'احجز في دقائق';
  static const String ob2Body =
      'صف مشكلتك بالصور أو برسالة صوتية، وسيصلك ردّ الحرفي مباشرة داخل التطبيق.';
  static const String ob3Title = 'ضمان بريكولا';
  static const String ob3Body =
      'إذا تخلّف الحرفي عن الموعد، نبحث لك عن بديل فوراً. الدفع نقداً عند الإنجاز.';
  static const String next = 'التالي';
  static const String start = 'ابدأ الآن';
  static const String skip = 'تخطّي';

  // ── Auth ─────────────────────────────────────────────────────────────
  static const String loginTitle = 'تسجيل الدخول';
  static const String loginSubtitle =
      'أدخل رقم هاتفك وسنرسل لك رمز تحقق برسالة نصية';
  static const String phoneNumber = 'رقم الهاتف';
  static const String phoneHint = '0550 12 34 56';
  static const String sendCode = 'أرسل رمز التحقق';
  static const String codeTitle = 'أدخل رمز التحقق';
  static const String codeSubtitle = 'أرسلنا رمزاً من 6 أرقام إلى';
  static const String verify = 'تحقّق';
  static const String resendCode = 'إعادة إرسال الرمز';
  static const String invalidPhone = 'يرجى إدخال رقم هاتف جزائري صحيح';
  static const String invalidCode = 'الرمز غير صحيح، حاول مجدداً';
  static const String logout = 'تسجيل الخروج';

  // ── Home ─────────────────────────────────────────────────────────────
  static const String homeGreeting = 'واش خصّك اليوم؟';
  static const String searchHint = 'ابحث عن حرفي أو خدمة…';
  static const String catConstruction = 'أعمال البناء والصيانة';
  static const String catAppliances = 'إصلاح الأجهزة المنزلية';
  static const String catTech = 'الخدمات التكنولوجية';
  static const String topRated = 'الأعلى تقييماً قربك';
  static const String availableNow = 'متاح الآن';
  static const String seeAll = 'عرض الكل';
  static const String urgentBanner = '🚨 تحتاج تدخلاً مستعجلاً؟';
  static const String urgentBannerSub = 'سباكة • كهرباء • أقفال — استجابة سريعة';

  // ── Filters ──────────────────────────────────────────────────────────
  static const String filters = 'تصفية النتائج';
  static const String wilaya = 'الولاية';
  static const String commune = 'البلدية';
  static const String verifiedOnly = 'الحرفيون الموثّقون فقط';
  static const String availableNowOnly = 'المتاحون الآن فقط';
  static const String sortBy = 'ترتيب حسب';
  static const String sortRating = 'الأعلى تقييماً';
  static const String sortNearest = 'الأقرب';
  static const String apply = 'طبّق';
  static const String reset = 'إعادة ضبط';

  // ── Craftsman ────────────────────────────────────────────────────────
  static const String verifiedCraftsman = 'حرفي موثّق';
  static const String verifiedTooltip =
      'تحقّقنا من هويته وبطاقة الحرفي لدى غرفة الحرفة';
  static const String phoneVerified = 'هاتف مؤكد';
  static const String phoneMaskedNotice =
      'سيظهر رقم الهاتف بعد تأكيد الحجز حفاظاً على خصوصية الطرفين';
  static const String skills = 'المهارات';
  static const String portfolio = 'أعمال منجزة';
  static const String reviews = 'التقييمات';
  static const String noReviewsYet = 'لا توجد تقييمات بعد — كن أول من يقيّم';
  static const String indicativePrices = 'أسعار استرشادية';
  static const String dzd = 'دج';
  static const String bookNow = 'احجز الآن';
  static const String chatNow = 'دردشة';
  static const String call = 'اتصال';
  static const String location = 'الموقع';
  static const String urgentToggle = 'تدخل مستعجل 🚨';
  static const String urgentSurchargeNote =
      'التدخل المستعجل يشمل زيادة 30% على السعر الاسترشادي';
  static const String workingHours = 'أيام العمل';
  static const String memberSince = 'عضو منذ';

  // ── Booking ──────────────────────────────────────────────────────────
  static const String bookingTitle = 'طلب حجز';
  static const String service = 'الخدمة المطلوبة';
  static const String problemDescription = 'صف المشكلة';
  static const String problemHint =
      'مثال: المكيف يسرّب الماء ولا يبرّد منذ يومين…';
  static const String addPhotos = 'أضف صوراً (اختياري)';
  static const String preferredTime = 'الوقت المفضّل';
  static const String today = 'اليوم';
  static const String tomorrow = 'غداً';
  static const String urgentRequest = 'طلب مستعجل 🚨 (+30%)';
  static const String sendRequest = 'أرسل الطلب';
  static const String bookingSent = 'تم إرسال طلبك بنجاح';
  static const String guaranteeTitle = 'ضمان بريكولا 🛡️';
  static const String guaranteeBody =
      'إذا تخلّف الحرفي عن الموعد المتفق عليه، نبحث لك عن حرفي بديل في أقرب وقت ممكن دون أي تكلفة إضافية.';
  static const String myBookings = 'حجوزاتي';
  static const String bookingPending = 'بانتظار ردّ الحرفي';
  static const String bookingAccepted = 'مقبول — في الطريق إليك';
  static const String bookingCompleted = 'مكتمل';
  static const String bookingCancelled = 'ملغي';
  static const String confirmPayment = 'تم الدفع ✓';
  static const String paymentConfirmedMsg =
      'شكراً! تم تسجيل الدفع نقداً عند الإنجاز.';
  static const String rateService = 'قيّم الخدمة';
  static const String reviewWithPhotoRequired =
      'لضمان مصداقية التقييمات، يجب إرفاق صورة للعمل المنجز';
  static const String yourRating = 'تقييمك';
  static const String yourComment = 'تعليقك (اختياري)';
  static const String submitReview = 'انشر التقييم';
  static const String attachWorkPhoto = '📷 أرفق صورة العمل المنجز (إلزامية)';

  // ── Chat ─────────────────────────────────────────────────────────────
  static const String chats = 'المحادثات';
  static const String typeMessage = 'اكتب رسالتك…';
  static const String holdToRecord = 'اضغط مطوّلاً للتسجيل الصوتي 🎙️';
  static const String voiceMessage = 'رسالة صوتية';
  static const String noChats = 'لا توجد محادثات بعد';
  static const String noChatsSub =
      'عند حجز حرفي ستظهر محادثتك معه هنا';

  // ── Notifications ────────────────────────────────────────────────────
  static const String notifications = 'الإشعارات';
  static const String noNotifications = 'لا توجد إشعارات';
  static const String notifBookingAccepted = 'قبل الحرفي طلبك ✅';
  static const String notifNewMessage = 'رسالة جديدة 💬';
  static const String notifReviewReminder = 'كيف كانت الخدمة؟ قيّم حرفيك ⭐';
  static const String notifReward = 'مكافأة جديدة 🎁';

  // ── Rewards ──────────────────────────────────────────────────────────
  static const String rewards = 'المكافآت';
  static const String rewardsTitle = 'ادعُ أصدقاءك واربح ترقيات مجانية';
  static const String rewardsBody =
      'شارك رمز الدعوة الخاص بك: كل صديق يسجّل ويكمل أول حجز يمنحك نقاطاً. اجمع النقاط للحصول على إبراز مجاني لملفك أو خصومات على الخدمات.';
  static const String yourCode = 'رمز الدعوة الخاص بك';
  static const String copyCode = 'نسخ الرمز';
  static const String codeCopied = 'تم نسخ الرمز ✓';
  static const String shareInvite = 'مشاركة الدعوة';
  static const String myPoints = 'نقاطي';
  static const String inviteHistory = 'سجل الدعوات';
  static const String rewardFeatured =
      'إبراز الملف 7 أيام (يظهر أولاً في النتائج)';
  static const String redeem = 'استبدال';
  static const String notEnoughPoints = 'نقاط غير كافية بعد — واصل الدعوة!';

  // ── Become craftsman ─────────────────────────────────────────────────
  static const String becomeCraftsman = 'سجّل كحرفي';
  static const String bcStep1 = 'المعلومات الشخصية';
  static const String bcStep2 = 'المهن والولاية';
  static const String bcStep3 = 'الوثائق والأعمال';
  static const String bcStep4 = 'مراجعة وتأكيد';
  static const String fullName = 'الاسم الكامل';
  static const String chooseTrades = 'اختر مهنتك (يمكن اختيار أكثر من واحدة)';
  static const String uploadChamberCard = '📄 صورة بطاقة الحرفي (غرفة الحرفة)';
  static const String uploadChamberCardSub =
      'تمنحك شارة "حرفي موثّق" وتضاعف ثقة الزبائن';
  static const String uploadPortfolio = '📷 صور من أعمالك (3 على الأقل)';
  static const String chooseUploadType = 'اختر طريقة الرفع';
  static const String uploadPhoto = '📷 التقط صورة بالكاميرا';
  static const String uploadPdf = '📄 ارفع ملف PDF';
  static const String verificationSubmitted =
      'تم إرسال وثيقة التحقق — ملفك الآن قيد المراجعة';
  static const String pendingReview = 'قيد المراجعة';
  static const String notVerifiedYet = 'غير موثّق بعد';
  static const String submitApplication = 'أرسل الطلب';
  static const String applicationSent = 'تم استلام طلبك!';
  static const String applicationPending =
      'طلبك قيد المراجعة من فريق بريكولا، سنعلمك فور الموافقة (عادة خلال 24–48 ساعة).';
  static const String backToHome = 'عودة للرئيسية';

  // ── Account ──────────────────────────────────────────────────────────
  static const String account = 'حسابي';
  static const String editProfile = 'تعديل الملف';
  static const String language = 'اللغة';
  static const String help = 'المساعدة';
  static const String about = 'عن بريكولا';
  static const String terms = 'الشروط والأحكام';
  static const String privacy = 'سياسة الخصوصية';
  static const String legalNotice =
      'تخضع معالجة بياناتك الشخصية لأحكام القانون 18-07 المتعلق بحماية الأشخاص الطبيعيين في مجال معالجة المعطيات ذات الطابع الشخصي.';
  static const String cashPaymentNote =
      'الدفع حالياً نقداً عند إنجاز الخدمة. الدفع الإلكتروني ببطاقات CIB و EDAHABIA قيد التطوير.';

  // ── Common ───────────────────────────────────────────────────────────
  static const String loading = 'جارٍ التحميل…';
  static const String errorGeneric = 'حدث خطأ، حاول مجدداً';
  static const String emptyHere = 'لا يوجد شيء هنا بعد';
  static const String confirm = 'تأكيد';
  static const String cancel = 'إلغاء';
  static const String save = 'حفظ';
  static const String delete = 'حذف';
  static const String retry = 'إعادة المحاولة';
  static const String from = 'من';
  static const String to = 'إلى';
  static const String kmAway = 'كم';

  // ── Admin ──────────────────────────────────────────────────────────
  static const String adminPanel = 'لوحة الإدارة';
  static const String adminOnly = 'للإدارة فقط';
  static const String pendingRequests = 'طلبات قيد المراجعة';
  static const String noPendingRequests = 'لا توجد طلبات معلقة 🎉';
  static const String approve = 'قبول';
  static const String reject = 'رفض';
  static const String confirmApprove = 'قبول هذا الحرفي؟';
  static const String confirmReject = 'رفض هذا الطلب؟';
  static const String chamberDocVerified = 'وثيقة الغرفة مؤكدة';
  static const String verificationDoc = 'وثيقة التحقق';
  static const String noDocUploaded = 'لم يرفع وثيقة';
  static const String notAuthorized = 'غير مصرح لك بالدخول';
  static const String noInternet = 'لا يوجد اتصال بالإنترنت';
  static const String noInternetHint = 'تحقق من اتصالك ثم أعد المحاولة';

  // ── Admin PIN ────────────────────────────────────────────────────
  static const String pinTitle = 'رمز الإدارة';
  static const String pinSubtitle =
      'أدخل رمز PIN للوصول إلى لوحة الإدارة';
  static const String createPinTitle = 'أنشئ رمز PIN';
  static const String createPinSubtitle =
      'اختر رمزاً سرياً (4 أرقام على الأقل) لحماية لوحة الإدارة';
  static const String pinLabel = 'رمز PIN';
  static const String pinConfirmLabel = 'تأكيد الرمز';
  static const String pinMismatch = 'الرمزان غير متطابقين';
  static const String pinTooShort = 'الرمز قصير جداً (4 أرقام على الأقل)';
  static const String pinWrong = 'رمز خاطئ، حاول مجدداً';
  static const String pinSet = 'تم حفظ الرمز بنجاح';

  // ── Admin tabs ───────────────────────────────────────────────────
  static const String tabRequests = 'الطلبات';
  static const String tabCraftsmen = 'الحرفيون';
  static const String tabBookings = 'الحجوزات';
  static const String tabUsers = 'المستخدمون';
  static const String tabStats = 'إحصائيات';
  static const String tabBroadcast = 'إشعار';

  // ── Admin actions ────────────────────────────────────────────────
  static const String suspend = 'تعليق';
  static const String reactivate = 'تفعيل';
  static const String confirmSuspend = 'تعليق حساب هذا الحرفي؟';
  static const String confirmDeleteCraftsman =
      'حذف ملف هذا الحرفي نهائياً؟';
  static const String statusSuspended = 'معلّق';
  static const String statusApproved = 'مقبول';
  static const String makeAdmin = 'جعله أدمن';
  static const String removeAdmin = 'إزالة الأدمن';
  static const String confirmMakeAdmin =
      'منح صلاحية الأدمن لهذا المستخدم؟';
  static const String confirmRemoveAdmin =
      'سحب صلاحية الأدمن من هذا المستخدم؟';
  static const String roleAdmin = 'أدمن';
  static const String roleCustomer = 'زبون';
  static const String roleCraftsman = 'حرفي';
  static const String statCraftsmen = 'حرفيون معتمدون';
  static const String statPending = 'طلبات معلقة';
  static const String statBookings = 'الحجوزات';
  static const String statUsers = 'المستخدمون';
  static const String broadcastTitleLabel = 'عنوان الإشعار';
  static const String broadcastBodyLabel = 'نص الإشعار';
  static const String sendBroadcast = 'إرسال للجميع';
  static const String confirmBroadcast =
      'إرسال هذا الإشعار لجميع المستخدمين؟';
  static const String broadcastDone = 'تم الإرسال';
  static const String allFilter = 'الكل';
}
