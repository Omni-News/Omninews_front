import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';
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

    // 현재 페이지를 닫으면서 결과(true) 전달 -> 이전 화면에서 await 후 새로고침 가능
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final status = provider.status;
    final isRecentLogin = _authService.isRecentLogin();
    final availablePlans = provider.availablePlans;

    // 뒤로가기(제스처/버튼) 시에도 결과를 돌려주어 이전 화면이 새로고침할 수 있게 함
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

            // 취소 버튼 추가
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
      // 구독 없음 - 구독 홍보 UI로 변경
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

            // 임시 구독 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleSubscribeTest(context, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text('${'OmniNews 프리미엄(개발용) '} 구독하기'),
              ),
            ),

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
                  '월 ${_formatPrice(plan.price)} · 첫 결제 후 자동 갱신',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  // 혜택 항목 행 위젯
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

  // 구독 처리 메서드 - StoreKit 플랜 사용
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
      // StoreKit에서 가져온 플랜으로 구독 구매 시도
      final success = await provider.purchaseSubscription(plan);

      // 로딩 닫기
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구독 처리 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // 성공 시: (선택) 서버에서 최신 구독 상태 동기화가 필요한 경우 호출
        // await provider.refreshSubscriptionStatus(); // Provider에 메서드가 있다면 사용

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구독이 완료되었습니다. 이전 화면으로 돌아갑니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await Future.delayed(const Duration(milliseconds: 300)); // 스낵바 살짝 노출
        await _onPurchaseSuccess(context);
      }
    } catch (e) {
      // 오류 처리
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

  Future<void> _handleSubscribeTest(
    BuildContext context,
    SubscriptionProvider provider,
  ) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await provider.purchaseSubscriptionTest();

      // 로딩 닫기 (성공/실패 모두 닫기)
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구독 처리 중 오류가 발생했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // 성공 시 동일 처리
        // await provider.refreshSubscriptionStatus(); // 가능하면 최신화
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
      }
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
  String _formatPrice(double price) {
    // 소수점 없는 정수로 표시
    int priceAsInt = price.round();

    // 천 단위 구분자 추가
    String formattedPrice = priceAsInt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return '$formattedPrice원';
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
                const Text(
                  '구독을 취소하려면 앱스토어/구글플레이의 구독 관리 페이지로 이동해야 합니다.',
                  style: TextStyle(fontSize: 14),
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
