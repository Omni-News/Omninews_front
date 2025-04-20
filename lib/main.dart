import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:omninews_flutter/firebase_options.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'provider/theme_provider.dart';
import 'screens/home_screen.dart';

// 백그라운드 메시징 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('백그라운드 메시지 처리: ${message.messageId}');
}

// 앱 초기화 함수
Future<void> _initializeApp() async {
  // Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // iOS에서만 권한 요청
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // FCM 토큰 가져오기 시도 (시뮬레이터가 아닌 실제 기기에서만)
  if (!kIsWeb && !(Platform.isIOS && !isRealDevice())) {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print('FCM 토큰: $token');
    } catch (e) {
      print('FCM 토큰 가져오기 실패: $e');
    }
  } else {
    print('시뮬레이터나 웹에서는 FCM 토큰을 가져오지 않습니다.');
  }

  final authService = AuthService();
  await authService.initialize();
}

// 시뮬레이터 여부 확인 함수 (iOS)
bool isRealDevice() {
  if (Platform.isIOS) {
    // 시뮬레이터 감지 로직 (간단한 휴리스틱)
    if (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_VERSION_INFO')) {
      return false;
    }
  }
  return true;
}

void main() async {
  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: "89046ab727ea7019b5ec60e5aa53f5cb");

  try {
    // Firebase 등 앱 초기화
    await _initializeApp();
  } catch (e) {
    print('앱 초기화 중 오류 발생: $e');
    // 초기화 오류가 발생해도 앱은 계속 실행합니다
  }

  // 앱 실행
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
