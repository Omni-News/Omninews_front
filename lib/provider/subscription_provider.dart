import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  SubscriptionStatus _status = SubscriptionStatus(isActive: false);
  List<SubscriptionPlan> _availablePlans = [];
  bool _isLoading = false;
  bool _hasCheckedSubscription = false;

  SubscriptionStatus get status => _status;
  List<SubscriptionPlan> get availablePlans => _availablePlans;
  bool get isLoading => _isLoading;

  final SubscriptionService _subscriptionService;
  final AuthService _authService = AuthService();

  SubscriptionProvider(this._subscriptionService);

  // 앱 시작시 구독 검증 없이 상품 정보만 로드
  Future<void> loadProductsOnly() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 구독 상품 정보만 로드
      _availablePlans = await _subscriptionService.loadSubscriptionPlans();

      // 리스너 구독 - 스토어 이벤트 수신만 준비
      _subscriptionService.statusStream.listen((status) {
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
    // 이미 확인한 경우 중복 검증 방지
    if (_hasCheckedSubscription) {
      debugPrint('구독 상태 이미 확인됨, 중복 검증 방지');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('로그인 후 구독 상태 확인 시작');

      // 트랜잭션 리스너 설정
      _subscriptionService.setupListener();

      // 구독 상태 확인
      _status = await _subscriptionService.checkSubscriptionStatus();

      // 구독 상품 정보 로드
      if (_availablePlans.isEmpty) {
        _availablePlans = await _subscriptionService.loadSubscriptionPlans();
      }

      _hasCheckedSubscription = true;
      debugPrint('로그인 후 구독 상태 확인 완료: ${_status.isActive ? "구독 중" : "구독 안함"}');
    } catch (e) {
      debugPrint('구독 상태 확인 중 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchaseSubscription(SubscriptionPlan plan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _subscriptionService.purchasePlan(plan.id);
      return success;
    } catch (e) {
      debugPrint('구독 구매 중 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 초기화 - 앱 시작시 자동 복원 추가
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 서비스 초기화 (이 과정에서 자동으로 구독 복원 시도)
      await _subscriptionService.initialize();

      // 구독 상태 로드
      _status = await _subscriptionService.checkSubscriptionStatus();

      // 구독 상품 로드
      _availablePlans = await _subscriptionService.loadSubscriptionPlans();

      // 로그인 상태에서만 자동 복원 시도
      if (_authService.isLoggedIn) {
        print('사용자 로그인 상태에서 구독 복원 시도...');
        await _subscriptionService.handleAccountSwitch();

        // 복원 후 상태 다시 확인
        _status = await _subscriptionService.checkSubscriptionStatus();
      }
    } catch (e) {
      debugPrint('Error initializing subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // 스트림 구독
    _subscriptionService.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });
  }

  // 계정 전환 후 구독 상태 새로고침
  Future<void> refreshAfterAccountChange() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 구독 서비스를 통해 계정 전환 처리
      await _subscriptionService.handleAccountSwitch();

      // 2. 구독 상태 갱신
      _status = await _subscriptionService.checkSubscriptionStatus();

      // 3. 최근 로그인 플래그 리셋 (다음 작업에서는 새 로그인으로 간주하지 않도록)
      _authService.resetRecentLoginFlag();
    } catch (e) {
      debugPrint('계정 변경 후 구독 새로고침 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 구독 상태 새로고침
  Future<void> refreshSubscriptionStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 먼저 스토어에서 최신 상태 확인
      await _subscriptionService.restorePurchases();

      // 그 다음 구독 상태 갱신
      _status = await _subscriptionService.checkSubscriptionStatus();
    } catch (e) {
      debugPrint('Error refreshing subscription status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 구독 취소 안내 메서드
  Future<bool> navigateToSubscriptionManagement() async {
    return await _subscriptionService.navigateToSubscriptionManagement();
  }
}
