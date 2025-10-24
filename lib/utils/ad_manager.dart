import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// SubscriptionService 및 SubscriptionStatus 경로 수정
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';

class AdManager with ChangeNotifier {
  // [✅ 수정] 클래스명 변경 반영 (만약 SubscriptionService 클래스명이 다르다면 맞춰주세요)
  final SubscriptionService _subscriptionService = SubscriptionService();

  // --- 광고 단위 ID (실제 ID로 변경 필요) ---
  final String _nativeAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110' // Android 네이티브 테스트 ID
          : 'ca-app-pub-8274643755495491/6309338228'; // iOS 네이티브 테스트 ID
  final String _bannerAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android 배너 테스트 ID
          : 'ca-app-pub-8274643755495491/8422310331'; // iOS 배너 테스트 ID

  // --- [✅ 추가] 배너 광고 위치 식별자 ---
  static const String newsScreenBannerPlacement = 'news_screen_banner';
  static const String rssScreenBannerPlacement = 'rss_screen_banner';
  // 필요하다면 다른 위치 ID 추가...

  // --- 구독 상태 변수 ---
  bool _isLoadingSubscriptionStatus = true;
  bool _isSubscribed = false;
  SubscriptionStatus? _status;

  // --- [✅ 수정] 배너 광고 상태 변수 (Map으로 복원) ---
  final Map<String, BannerAd?> _bannerAds = {}; // Placement ID -> BannerAd
  final Map<String, bool> _bannerAdLoadedStatus = {}; // Placement ID -> 로드 상태

  // ===========================================================================
  // Public Getters
  // ===========================================================================

  bool get isLoadingSubscriptionStatus => _isLoadingSubscriptionStatus;
  bool get isSubscribed => _isSubscribed;
  SubscriptionStatus? get subscriptionStatus => _status;
  bool get showAds => !_isLoadingSubscriptionStatus && !_isSubscribed;

  // --- [✅ 수정] 배너 광고 Getters (placementId 사용) ---
  /// 특정 위치의 배너 광고 객체 가져오기
  BannerAd? getBannerAd(String placementId) => _bannerAds[placementId];

  /// 특정 위치의 배너 광고 로드 완료 여부 가져오기
  bool isBannerAdLoaded(String placementId) =>
      _bannerAdLoadedStatus[placementId] ?? false;

  // ===========================================================================
  // Methods
  // ===========================================================================

  Future<void> initialize() async {
    await _checkSubscriptionStatus();
    if (showAds) {
      // [✅ 수정] 각 위치별 배너 광고 로드 시작
      loadBannerAd(placementId: newsScreenBannerPlacement);
      loadBannerAd(placementId: rssScreenBannerPlacement);
      // 필요하다면 다른 배너 광고도 미리 로드...
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    _isLoadingSubscriptionStatus = true;
    notifyListeners();
    try {
      final status = await _subscriptionService.checkSubscriptionStatus();
      _status = status;
      _isSubscribed = status.isActive;
      _isSubscribed = false; // 테스트용 임시 하드코딩
    } catch (e) {
      debugPrint("구독 상태 확인 오류: $e");
      _isSubscribed = false;
    } finally {
      _isLoadingSubscriptionStatus = false;
      notifyListeners();
    }
  }

  /// [✅ 유지] 요청 시 새로운 네이티브 광고를 로드하고 Future로 반환
  Future<NativeAd?> loadNewNativeAd() async {
    if (!showAds) {
      debugPrint("AdManager: Ads disabled. Skipping native ad load.");
      return null;
    }
    final Completer<NativeAd?> completer = Completer<NativeAd?>();
    debugPrint("AdManager: Attempting to load NativeAd ID: $_nativeAdUnitId");
    NativeAd(
      adUnitId: _nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('AdManager: New NativeAd loaded.');
          if (!completer.isCompleted)
            completer.complete(ad as NativeAd);
          else
            ad.dispose();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('AdManager: Failed to load new NativeAd: $error');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(null);
        },
        onAdClicked: (Ad ad) => debugPrint('Ad clicked.'),
        onAdImpression: (Ad ad) => debugPrint('Ad impression.'),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    ).load();
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint("AdManager: NativeAd loading timed out.");
        if (!completer.isCompleted) completer.complete(null);
        return null;
      },
    );
  }

  /// [✅ 수정] 특정 위치 ID에 대한 배너 광고 로드
  void loadBannerAd({required String placementId}) {
    if (!showAds || _bannerAds.containsKey(placementId)) {
      // 이미 로드 요청/완료되었거나 광고 표시 안 함 상태면 중복 로드 방지
      return;
    }

    debugPrint("AdManager: Loading BannerAd for placement: $placementId");

    // 로딩 시작 상태 표시
    _bannerAds[placementId] = null;
    _bannerAdLoadedStatus[placementId] = false;
    // notifyListeners(); // 필요 시 로딩 시작 알림

    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('AdManager: BannerAd for $placementId loaded.');
          // AdManager가 아직 살아있을 때만 Map 업데이트
          if (!_isLoadingSubscriptionStatus &&
              _bannerAds.containsKey(placementId)) {
            _bannerAds[placementId] = ad as BannerAd;
            _bannerAdLoadedStatus[placementId] = true;
            notifyListeners();
          } else {
            // 이미 dispose 되었거나, 로드 요청이 취소된 경우 광고 해제
            ad.dispose();
            debugPrint(
              'AdManager: Disposing loaded BannerAd for $placementId as manager might be disposed.',
            );
            _bannerAds.remove(placementId); // 맵에서도 제거
            _bannerAdLoadedStatus.remove(placementId);
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('AdManager: BannerAd for $placementId failed: $error');
          ad.dispose();
          // AdManager가 아직 살아있을 때만 Map 업데이트 (실패 상태 반영)
          if (!_isLoadingSubscriptionStatus &&
              _bannerAds.containsKey(placementId)) {
            _bannerAds.remove(placementId); // 실패 시 제거 (재로드 가능)
            _bannerAdLoadedStatus[placementId] = false;
            notifyListeners(); // 실패 상태 알림 (선택적)
          } else {
            // 이미 dispose된 경우
            _bannerAds.remove(placementId);
            _bannerAdLoadedStatus.remove(placementId);
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    // [✅ 수정] Map에 있는 모든 배너 광고 dispose
    _bannerAds.forEach((_, ad) {
      ad?.dispose();
    });
    _bannerAds.clear();
    _bannerAdLoadedStatus.clear();
    super.dispose();
  }
}
