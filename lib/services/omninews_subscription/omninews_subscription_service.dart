import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseResult {
  final bool success;
  final String productId;
  final String? message;

  PurchaseResult({
    required this.success,
    required this.productId,
    this.message,
  });
}

class SubscriptionService {
  final _statusController = StreamController<SubscriptionStatus>.broadcast();
  Stream<SubscriptionStatus> get statusStream => _statusController.stream;

  // 최종 구매 결과 스트림: 서버 검증까지 끝난 뒤 성공/실패 이벤트 발행
  final _purchaseResultController =
      StreamController<PurchaseResult>.broadcast();
  Stream<PurchaseResult> get purchaseResultStream =>
      _purchaseResultController.stream;

  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdateSubscription;
  final _inAppPurchase = InAppPurchase.instance;
  final AuthService _authService = AuthService();
  final bool skipInitialCheck;

  SubscriptionService({this.skipInitialCheck = false});

  // 트랜잭션 리스너만 설정
  Future<void> setupListener() async {
    try {
      if (_purchaseUpdateSubscription == null) {
        _setupTransactionListener();
        debugPrint('구독 트랜잭션 리스너 설정 완료');
      }
    } catch (e) {
      debugPrint('구독 리스너 설정 중 오류: $e');
    }
  }

  Future<void> initialize() async {
    try {
      await setupListener();

      if (!skipInitialCheck) {
        final status = await checkSubscriptionStatus();
        _statusController.add(status);
        debugPrint('초기화 시 구독 상태 확인 완료');
      } else {
        debugPrint('초기화 시 구독 상태 확인 생략됨');
      }
    } catch (e) {
      debugPrint('SubscriptionService 초기화 중 오류: $e');
    }
  }

  void _setupTransactionListener() {
    debugPrint('인앱 구매 트랜잭션 리스너 설정 중...');
    _purchaseUpdateSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () {
        _purchaseUpdateSubscription?.cancel();
        debugPrint('구매 스트림 리스닝 종료됨');
      },
      onError: (error) {
        debugPrint('구매 스트림 오류: $error');
      },
    );
    debugPrint('인앱 구매 트랜잭션 리스너 설정 완료');
  }

  // 구독 상태 확인 - 서버 API 사용
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    try {
      if (!_authService.isLoggedIn) {
        return SubscriptionStatus(isActive: false);
      }

      final response = await _authService.apiRequest(
        'GET',
        '/subscription/verify',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          final isActive = data['is_active'] ?? false;
          final productId = data['product_id'] ?? 'unknown';

          DateTime? expiryDate;
          if (data['expires_date'] != null) {
            try {
              expiryDate = DateTime.parse(data['expires_date']);
            } catch (e) {
              debugPrint('만료일 파싱 오류: $e');
            }
          }

          return SubscriptionStatus(
            isActive: isActive,
            productId: productId,
            expiryDate: expiryDate,
          );
        }
      }

      return SubscriptionStatus(isActive: false);
    } catch (e) {
      debugPrint('구독 상태 확인 중 오류: $e');
      return SubscriptionStatus(isActive: false);
    }
  }

  // 서버에 구독 정보 등록
  Future<bool> registerSubscriptionWithServer(PurchaseDetails purchase) async {
    try {
      final receiptData = purchase.verificationData.serverVerificationData;

      final subscriptionRequest = SubscriptionRequest(
        receiptData: receiptData,
        platform: Platform.isIOS ? 'ios' : 'android',
        isTest: true,
      );

      final response = await _authService.apiRequest(
        'POST',
        '/subscription/register',
        body: subscriptionRequest.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('서버에 구독 등록 성공');
        return true;
      } else {
        debugPrint('서버에 구독 등록 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('서버에 구독 등록 실패: $e');
      return false;
    }
  }

  // 구독 플랜 로드
  Future<List<SubscriptionPlan>> loadSubscriptionPlans() async {
    try {
      final productIds = {'kdh.omninews.premium'};
      final response = await _inAppPurchase.queryProductDetails(productIds);

      return response.productDetails.map((product) {
        return SubscriptionPlan(
          id: product.id,
          name: '프리미엄 구독',
          description: product.description,
          price:
              double.tryParse(
                product.price.replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0.0,
          features: ['광고 없이 기사 읽기', '프리미엄 콘텐츠 이용', '개인화된 추천'],
          durationDays: 30,
        );
      }).toList();
    } catch (e) {
      debugPrint('구독 상품 로드 중 오류: $e');
      return [];
    }
  }

  // 구독 구매 시작
  Future<bool> purchasePlan(String productId) async {
    try {
      debugPrint("구독 구매 시작: $productId");

      final products = await _inAppPurchase.queryProductDetails({productId});
      if (products.productDetails.isEmpty) {
        debugPrint('상품을 찾을 수 없습니다: $productId');
        return false;
      }

      final product = products.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);

      bool purchaseStarted;
      if (Platform.isIOS) {
        debugPrint("iOS에서 구독 구매 요청");
        purchaseStarted = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        debugPrint("Android에서 구독 구매 요청");
        // 주의: 구독은 일반적으로 non-consumable로 처리합니다.
        // 기존 코드 유지가 필요하면 buyConsumable을 사용하세요.
        purchaseStarted = await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
        );
      }

      debugPrint("구매 요청 시작 결과: $purchaseStarted");
      return purchaseStarted;
    } catch (e) {
      debugPrint('구독 구매 중 오류: $e');
      return false;
    }
  }

  // 구매 복원
  Future<bool> restorePurchases() async {
    try {
      debugPrint("구매 내역 복원 시도 중...");
      await _inAppPurchase.restorePurchases();
      debugPrint("구매 내역 복원 요청 완료");
      return true;
    } catch (e) {
      debugPrint('구매 복원 중 오류: $e');
      return false;
    }
  }

  void _emitFailure(PurchaseDetails purchase, String msg) {
    debugPrint(msg);
    _purchaseResultController.add(
      PurchaseResult(
        success: false,
        productId: purchase.productID,
        message: msg,
      ),
    );
  }

  void _emitSuccess(PurchaseDetails purchase) {
    _purchaseResultController.add(
      PurchaseResult(success: true, productId: purchase.productID),
    );
  }

  // 구매 상태 업데이트 핸들러
  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint('트랜잭션 상태: ${purchase.status} - 상품: ${purchase.productID}');
      debugPrint('거래 ID: ${purchase.purchaseID ?? "없음"}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('결제가 진행 중입니다');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          debugPrint('구매 완료 또는 복원됨: ${purchase.productID}');

          // 1) 서버 검증
          final verified = await registerSubscriptionWithServer(purchase);

          if (verified) {
            debugPrint('서버에 구독 등록 성공');

            // 2) 상태 갱신
            final status = await checkSubscriptionStatus();
            _statusController.add(status);

            // 3) 성공 이벤트
            _emitSuccess(purchase);

            // 4) 트랜잭션 완료 처리
            if (purchase.pendingCompletePurchase) {
              await _inAppPurchase.completePurchase(purchase);
              debugPrint('트랜잭션 완료됨');
            }
          } else {
            // 서버 검증 실패 → 실패 이벤트 및 플랫폼별 처리
            _emitFailure(purchase, '서버 검증 실패로 구독이 적용되지 않습니다.');

            if (Platform.isAndroid) {
              // Android: acknowledge 생략 → 일정 시간 후 자동 환불 유도
              debugPrint('Android: 서버 검증 실패 → acknowledge 생략하여 자동 환불 유도');
              // 필요 시 아래 주석을 해제해 항상 트랜잭션을 완료하도록 할 수 있습니다.
              // if (purchase.pendingCompletePurchase) {
              //   await _inAppPurchase.completePurchase(purchase);
              // }
            } else {
              // iOS: 트랜잭션은 반드시 완료 처리
              if (purchase.pendingCompletePurchase) {
                await _inAppPurchase.completePurchase(purchase);
                debugPrint('iOS: 실패지만 트랜잭션은 finish 처리');
              }
            }
          }
          break;

        case PurchaseStatus.error:
          debugPrint('구매 오류: ${purchase.error?.message ?? "알 수 없는 오류"}');
          _emitFailure(
            purchase,
            '구매 오류: ${purchase.error?.message ?? "알 수 없는 오류"}',
          );

          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('구매가 취소되었습니다');
          _emitFailure(purchase, '구매가 취소되었습니다');
          break;
      }
    }
  }

  // 계정 전환 후 구독 정보 갱신
  Future<void> handleAccountSwitch() async {
    try {
      debugPrint('계정 전환 후 구독 정보 갱신 중...');

      if (_authService.isLoggedIn) {
        final status = await checkSubscriptionStatus();
        _statusController.add(status);
      }
    } catch (e) {
      debugPrint('계정 전환 후 구독 정보 갱신 오류: $e');
    }
  }

  // 구독 관리 페이지로 이동
  Future<bool> navigateToSubscriptionManagement() async {
    try {
      Uri url;

      if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse('App-prefs:SUBSCRIPTIONS'))) {
          return await launchUrl(Uri.parse('App-prefs:SUBSCRIPTIONS'));
        }
        url = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else if (Platform.isAndroid) {
        url = Uri.parse('https://play.google.com/store/account/subscriptions');
      } else {
        return false;
      }

      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('구독 관리 페이지 이동 중 오류: $e');
      return false;
    }
  }

  void dispose() {
    debugPrint('SubscriptionService 리소스 해제');
    _purchaseUpdateSubscription?.cancel();
    _statusController.close();
    _purchaseResultController.close();
  }
}
