import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  SubscriptionStatus _status = SubscriptionStatus(isActive: false);
  List<SubscriptionPlan> _availablePlans = [];
  bool _isLoading = false;

  SubscriptionStatus get status => _status;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  bool get isLoading => _isLoading;

  final SubscriptionService _subscriptionService;
  final AuthService _authService = AuthService();

  StreamSubscription<SubscriptionStatus>? _statusSub;

  SubscriptionProvider(this._subscriptionService);

  // 앱 시작시 구독 검증 없이 상품 정보만 로드
  Future<void> loadProductsOnly() async {
    _isLoading = true;
    notifyListeners();

    try {
      _availablePlans = await _subscriptionService.loadSubscriptionPlans();

      // 서비스의 상태 스트림을 구독해 UI 갱신 (중복 구독 방지)
      _statusSub?.cancel();
      _statusSub = _subscriptionService.statusStream.listen((status) {
        _status = status;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('구독 상품 로드 중 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그인 시 한 번만 호출되는 구독 상태 확인 메서드
  Future<void> checkSubscriptionOnLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('로그인 후 구독 상태 확인 시작');

      // 트랜잭션 리스너 설정
      await _subscriptionService.setupListener();

      // 구독 상태 확인
      _status = await _subscriptionService.checkSubscriptionStatus();

      // 구독 상품 정보 로드
      if (_availablePlans.isEmpty) {
        _availablePlans = await _subscriptionService.loadSubscriptionPlans();
      }

      // 상태 스트림 구독 (중복 방지)
      _statusSub?.cancel();
      _statusSub = _subscriptionService.statusStream.listen((status) {
        _status = status;
        notifyListeners();
      });

      debugPrint('로그인 후 구독 상태 확인 완료: ${_status.isActive ? "구독 중" : "구독 안함"}');
    } catch (e) {
      debugPrint('구독 상태 확인 중 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 구독 구매 시작: "시작됨" 여부만 반환
  Future<bool> purchaseSubscription(SubscriptionPlan plan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final started = await _subscriptionService.purchasePlan(plan.id);
      return started;
    } catch (e) {
      debugPrint('구독 구매 중 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 특정 상품의 최종 결과를 기다림 (스토어 콜백 + 서버 검증까지)
  Future<PurchaseResult> waitForPurchaseResult(
    String productId, {
    Duration timeout = const Duration(minutes: 2),
  }) {
    return _subscriptionService.purchaseResultStream
        .firstWhere((r) => r.productId == productId)
        .timeout(timeout);
  }

  // 초기화 - 앱 시작시 자동 복원 추가
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _subscriptionService.initialize();

      _status = await _subscriptionService.checkSubscriptionStatus();
      _availablePlans = await _subscriptionService.loadSubscriptionPlans();

      if (_authService.isLoggedIn) {
        debugPrint('사용자 로그인 상태에서 구독 복원 시도...');
        await _subscriptionService.handleAccountSwitch();

        _status = await _subscriptionService.checkSubscriptionStatus();
      }

      // 상태 스트림 구독 (중복 방지)
      _statusSub?.cancel();
      _statusSub = _subscriptionService.statusStream.listen((status) {
        _status = status;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 계정 전환 후 구독 상태 새로고침
  Future<void> refreshAfterAccountChange() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _subscriptionService.handleAccountSwitch();
      _status = await _subscriptionService.checkSubscriptionStatus();
      _authService.resetRecentLoginFlag();
    } catch (e) {
      debugPrint('계정 변경 후 구독 새로고침 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 구독 상태 새로고침 (복원 + 검증)
  Future<void> refreshSubscriptionStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _subscriptionService.restorePurchases();
      // 복원 이벤트가 들어올 시간을 약간 줌 (스토어 콜백 → 서버 등록/검증 → 상태 반영)
      await Future.delayed(const Duration(seconds: 1));
      _status = await _subscriptionService.checkSubscriptionStatus();
    } catch (e) {
      debugPrint('Error refreshing subscription status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UI에서 직접 호출할 구매 복원
  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ok = await _subscriptionService.restorePurchases();
      // 복원 → 콜백 처리 대기 후 서버 상태 확인
      await Future.delayed(const Duration(seconds: 1));
      _status = await _subscriptionService.checkSubscriptionStatus();
      return ok;
    } catch (e) {
      debugPrint('구매 복원 중 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 구독 취소 안내 메서드
  Future<bool> navigateToSubscriptionManagement() async {
    return await _subscriptionService.navigateToSubscriptionManagement();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }
}
