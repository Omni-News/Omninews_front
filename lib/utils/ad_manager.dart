import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';

class AdManager with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // --- 광고 단위 ID (테스트 ID) ---
  // TODO: 실제 Ad Unit ID로 변경
  final String _nativeAdUnitId =
      Platform.isAndroid ? '' : 'ca-app-pub-8274643755495491/6309338228';
  final String _bannerAdUnitId =
      Platform.isAndroid ? '' : 'ca-app-pub-8274643755495491/8422310331';

  // --- 구독 상태 변수 ---
  bool _isLoadingSubscriptionStatus = true;
  bool _isSubscribed = false;
  SubscriptionStatus? _status;

  // --- [✅ 수정] 네이티브 광고 상태 변수 (List로 변경) ---
  static const int _maxNativeAds = 1; // 로드할 네이티브 광고 개수
  final List<NativeAd> _nativeAds = [];
  bool _areNativeAdsLoading = false;

  // --- 배너 광고 상태 변수 ---
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ===========================================================================
  // Public Getters
  // ===========================================================================

  bool get isLoadingSubscriptionStatus => _isLoadingSubscriptionStatus;
  bool get isSubscribed => _isSubscribed;
  SubscriptionStatus? get subscriptionStatus => _status;
  bool get showAds => !_isLoadingSubscriptionStatus && !_isSubscribed;

  // --- [✅ 수정] 네이티브 광고 Getters ---
  /// 로드에 성공한 네이티브 광고 목록
  List<NativeAd> get nativeAds => _nativeAds;

  /// 네이티브 광고가 (적어도 1개) 로드되었는지 여부
  bool get areNativeAdsLoaded => _nativeAds.isNotEmpty;

  // --- 배너 광고 Getters ---
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  // ===========================================================================
  // Methods
  // ===========================================================================

  Future<void> initialize() async {
    await _checkSubscriptionStatus();

    if (showAds) {
      loadNativeAds(); // [✅ 수정]
      loadBannerAd();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    _isLoadingSubscriptionStatus = true;
    notifyListeners();

    final status = await _subscriptionService.checkSubscriptionStatus();
    _status = status;
    // TODO: 이따 복원
    //_isSubscribed = status.isActive;
    _isSubscribed = false;

    _isLoadingSubscriptionStatus = false;
    notifyListeners();
  }

  // --- [✅ 수정] 네이티브 광고 로드 (여러 개) ---
  void loadNativeAds() {
    if (_areNativeAdsLoading || _nativeAds.isNotEmpty || !showAds) {
      return;
    }
    _areNativeAdsLoading = true;

    for (int i = 0; i < _maxNativeAds; i++) {
      NativeAd(
        adUnitId: _nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            debugPrint('AdManager: NativeAd loaded (Instance ${i + 1}).');
            _nativeAds.add(ad as NativeAd);
            // 모든 광고 로드가 완료되었는지 확인
            if (_nativeAds.length == _maxNativeAds) {
              _areNativeAdsLoading = false;
              notifyListeners();
            }
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint(
              'AdManager: NativeAd failed to load (Instance ${i + 1}): $error',
            );
            ad.dispose();
            // 실패하더라도 로딩 상태는 해제 (모든 시도가 끝났을 때)
            if (i == _maxNativeAds - 1 && _nativeAds.isEmpty) {
              _areNativeAdsLoading = false;
              notifyListeners();
            }
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
        ),
      ).load();
    }
  }

  // --- 배너 광고 로드 (변경 없음) ---
  void loadBannerAd() {
    if (_isBannerAdLoaded || _bannerAd != null || !showAds) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('AdManager: BannerAd loaded.');
          _bannerAd = ad as BannerAd;
          _isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('AdManager: BannerAd failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
          notifyListeners();
        },
      ),
    )..load();
  }

  Future<NativeAd?> loadNewNativeAd() async {
    // 광고 표시 안 함 상태면 null 반환
    if (!showAds) {
      return null;
    }

    final Completer<NativeAd?> completer = Completer<NativeAd?>();

    NativeAd? nativeAd; // 콜백 내에서 참조하기 위해 변수 선언

    nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('AdManager: New NativeAd loaded successfully.');
          completer.complete(ad as NativeAd); // 로드 성공 시 광고 객체 반환
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('AdManager: Failed to load new NativeAd: $error');
          ad.dispose(); // 실패 시 광고 객체 해제
          completer.complete(null); // 로드 실패 시 null 반환
        },
        // --- 기타 콜백 (클릭, 노출 등) ---
        onAdClicked: (Ad ad) => debugPrint('Ad clicked.'),
        onAdImpression: (Ad ad) => debugPrint('Ad impression.'),
        // ... 필요한 다른 콜백 추가 ...
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium, // 필요에 따라 템플릿 변경
      ),
    )..load();

    return completer.future; // 광고 로드 결과를 기다리는 Future 반환
  }

  @override
  void dispose() {
    for (var ad in _nativeAds) {
      ad.dispose();
    }
    _bannerAd?.dispose();
    super.dispose();
  }
}
