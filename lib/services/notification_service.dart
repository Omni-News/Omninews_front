import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _token;

  NotificationService._();

  Future<void> init() async {
    // 알림 권한 요청 (iOS에서는 필수)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // FCM 토큰 가져오기
    _token = await _fcm.getToken();
    print("FCM 토큰: $_token");

    // 토큰이 새로 생성될 때마다 서버에 업데이트하기 위한 리스너
    _fcm.onTokenRefresh.listen((newToken) {
      _token = newToken;
      // 토큰 업데이트 - 서버에 새 토큰을 저장하는 함수 호출
      _sendTokenToServer(newToken);
    });

    // 로컬 알림 설정
    _initLocalNotifications();

    // 포그라운드 알림 핸들링
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("포그라운드 메시지 수신: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // 앱이 백그라운드에서 알림을 통해 열렸을 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("백그라운드 알림 클릭: ${message.notification?.title}");
      // 알림 클릭시 특정 화면으로 이동하는 로직
      _handleNotificationClick(message);
    });

    // 앱이 종료된 상태에서 알림을 통해 열렸는지 확인
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print("종료 상태에서 알림 클릭: ${initialMessage.notification?.title}");
      _handleNotificationClick(initialMessage);
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // 로컬 알림 클릭 처리
      },
    );

    // Android 채널 설정
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            '중요 알림',
            description: '이 채널은 중요한 알림에 사용됩니다',
            importance: Importance.high,
          ),
        );
  }

  // FCM 메시지를 로컬 알림으로 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            '중요 알림',
            channelDescription: '이 채널은 중요한 알림에 사용됩니다',
            icon: android?.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // 알림 클릭 처리
  void _handleNotificationClick(RemoteMessage message) {
    // 알림의 데이터를 이용하여 특정 화면으로 라우팅하는 로직
    // 예: 새 글 알림이면 해당 글 상세 페이지로 이동
    if (message.data.containsKey('postId')) {
      // 게시글 페이지로 이동하는 로직
      print('게시글 ID: ${message.data['postId']}로 이동');
    }
  }

  // 서버에 FCM 토큰 전송
  Future<void> _sendTokenToServer(String token) async {
    // 서버 API를 호출하여 토큰을 저장하는 로직
    // 예: 사용자 인증 정보와 함께 토큰을 서버에 저장
    print('토큰을 서버에 전송: $token');

    // 실제 구현에서는 HTTP 요청을 사용하여 서버에 토큰을 전송
    // 예: dio 또는 http 패키지 사용
  }

  // 현재 토큰 가져오기 (서버에 전송하기 위해)
  String? getToken() {
    return _token;
  }
}
