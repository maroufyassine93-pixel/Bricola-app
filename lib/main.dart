import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'l10n/strings_ar.dart';
import 'screens/account_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/become_craftsman/step1_personal.dart';
import 'screens/become_craftsman/step2_trades.dart';
import 'screens/become_craftsman/step3_documents.dart';
import 'screens/become_craftsman/step4_review.dart';
import 'screens/become_craftsman/success_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/category_detail_screen.dart';
import 'screens/chat_detail_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/craftsman_list_screen.dart';
import 'screens/craftsman_profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/email_login_screen.dart';
import 'screens/phone_login_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/messaging_service.dart';
import 'services/referral_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppConfig.firebaseReady = true;
  } catch (e) {
    // Demo mode: Firebase not configured yet (`flutterfire configure`
    // not run). Initialize a placeholder DEFAULT app so that
    // FirebaseAuth/Firestore/Storage/Messaging.instance don't throw
    // `[core/no-app]`. Services short-circuit to empty demo data when
    // !AppConfig.firebaseReady, so the app stays fully navigable.
    debugPrint('Firebase init skipped (demo mode): $e');
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:0:android:bricola-demo',
          messagingSenderId: '0',
          projectId: 'bricola-demo',
        ),
      );
    } catch (_) {
      // Already initialized — ignore.
    }
    AppConfig.firebaseReady = false;
  }
  runApp(const BricolaApp());
}

class BricolaApp extends StatelessWidget {
  const BricolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => MessagingService()),
        Provider(create: (_) => ReferralService()),
      ],
      child: MaterialApp(
        title: S.appName,
        debugShowCheckedModeBanner: false,
        theme: BricolaTheme.light(),
        // Arabic-first RTL.
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/',
        onGenerateRoute: _routes,
      ),
    );
  }

  Route<dynamic> _routes(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
        page = const SplashScreen();
        break;
      case '/onboarding':
        page = const OnboardingScreen();
        break;
      case '/login':
        // Email login while phone SMS is unavailable; switch back to
        // PhoneLoginScreen when Blaze is funded.
        page = const EmailLoginScreen();
        break;
      case '/home':
        page = const HomeScreen();
        break;
      case '/category':
        page = CategoryDetailScreen(
            groupId: settings.arguments as String);
        break;
      case '/craftsmen':
        final args =
            (settings.arguments as Map<String, dynamic>?) ?? {};
        page = CraftsmanListScreen(
          tradeId: args['tradeId'] as String?,
          wilayaCode: args['wilayaCode'] as int?,
          verifiedOnly: args['verifiedOnly'] as bool? ?? false,
          availableNowOnly:
              args['availableNowOnly'] as bool? ?? false,
          query: args['query'] as String?,
        );
        break;
      case '/craftsman':
        page = CraftsmanProfileScreen(
            craftsmanId: settings.arguments as String);
        break;
      case '/booking':
        final args = settings.arguments as Map<String, dynamic>;
        page = BookingScreen(
          craftsmanId: args['craftsmanId'] as String,
          tradeId: args['tradeId'] as String?,
        );
        break;
      case '/chats':
        page = const ChatListScreen();
        break;
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>;
        page = ChatDetailScreen(
          chatId: args['chatId'] as String,
          otherName: args['otherName'] as String? ?? '',
          bookingId: args['bookingId'] as String?,
        );
        break;
      case '/notifications':
        page = const NotificationsScreen();
        break;
      case '/rewards':
        page = const RewardsScreen();
        break;
      case '/account':
        page = const AccountScreen();
        break;
      case '/admin':
        page = const AdminScreen();
        break;
      case '/become/step1':
        page = const BecomeStep1Personal();
        break;
      case '/become/step2':
        page = const BecomeStep2Trades();
        break;
      case '/become/step3':
        page = const BecomeStep3Documents();
        break;
      case '/become/step4':
        page = const BecomeStep4Review();
        break;
      case '/become/success':
        page = const BecomeSuccessScreen();
        break;
      default:
        page = const SplashScreen();
    }
    return MaterialPageRoute(
        builder: (_) => page, settings: settings);
  }
}

/// Current Firebase uid, or empty when signed out / in demo mode.
String currentUid() {
  if (!AppConfig.firebaseReady) return '';
  return FirebaseAuth.instance.currentUser?.uid ?? '';
}
