import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// SubscriptionService 및 SubscriptionStatus 경로 수정
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';

class AdManager with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // --- 광고 단위 ID (Google 공식 테스트 ID) ---
  // [✅ 수정] iOS 보상형 전면 ID를 테스트 ID로 수정 (실제 ID는 필요시 적용)

  final String _bannerAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-8274643755495491/2347352963'
          : 'ca-app-pub-8274643755495491/8422310331';
  final String _rewardedInterstitialAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-8274643755495491/8370121247'
          : 'ca-app-pub-8274643755495491/5204181676';

  // --- 배너 광고 위치 식별자 ---
  static const String newsScreenBannerPlacement = 'news_screen_banner';
  static const String rssScreenBannerPlacement = 'rss_screen_banner';
  static const String subscribeScreenBannerPlacement =
      'subscribe_screen_banner';

  // --- 구독 상태 변수 ---
  bool _isLoadingSubscriptionStatus = true;
  bool _isSubscribed = false;
  SubscriptionStatus? _status;

  // --- 배너 광고 상태 변수 ---
  final Map<String, BannerAd?> _bannerAds = {};
  final Map<String, bool> _bannerAdLoadedStatus = {};

  // --- 보상형 전면 광고 상태 변수 ---
  RewardedInterstitialAd? _rewardedInterstitialAd;
  static bool _isRewardedInterstitialAdLoaded = false;

  // ===========================================================================
  // Public Getters
  // ===========================================================================

  bool get isLoadingSubscriptionStatus => _isLoadingSubscriptionStatus;
  bool get isSubscribed => _isSubscribed;
  SubscriptionStatus? get subscriptionStatus => _status;
  bool get showAds {
    if (Platform.isAndroid) {
      return true;
    }
    return !_isLoadingSubscriptionStatus && !_isSubscribed;
  }

  BannerAd? getBannerAd(String placementId) => _bannerAds[placementId];
  bool isBannerAdLoaded(String placementId) =>
      _bannerAdLoadedStatus[placementId] ?? false;
  static bool get isRewardedInterstitialAdLoaded =>
      _isRewardedInterstitialAdLoaded;

  // ===========================================================================
  // Methods
  // ===========================================================================

  Future<void> initialize() async {
    await _checkSubscriptionStatus();
    if (showAds) {
      loadBannerAd(placementId: newsScreenBannerPlacement);
      loadBannerAd(placementId: rssScreenBannerPlacement);
      loadBannerAd(placementId: subscribeScreenBannerPlacement);
      loadRewardedInterstitialAd();
    }
  }

  Future<void> refreshSubscriptionStatus() async {
    await _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    _isLoadingSubscriptionStatus = true;
    notifyListeners();
    try {
      final status = await _subscriptionService.checkSubscriptionStatus();
      _status = status;
      _isSubscribed = status.isActive;
    } catch (e) {
      debugPrint("구독 상태 확인 오류: $e");
      _isSubscribed = false;
    } finally {
      _isLoadingSubscriptionStatus = false;
      // 구독 상태가 변경되었을 수 있으므로 광고 로드 로직 재확인
      if (showAds) {
        // 광고가 아직 로드되지 않았다면 로드 시도
        if (_bannerAds.isEmpty) {
          // 간단한 체크, 더 정교하게 할 수 있음
          loadBannerAd(placementId: newsScreenBannerPlacement);
          loadBannerAd(placementId: rssScreenBannerPlacement);
          loadBannerAd(placementId: subscribeScreenBannerPlacement);
        }
        if (_rewardedInterstitialAd == null &&
            !_isRewardedInterstitialAdLoaded) {
          loadRewardedInterstitialAd();
        }
      } else {
        // 구독자가 되었으면 광고 제거
        if (!Platform.isAndroid) {
          disposeAds(); // 광고 해제 함수 호출 (disposeAds 함수 추가 필요)
        }
      }
      notifyListeners();
    }
  }

  // [✅ 추가] 광고만 해제하는 함수
  void disposeAds() {
    if (Platform.isAndroid) {
      return;
    }
    _bannerAds.forEach((_, ad) {
      ad?.dispose();
    });
    _bannerAds.clear();
    _bannerAdLoadedStatus.clear();
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _isRewardedInterstitialAdLoaded = false;
    debugPrint("AdManager: Ads disposed due to subscription status change.");
    notifyListeners(); // UI 갱신을 위해 호출
  }

  void loadRewardedInterstitialAd() {
    if (!showAds ||
        _rewardedInterstitialAd != null ||
        _isRewardedInterstitialAdLoaded) {
      // 이미 로드되었거나 로딩 중이면 return
      // _isRewardedInterstitialAdLoaded 체크 추가: 로드 성공 후 다시 호출 방지
      return;
    }
    debugPrint("AdManager: Loading RewardedInterstitialAd...");
    // 로드 시도 상태 표시 (선택적)
    // _isRewardedInterstitialAdLoaded = false; // 로드 시도 중임을 명시

    RewardedInterstitialAd.load(
      adUnitId: _rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          debugPrint('AdManager: RewardedInterstitialAd loaded.');
          // 로드 성공 후 광고가 여전히 필요한지(showAds) 다시 확인
          if (showAds) {
            _rewardedInterstitialAd = ad;
            _isRewardedInterstitialAdLoaded = true;
          } else {
            // 로드되는 동안 구독 상태가 바뀌었으면 해제
            ad.dispose();
            _rewardedInterstitialAd = null;
            _isRewardedInterstitialAdLoaded = false;
            debugPrint(
              'AdManager: Discarded loaded RewardedInterstitialAd as ads are no longer needed.',
            );
          }
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint(
            'AdManager: RewardedInterstitialAd failed to load: $error',
          );
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialAdLoaded = false;
          notifyListeners();
        },
      ),
    );
  }

  // [✅ 수정] executeRewardedAction 수정
  Future<void> executeRewardedAction({
    required Future<void> Function() action,
    required VoidCallback onAdDismissedWithoutReward,
    required VoidCallback onAdFailed,
  }) async {
    // 1. 구독자인지 먼저 확인
    if (isSubscribed && !Platform.isAndroid) {
      debugPrint("AdManager: User is subscribed. Executing action directly.");
      await action();
      return;
    }

    // --- 비구독자 로직 ---
    // 2. 지역 변수에 광고 객체와 로드 상태 저장 (안전한 사용 위해)
    final RewardedInterstitialAd? adToShow = _rewardedInterstitialAd;
    final bool isAdCurrentlyLoaded = _isRewardedInterstitialAdLoaded;

    // 3. 광고가 로드되었는지 지역 변수로 확인
    if (isAdCurrentlyLoaded && adToShow != null) {
      debugPrint("AdManager: Rewarded ad is loaded. Showing ad...");
      bool rewardEarned = false;

      adToShow.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {
          debugPrint('AdManager: Ad showed full screen.');
          // 보여준 후에는 로드 상태를 false로 바꿔서 중복 표시 방지
          _isRewardedInterstitialAdLoaded = false;
          _rewardedInterstitialAd = null; // 참조 제거
          notifyListeners();
        },
        onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
          debugPrint('AdManager: Ad dismissed.');
          ad.dispose(); // 콜백에서 받은 ad 객체 dispose
          // _rewardedInterstitialAd 등은 이미 위에서 null 처리됨

          loadRewardedInterstitialAd(); // 다음 광고 미리 로드

          if (rewardEarned) {
            debugPrint("AdManager: Reward earned. Executing action.");
            action(); // 보상 받았으면 액션 실행
          } else {
            debugPrint("AdManager: Ad dismissed without reward.");
            onAdDismissedWithoutReward(); // 보상 못 받음 콜백 호출
          }
        },
        onAdFailedToShowFullScreenContent: (
          RewardedInterstitialAd ad,
          AdError error,
        ) {
          debugPrint('AdManager: Ad failed to show: $error');
          ad.dispose(); // 콜백에서 받은 ad 객체 dispose
          _rewardedInterstitialAd = null; // 참조 제거 확실히
          _isRewardedInterstitialAdLoaded = false; // 로드 상태 false
          notifyListeners();

          loadRewardedInterstitialAd(); // 다음 광고 미리 로드

          onAdFailed(); // 실패 콜백 호출
          action(); // 실패 시에도 액션 실행 (사용자 편의)
        },
      );

      adToShow.setImmersiveMode(true);
      adToShow.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint(
            'AdManager: User earned reward: ${reward.amount} ${reward.type}',
          );
          rewardEarned = true; // 보상 획득!
        },
      );
    } else {
      // 4. 광고가 로드되지 않은 경우 (로딩 중 or 로드 실패)
      debugPrint(
        "AdManager: Rewarded ad is not loaded (isLoaded: $isAdCurrentlyLoaded). Executing action directly after fail callback.",
      );
      onAdFailed(); // 실패 콜백 호출
      await action(); // 액션 실행 (사용자 편의)

      // 광고 로드를 다시 시도 (이미 로딩 중이라면 loadRewardedInterstitialAd 내부에서 중단됨)
      if (!isAdCurrentlyLoaded && _rewardedInterstitialAd == null) {
        loadRewardedInterstitialAd();
      }
    }
  }

  // --- 배너/네이티브 광고 로직 (큰 변경 없음, showAds 체크는 내부에서 함) ---
  void loadBannerAd({required String placementId}) {
    if (!showAds || _bannerAds.containsKey(placementId)) {
      return;
    }
    debugPrint("AdManager: Loading BannerAd for placement: $placementId");
    _bannerAds[placementId] = null;
    _bannerAdLoadedStatus[placementId] = false;
    // notifyListeners(); // 로딩 시작 알림 필요 시

    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('AdManager: BannerAd for $placementId loaded.');
          // 로드 성공 후에도 광고 표시 상태(showAds) 재확인
          if (showAds && _bannerAds.containsKey(placementId)) {
            _bannerAds[placementId] = ad as BannerAd;
            _bannerAdLoadedStatus[placementId] = true;
          } else {
            // 로드 중에 구독 상태 변경 시 광고 해제
            ad.dispose();
            _bannerAds.remove(placementId);
            _bannerAdLoadedStatus.remove(placementId);
            debugPrint(
              'AdManager: Discarded loaded BannerAd for $placementId as ads are no longer needed.',
            );
          }
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('AdManager: BannerAd for $placementId failed: $error');
          ad.dispose();
          // 실패 시에도 map에서 제거하여 재시도 가능하게 함
          _bannerAds.remove(placementId);
          _bannerAdLoadedStatus[placementId] = false;
          notifyListeners(); // 실패 상태 알림 (선택적)
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    disposeAds(); // 모든 광고 해제
    super.dispose();
  }
}
