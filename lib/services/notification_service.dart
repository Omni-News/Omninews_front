import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/screens/rss_detail_screen.dart';
import 'package:omninews_flutter/services/notification_navigation.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/services/rss_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  NotificationService._();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 로컬 알림 설정
    await _initLocalNotifications();

    // 포그라운드 알림 핸들링
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("포그라운드 메시지 수신: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // 앱이 백그라운드에서 알림을 통해 열렸을 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("백그라운드 알림 클릭: ${message.notification?.title}");
      _handleRemoteMessage(message);
    });

    // 앱이 종료된 상태에서 알림을 통해 열렸는지 확인
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("종료 상태에서 알림 클릭: ${initialMessage.notification?.title}");
      _handleRemoteMessage(initialMessage);
    }
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleLocalNotificationPayload(details.payload);
      },
    );

    // Android 채널 설정
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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
    if (kIsWeb) return;

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
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  void _handleLocalNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationData(decoded);
      }
    } catch (e) {
      debugPrint('알림 payload 파싱 실패: $e');
    }
  }

  void _handleNotificationData(Map<dynamic, dynamic> data) {
    final payload = NotificationRssPayload.fromData(data);
    if (payload == null) return;

    _openRssDetail(payload.item);
  }

  void _openRssDetail(RssItem item) {
    RecentlyReadService.addRssItem(item);
    unawaited(RssService.updateRssRank(item.rssId));

    void pushDetail() {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => RssDetailScreen(rssItem: item)),
      );
    }

    if (navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pushDetail());
      return;
    }

    pushDetail();
  }
}
