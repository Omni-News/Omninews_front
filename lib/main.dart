import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:omninews_flutter/firebase_options.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/provider/subscription_provider.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';
import 'package:omninews_flutter/services/omninews_subscription/receipt_validator.dart';
import 'package:provider/provider.dart';
import 'provider/theme_provider.dart';
import 'screens/home_screen.dart';

// 백그라운드 메시징 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('백그라운드 메시지 처리: ${message.messageId}');
}

// 앱 초기화 함수
Future<void> _initializeApp() async {
  // Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // AuthService 초기화 - 자동 로그인 준비
  final authService = AuthService();
  await authService.initialize();
  debugPrint('AuthService 초기화 완료: 토큰 있음=${authService.accessToken != null}');
}

// StoreKit 초기화 함수
void initStoreKit() {
  debugPrint("StoreKit 초기화: ${InAppPurchase.instance}");
}

void main() async {
  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: "89046ab727ea7019b5ec60e5aa53f5cb");

  // Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase 등 앱 초기화
    await _initializeApp();

    // StoreKit 초기화 (필수 - 구독 서비스가 의존함)
    initStoreKit();
    debugPrint('앱 초기화 완료: ${DateTime.now()} (kang1027)');
  } catch (e) {
    debugPrint('앱 초기화 중 오류 발생: $e');
  }

  // 구독 서비스 - 초기화는 하되 검증은 하지 않음
  final subscriptionService = SubscriptionService(skipInitialCheck: true);
  try {
    await subscriptionService.setupListener(); // 리스너만 설정
    debugPrint('구독 서비스 리스너 설정 완료');
  } catch (e) {
    debugPrint('구독 서비스 초기화 오류: $e');
  }

  // 앱 실행
  runApp(MyApp(subscriptionService: subscriptionService));
}

class MyApp extends StatelessWidget {
  final SubscriptionService? subscriptionService;

  const MyApp({super.key, this.subscriptionService});

  @override
  Widget build(BuildContext context) {
    final actualService =
        subscriptionService ?? SubscriptionService(skipInitialCheck: true);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (context) {
            // 초기화 단계에서는 구독 확인 않음 - 상품 정보만 로드
            final provider = SubscriptionProvider(actualService);
            provider.loadProductsOnly(); // 구독 검증 없이 상품만 로드
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Omninews',
            theme: themeProvider.currentTheme,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
