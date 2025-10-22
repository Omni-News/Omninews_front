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

class ServerRegisterResult {
  final bool ok;
  final String? err;

  ServerRegisterResult({required this.ok, this.err});
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

  // 최초 진입 시 검증 스킵 여부
  final bool skipInitialCheck;

  // 사용자 유도 여부 플래그
  bool _userInitiatedPurchase = false;
  bool _userInitiatedRestore = false; // ← 복원 버튼으로 시작했는지

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

      // 최초 진입 시에는 register가 아닌 verify만 수행
      if (!skipInitialCheck) {
        final status = await checkSubscriptionStatus();
        _statusController.add(status);
        debugPrint('초기화 시 구독 상태 확인(verify) 완료');
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

  // 구독 상태 확인 - 서버 API 사용 (verify 전용)
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

  // 서버에 구독 정보 등록 (register)
  // - iOS: transaction_id(필수)
  // - Android: transaction_id(가능하면) + purchase_token(권장)
  Future<ServerRegisterResult> registerSubscriptionWithServer(
    PurchaseDetails purchase,
  ) async {
    try {
      final transactionId = purchase.purchaseID; // iOS/Android 식별자(없을 수 있음)

      // Android의 경우 purchaseID가 null일 수 있으므로 purchaseToken을 함께 전달
      final serverVerificationData =
          purchase.verificationData.serverVerificationData;
      final bool isAndroid = Platform.isAndroid;
      final bool isIOS = Platform.isIOS;

      if ((transactionId == null || transactionId.isEmpty) &&
          (!isAndroid || serverVerificationData.isEmpty)) {
        final errorMsg =
            '서버 등록 실패: 전송할 식별자가 없습니다. (transactionId/purchaseToken 없음)';
        debugPrint(errorMsg);
        return ServerRegisterResult(ok: false, err: errorMsg);
      }

      final body = <String, dynamic>{'platform': isIOS ? 'ios' : 'android'};

      if (transactionId != null && transactionId.isNotEmpty) {
        body['transaction_id'] = transactionId;
      }
      if (isAndroid && serverVerificationData.isNotEmpty) {
        // 서버가 지원한다면 purchase_token으로 검증/연결
        body['purchase_token'] = serverVerificationData;
      }

      final response = await _authService.apiRequest(
        'POST',
        '/subscription/register',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('서버에 구독 등록 성공');
        return ServerRegisterResult(ok: true);
      } else {
        final errorMsg = response.body ?? '서버 등록 실패';
        debugPrint('서버에 구독 등록 실패: ${response.statusCode} - $errorMsg');
        return ServerRegisterResult(ok: false, err: errorMsg);
      }
    } catch (e) {
      final errorMsg = '서버에 구독 등록 실패: $e';
      debugPrint(errorMsg);
      return ServerRegisterResult(ok: false, err: errorMsg);
    }
  }

  // 구독 플랜 로드
  Future<List<SubscriptionPlan>> loadSubscriptionPlans() async {
    try {
      Set<String> productIds;
      if (Platform.isAndroid) {
        productIds = {'omninews-premium'};
      } else if (Platform.isIOS) {
        productIds = {'kdh.omninews.premium'};
      } else {
        productIds = {};
      }

      final response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('스토어에서 찾지 못한 상품 IDs: ${response.notFoundIDs}');
      }
      if (response.productDetails.isEmpty) {
        debugPrint('상품 상세가 비어 있음');
        return [];
      }

      return response.productDetails.map((product) {
        return SubscriptionPlan(
          id: product.id,
          name: '프리미엄 구독',
          description: product.description,
          price: product.rawPrice,
          currencyCode: product.currencyCode,
          priceString: product.price,
          features: ['광고 없이 기사 읽기', '다양한 플랫폼 RSS 생성', '무제한 RSS 요약'],
          durationDays: 30,
        );
      }).toList();
    } catch (e) {
      debugPrint('구독 상품 로드 중 오류: $e');
      return [];
    }
  }

  // 구독 구매 시작 (사용자 버튼 → 여기서만 register 가능하도록 플래그 설정)
  Future<bool> purchasePlan(String productId) async {
    _userInitiatedPurchase = true; // 사용자 유도 구매 시작
    try {
      debugPrint("구독 구매 시작: $productId");

      final products = await _inAppPurchase.queryProductDetails({productId});
      if (products.productDetails.isEmpty) {
        debugPrint('상품을 찾을 수 없습니다: $productId');
        _userInitiatedPurchase = false; // 실패 시 플래그 해제
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
        purchaseStarted = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }

      debugPrint("구매 요청 시작 결과: $purchaseStarted");
      if (!purchaseStarted) {
        _userInitiatedPurchase = false;
      }
      return purchaseStarted;
    } catch (e) {
      debugPrint('구독 구매 중 오류: $e');
      _userInitiatedPurchase = false;
      return false;
    }
  }

  // 구매 복원 (사용자 버튼으로 시작했을 때만 서버 등록 허용)
  Future<bool> restorePurchases() async {
    try {
      debugPrint("구매 내역 복원 시도 중...");
      _userInitiatedRestore = true; // ← 복원 트리거 표시
      await _inAppPurchase.restorePurchases();
      debugPrint("구매 내역 복원 요청 완료");
      return true;
    } catch (e) {
      debugPrint('구매 복원 중 오류: $e');
      _userInitiatedRestore = false;
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

          final bool shouldRegister =
              _userInitiatedPurchase || _userInitiatedRestore;

          if (shouldRegister) {
            // 사용자가 버튼을 눌러 시작한 경우에만 register 수행 (복원 포함)
            final result = await registerSubscriptionWithServer(purchase);

            if (result.ok) {
              // 1. Ok가 나오면 걍 구독 진행
              debugPrint('서버에 구독 등록/연결 성공');
              final status = await checkSubscriptionStatus(); // 등록 후 상태 동기화
              _statusController.add(status);
              if (_userInitiatedPurchase) {
                _emitSuccess(purchase);
              }
              if (purchase.pendingCompletePurchase) {
                await _inAppPurchase.completePurchase(purchase);
                debugPrint('트랜잭션 완료됨');
              }
            } else {
              // 2. err가 나오면 에러 메시지와 함께 실패 처리
              final errorMessage = result.err ?? '서버 등록/검증 실패로 구독이 적용되지 않습니다.';
              _emitFailure(purchase, errorMessage);

              if (Platform.isAndroid) {
                // Android: acknowledge 생략 → 자동 환불 유도
                debugPrint('Android: 서버 검증 실패 → acknowledge 생략하여 자동 환불 유도');
              } else {
                // iOS: 트랜잭션은 반드시 완료 처리
                if (purchase.pendingCompletePurchase) {
                  await _inAppPurchase.completePurchase(purchase);
                  debugPrint('iOS: 실패지만 트랜잭션은 finish 처리');
                }
              }
            }

            // 처리 후 플래그 해제
            _userInitiatedPurchase = false;
            _userInitiatedRestore = false;
          } else {
            // 앱 초기 진입 등 사용자 유도 구매가 아닌 이벤트:
            // register는 절대 하지 않고 verify만 수행
            debugPrint('사용자 유도 구매/복원이 아님 → register 생략, verify만 수행하여 상태 동기화');
            final status = await checkSubscriptionStatus();
            _statusController.add(status);

            // 상태에 따라 트랜잭션 완료 처리 결정
            final isActive = status.isActive;
            if (Platform.isIOS) {
              // iOS는 트랜잭션을 완료 처리
              if (purchase.pendingCompletePurchase) {
                await _inAppPurchase.completePurchase(purchase);
                debugPrint('iOS: 초기/복원 이벤트 트랜잭션 finish 처리');
              }
            } else {
              // Android: 비활성인 경우 ack 생략하여 환불 유도, 활성이라면 완료 처리
              if (isActive && purchase.pendingCompletePurchase) {
                await _inAppPurchase.completePurchase(purchase);
                debugPrint('Android: 활성 상태 → 트랜잭션 완료 처리');
              } else {
                debugPrint('Android: 비활성 상태 → acknowledge 생략(환불 유도)');
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
          _userInitiatedPurchase = false;
          _userInitiatedRestore = false;
          break;

        case PurchaseStatus.canceled:
          debugPrint('구매가 취소되었습니다');
          _emitFailure(purchase, '구매가 취소되었습니다');
          _userInitiatedPurchase = false;
          _userInitiatedRestore = false;
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
