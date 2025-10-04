import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../provider/subscription_provider.dart';

class SubscriptionHomePage extends StatefulWidget {
  const SubscriptionHomePage({Key? key}) : super(key: key);

  @override
  _SubscriptionHomePageState createState() => _SubscriptionHomePageState();
}

class _SubscriptionHomePageState extends State<SubscriptionHomePage> {
  final AuthService _authService = AuthService();

  // 구독 변경 여부를 상위 라우트에 전달하기 위한 플래그
  bool _subscriptionChanged = false;

  // 법적 링크 (SettingsScreen과 동일하게 유지)
  static const String eulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/omninews/%ED%99%88';

  @override
  void initState() {
    super.initState();
  }

  // 구매 성공 후 공통 처리: 로컬 상태 플래그 세팅, 스낵바, 현재 화면 종료(+결과 전달)
  Future<void> _onPurchaseSuccess(BuildContext context) async {
    if (!mounted) return;
    setState(() {
      _subscriptionChanged = true;
    });
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final status = provider.status;
    final isRecentLogin = _authService.isRecentLogin();
    final availablePlans = provider.availablePlans;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_subscriptionChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('구독 관리')),
        body:
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecentLogin) _buildAccountSwitchNotice(),
                      _buildStatusCard(
                        context,
                        status,
                        provider,
                        availablePlans,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  // 계정 전환 알림 카드
  Widget _buildAccountSwitchNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Text(
                '계정 전환 알림',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '다른 계정으로 로그인하셨습니다. 구독은 각 계정마다 별도로 관리됩니다. '
            '이전 계정의 구독 상태는 이전 계정으로 다시 로그인하면 확인할 수 있습니다.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '새 계정으로 구독 시 별도 요금이 부과될 수 있습니다.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    SubscriptionStatus status,
    SubscriptionProvider provider,
    List<SubscriptionPlan> availablePlans,
  ) {
    if (status.isActive) {
      // 구독 중
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  '구독 중',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '프리미엄',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('상품: '),
                Text(
                  '${status.productId ?? 'OmniNews 프리미엄'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('만료일: '),
                Text(
                  _formatDate(status.expiryDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('모든 프리미엄 기능을 이용할 수 있습니다.'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showCancellationDialog(context),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('구독 관리'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade300),
              ),
            ),
          ],
        ),
      );
    } else {
      // 구독 없음 - 구독 홍보 UI
      final plan = availablePlans.isNotEmpty ? availablePlans.first : null;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_border_rounded,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '프리미엄으로 업그레이드',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '프리미엄 혜택:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildBenefitRow('광고 없는 뉴스 읽기'),
            _buildBenefitRow('모든 프리미엄 콘텐츠 이용'),
            _buildBenefitRow('AI 맞춤 뉴스 추천'),
            _buildBenefitRow('오프라인 저장 및 읽기'),
            const SizedBox(height: 20),
            if (plan != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleSubscribe(context, provider, plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text('${plan.name} 구독하기'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  // KRW면 “2,200원”, 그 외 통화는 스토어 표시 문자열 그대로 사용
                  '월 ${_formatPriceDisplay(plan)} · 자동 갱신',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              _buildSubscriptionTermsAndLinks(plan),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await provider.restorePurchases();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? '구매 내역을 복원했습니다.' : '복원에 실패했습니다.'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.restore),
                label: const Text('구매 복원'),
              ),
            ] else ...[
              // 상품이 비어 있을 때 사용자 안내
              const SizedBox(height: 8),
              Text(
                '상품 정보를 불러올 수 없습니다. 네트워크 상태 또는 스토어 설정을 확인한 뒤 다시 시도해 주세요.',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildSubscriptionTermsAndLinks(SubscriptionPlan plan) {
    final price = _formatPriceDisplay(plan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필수 고지(구독 기간/가격/자동갱신/청구/관리)
        Text(
          '구독 정보',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 6),
        _bullet('구독 기간: 1개월(자동 갱신)'),
        _bullet('가격: $price/월'),
        _bullet('결제는 Apple ID로 청구됩니다.'),
        _bullet('현재 기간 종료 최소 24시간 전에 취소하지 않으면 자동으로 갱신됩니다.'),
        _bullet('갱신 시점 24시간 이내에 다음 기간 요금이 청구됩니다.'),
        _bullet('구매 후 언제든지 App Store 계정 설정에서 관리 및 취소할 수 있습니다.'),
        const SizedBox(height: 8),
        // 법적 링크
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () => _openExternal(eulaUrl),
              child: const Text('이용약관(EULA)'),
            ),
            TextButton(
              onPressed: () => _openExternal(privacyPolicyUrl),
              child: const Text('개인정보처리방침'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const Text('•  '), Expanded(child: Text(text))],
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // 실패해도 조용히 무시
    }
  }

  Widget _buildBenefitRow(String benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.blue.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // 구독 처리 메서드 - 최종 결과(purchaseResultStream)를 기다려 성공/실패 결정
  Future<void> _handleSubscribe(
    BuildContext context,
    SubscriptionProvider provider,
    SubscriptionPlan plan,
  ) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1) 구매 플로우 시작
      final started = await provider.purchaseSubscription(plan);
      if (!started) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // 로딩 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구독 결제를 시작할 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2) 최종 결과(스토어 콜백 + 서버 검증)를 기다림
      final result = await provider.waitForPurchaseResult(plan.id);

      // 로딩 닫기
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? '구독 등록에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 성공 UX
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독이 완료되었습니다. 이전 화면으로 돌아갑니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await _onPurchaseSuccess(context);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // 로딩 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 날짜 포맷팅
  String _formatDate(DateTime? date) {
    if (date == null) return '알 수 없음';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 가격 포맷팅
  String _formatPriceDisplay(SubscriptionPlan plan) {
    if ((plan.currencyCode ?? '').toUpperCase() == 'KRW') {
      // KRW: 소수점 없이 천 단위 구분 + "원"
      final priceAsInt = plan.price.round(); // rawPrice가 2200.0 → 2200
      final formatted = priceAsInt.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$formatted원';
    }
    // 기타 통화: 스토어가 준 문자열을 그대로(예: '$1.99', '€2,29', '¥240')
    return plan.priceString ?? plan.price.toString();
  }

  void _showCancellationDialog(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('구독 관리'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 플랫폼별로 문구 분리: iOS 빌드에서 Google Play 언급 제거
                Text(
                  Platform.isIOS
                      ? '구독을 취소하려면 앱스토어의 구독 관리 페이지로 이동해야 합니다.'
                      : '구독을 취소하려면 구글 플레이 스토어의 구독 관리 페이지로 이동해야 합니다.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (Platform.isIOS)
                  const Text(
                    '설정 앱 > Apple ID > 구독에서 구독을 취소할 수 있습니다.',
                    style: TextStyle(fontSize: 14),
                  ),
                if (Platform.isAndroid)
                  const Text(
                    '구글 플레이 스토어 > 계정 > 결제 및 구독에서 구독을 취소할 수 있습니다.',
                    style: TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 12),
                const Text(
                  '구독을 취소해도 현재 결제 기간이 끝날 때까지는 프리미엄 기능을 계속 이용할 수 있습니다.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  provider.navigateToSubscriptionManagement();
                },
                child: const Text('구독 관리로 이동'),
              ),
            ],
          ),
    );
  }
}
