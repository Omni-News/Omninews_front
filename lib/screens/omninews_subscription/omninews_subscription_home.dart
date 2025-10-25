import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/screens/webview_screen.dart';
import 'package:omninews_flutter/services/auth_service.dart'; // Keep AuthService import if needed elsewhere, or remove if only used for isRecentLogin
import 'package:provider/provider.dart';
import '../../provider/subscription_provider.dart';

class SubscriptionHomePage extends StatefulWidget {
  const SubscriptionHomePage({Key? key}) : super(key: key);

  @override
  State<SubscriptionHomePage> createState() => _SubscriptionHomePageState();
}

class _SubscriptionHomePageState extends State<SubscriptionHomePage> {
  // final AuthService _authService = AuthService(); // No longer needed for notice logic

  // 구독 변경 여부를 상위 라우트에 전달하기 위한 플래그
  bool _subscriptionChanged = false;

  // 법적 링크 (SettingsScreen과 동일한 URL 사용)
  static const String eulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/omninews/%ED%99%88';

  @override
  void initState() {
    super.initState();
  }

  // 구매 성공 후 공통 처리: 플래그 세팅 후 이전 화면으로 true 전달
  Future<void> _onPurchaseSuccess(BuildContext context) async {
    if (!mounted) return;
    setState(() {
      _subscriptionChanged = true;
    });
    // [✅ 수정] pop(true) -> pop(_subscriptionChanged)로 변경 (일관성)
    Navigator.of(context).pop(_subscriptionChanged);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionProvider>(context);
    final status = provider.status;
    // final isRecentLogin = _authService.isRecentLogin(); // No longer needed for notice logic
    final availablePlans = provider.availablePlans;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_subscriptionChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('구독 관리'), centerTitle: true),
        body:
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [✅ 수정] if 조건 제거, 항상 표시
                        _buildAccountSubscriptionNotice(),
                        const SizedBox(height: 16), // 공지 카드와 상태 카드 사이 간격 추가
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
      ),
    );
  }

  // [✅ 수정] 계정 구독 안내 카드 (isRecentLogin 조건 제거 및 문구 수정)
  Widget _buildAccountSubscriptionNotice() {
    return Semantics(
      label: '구독 계정 안내', // 라벨 변경
      child: Container(
        // margin 제거 (위젯 호출 시 SizedBox로 간격 조정)
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50, // 색상 변경 (정보성)
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200), // 색상 변경
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: Colors.blue.shade800,
                ), // 아이콘 변경
                const SizedBox(width: 8),
                Text(
                  '구독 계정 안내', // 타이틀 변경
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade900, // 색상 변경
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              // 문구 수정
              '구독 정보는 각 계정별로 관리됩니다. 만약 다른 계정으로 구독하셨다면, 해당 계정으로 로그인하여 구독 상태를 확인하고 서비스를 이용해주세요.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              // 문구 수정 (강조)
              '현재 계정으로 구독 시 별도 요금이 부과될 수 있습니다.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue.shade900, // 색상 변경
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- _buildStatusCard 및 이하 코드는 변경 없음 ---
  Widget _buildStatusCard(
    BuildContext context,
    SubscriptionStatus status,
    SubscriptionProvider provider,
    List<SubscriptionPlan> availablePlans,
  ) {
    final theme = Theme.of(context);

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
              color: theme.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
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
                  style: theme.textTheme.headlineSmall?.copyWith(
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

            // 상세 정보 및 약관 (토글)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  '상세 정보 및 약관',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                children: [
                  const SizedBox(height: 8),
                  _infoRow(
                    '상품',
                    status.productId?.toString().isNotEmpty == true
                        ? '${status.productId}'
                        : 'OmniNews 프리미엄',
                  ),
                  const SizedBox(height: 6),
                  _infoRow('만료일', _formatDate(status.expiryDate)),
                  const SizedBox(height: 12),
                  _buildTermsContent(context, null), // plan 없이 공통 약관/링크 표시
                ],
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '모든 프리미엄 기능을 이용할 수 있습니다.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
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

            // 도움말 및 설정(복원 포함) - 토글
            const SizedBox(height: 8),
            _buildSupportAndRestoreTile(context, provider),
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
              color: theme.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 혜택 (항상 펼침)
            Text(
              '프리미엄 혜택',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            _buildBenefitRow('광고 없는 뉴스 읽기'),
            _buildBenefitRow('모든 프리미엄 콘텐츠 이용'),
            _buildBenefitRow('AI 맞춤 뉴스 추천'),
            const SizedBox(height: 8),

            if (plan != null) ...[
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
                  '월 ${_formatPriceDisplay(plan)} · 자동 갱신',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 12),

              // 구독 정보 및 약관 (토글)
              _buildTermsAndLinksTile(context, plan),

              // 도움말 및 설정(복원 포함) - 토글
              const SizedBox(height: 8),
              _buildSupportAndRestoreTile(context, provider),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                '상품 정보를 불러올 수 없습니다. 네트워크 상태 또는 스토어 설정을 확인한 뒤 다시 시도해 주세요.',
                style: TextStyle(color: Colors.red.shade700),
              ),
              // 상품 정보 없을 때도 복원 버튼은 표시
              const SizedBox(height: 8),
              _buildSupportAndRestoreTile(context, provider),
            ],
          ],
        ),
      );
    }
  }

  // --- 이하 Helper Widgets 및 Functions (변경 없음) ---
  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text('$label: ', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndLinksTile(BuildContext context, SubscriptionPlan plan) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          '구독 정보 및 약관',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
        children: [
          const SizedBox(height: 4),
          _buildTermsContent(context, plan),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context, SubscriptionPlan? plan) {
    final theme = Theme.of(context);
    final price = plan == null ? null : _formatPriceDisplay(plan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan != null)
          Text(
            '구독 정보',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        if (plan != null) const SizedBox(height: 6),
        if (plan != null) _bullet('구독 기간: 1개월(자동 갱신)'),
        if (plan != null && price != null) _bullet('가격: $price/월'),
        _bullet('결제는 Apple ID로 청구됩니다.'),
        _bullet('현재 기간 종료 최소 24시간 전에 취소하지 않으면 자동으로 갱신됩니다.'),
        _bullet('갱신 시점 24시간 이내에 다음 기간 요금이 청구됩니다.'),
        _bullet('구매 후 언제든지 App Store 계정 설정에서 관리 및 취소할 수 있습니다.'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => const WebViewScreen(
                          url: eulaUrl,
                          title: '이용약관(EULA)',
                        ),
                  ),
                );
              },
              child: const Text('이용약관(EULA)'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => const WebViewScreen(
                          url: privacyPolicyUrl,
                          title: '개인정보처리방침',
                        ),
                  ),
                );
              },
              child: const Text('개인정보처리방침'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportAndRestoreTile(
    BuildContext context,
    SubscriptionProvider provider,
  ) {
    final theme = Theme.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          '도움말 및 설정',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        children: [
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restore),
            title: const Text('구매 복원'),
            subtitle: const Text('이전에 결제한 구독을 복원합니다.'),
            onTap: () async {
              final ok = await provider.restorePurchases();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '구매 내역을 복원했습니다.' : '복원에 실패했습니다.'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
              // 복원 성공 시 상태 변경 알림
              if (ok) {
                setState(() => _subscriptionChanged = true);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
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

  Widget _buildBenefitRow(String benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Color(0xFF1565C0), // Consistent blue color
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _extractEmail(String text) {
    final parts = text.split(": ");
    if (parts.length >= 3) {
      String email = parts.last.trim();
      email = email.replaceAll("\"}", "").replaceAll("\"", "");
      return email;
    }
    final emailPattern = RegExp(r'[\w.+\-]+@[\w\-]+\.[a-zA-Z0-9\-.]+');
    final match = emailPattern.firstMatch(text);
    return match != null ? match.group(0)! : '';
  }

  Future<void> _showAlreadyExistsDialog(
    BuildContext context,
    SubscriptionProvider provider,
    String email,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이미 다른 계정에서 구독 중'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이미 다른 계정($email)에서 구독 중입니다.\n\n'
                  '해당 계정으로 전환하여 사용하거나, 기존 구독을 취소한 뒤 현재 계정으로 다시 구독해주세요.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  await AuthService().signOut();
                  if (!mounted) return;
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('계정 전환하기'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await provider.navigateToSubscriptionManagement();
                },
                child: const Text('구독 관리로 이동'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleSubscribe(
    BuildContext context,
    SubscriptionProvider provider,
    SubscriptionPlan plan,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final started = await provider.purchaseSubscription(plan);
      if (!started && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await _showSubscriptionExpiredDialog(context, provider, plan);
        return;
      }

      final result = await provider.waitForPurchaseResult(plan.id);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!result.success) {
        if (mounted) {
          final errorMsg = result.message ?? '';
          if (errorMsg.contains('Already exists element') &&
              errorMsg.contains('existing user')) {
            final email = _extractEmail(errorMsg);
            await _showAlreadyExistsDialog(context, provider, email);
          } else if (_isExpiredError(errorMsg)) {
            await _showSubscriptionExpiredDialog(context, provider, plan);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('서버 검증에 실패하여 구독이 처리되지 않았습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독이 완료되었습니다. 이전 화면으로 돌아갑니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await _onPurchaseSuccess(context); // This will pop with true
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독 처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSubscriptionExpiredDialog(
    BuildContext context,
    SubscriptionProvider provider,
    SubscriptionPlan plan,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('구독이 만료되었습니다'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이전 구독이 만료되었습니다.\n\n'
                  '새로운 구독을 시작하려면 다음 방법 중 하나를 선택해주세요:',
                ),
                const SizedBox(height: 16),
                Container(
                  // 방법 1
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.blue.shade800),
                          const SizedBox(width: 8),
                          Text(
                            '방법 1: 구독 복원 시도',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '먼저 구독 복원을 시도해 보세요. 이전에 구독한 내역이 있다면 복원될 수 있습니다.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  // 방법 2
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.store, color: Colors.green.shade800),
                          const SizedBox(width: 8),
                          Text(
                            '방법 2: 구독 관리 페이지',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Platform.isIOS
                            ? '앱스토어 구독 관리 페이지에서 이전 구독을 확인하고 재구독할 수 있습니다.'
                            : '구글플레이 구독 관리 페이지에서 이전 구독을 확인하고 재구독할 수 있습니다.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final ok = await provider.restorePurchases();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? '구독 내역을 확인 중입니다...' : '구독 복원 시도 중 문제가 발생했습니다.',
                      ),
                      backgroundColor: ok ? Colors.blue : Colors.red,
                    ),
                  );
                  // 복원 성공 시 상태 변경 알림
                  if (ok) {
                    setState(() => _subscriptionChanged = true);
                  }
                },
                child: const Text('구독 복원 시도'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await provider.navigateToSubscriptionManagement();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                child: const Text('구독 관리 페이지로 이동'),
              ),
            ],
          ),
    );
  }

  bool _isExpiredError(String errorMsg) {
    final lowerMsg = errorMsg.toLowerCase();
    return lowerMsg.contains('expired') ||
        lowerMsg.contains('ended') ||
        lowerMsg.contains('subscription ended') ||
        lowerMsg.contains('만료') ||
        lowerMsg.contains('기간이 지났') ||
        lowerMsg.contains('종료');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '알 수 없음';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatPriceDisplay(SubscriptionPlan plan) {
    final currencyCode = (plan.currencyCode ?? '').toUpperCase();
    final priceString = plan.priceString;

    if (priceString != null && priceString.trim().isNotEmpty) {
      return priceString;
    }

    if (currencyCode == 'KRW') {
      final formatter = NumberFormat.currency(
        locale: 'ko_KR',
        symbol: '원',
        decimalDigits: 0,
      );
      return formatter.format(plan.price);
    }

    final generic = NumberFormat.simpleCurrency(
      name: currencyCode.isEmpty ? null : currencyCode,
    );
    return generic.format(plan.price);
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
                Text(
                  Platform.isIOS
                      ? '구독을 취소하려면 App Store의 구독 관리 페이지로 이동해야 합니다.'
                      : '구독을 취소하려면 Google Play 스토어의 구독 관리 페이지로 이동해야 합니다.',
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
                    'Google Play 스토어 > 계정 > 결제 및 구독에서 구독을 취소할 수 있습니다.',
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
} // End of _SubscriptionHomePageState
