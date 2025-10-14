import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/screens/webview_screen.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:provider/provider.dart';

import '../../provider/subscription_provider.dart';

class SubscriptionHomePage extends StatefulWidget {
  const SubscriptionHomePage({Key? key}) : super(key: key);

  @override
  State<SubscriptionHomePage> createState() => _SubscriptionHomePageState();
}

class _SubscriptionHomePageState extends State<SubscriptionHomePage> {
  final AuthService _authService = AuthService();

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
      ),
    );
  }

  // 계정 전환 알림 카드
  Widget _buildAccountSwitchNotice() {
    return Semantics(
      label: '계정 전환 알림',
      child: Container(
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
      ),
    );
  }

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
            ],
          ],
        ),
      );
    }
  }

  // 간단한 라벨:값 행
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

  // '구독 정보 및 약관' 토글 (비구독 상태에서 사용)
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

  // 약관/고지 내용 (공통)
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
        // 중요 고지
        if (plan != null) _bullet('구독 기간: 1개월(자동 갱신)'),
        if (plan != null && price != null) _bullet('가격: $price/월'),
        // 요청사항: Google 문구 제거
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

  // 도움말 및 설정(복원 포함) 토글
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
            color: Color(0xFF1565C0),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // 이메일 추출 패턴
  String _extractEmail(String text) {
    // "Already exists element: existing user: omninews1027+1@gmail.com"} 형태에서
    // 마지막 ': ' 이후 부분을 이메일로 간주
    final parts = text.split(": ");
    if (parts.length >= 3) {
      // 마지막 부분에서 "}"나 다른 잡문자 제거
      String email = parts.last.trim();

      // "}"와 같은 JSON 관련 문자 제거
      email = email.replaceAll("\"}", "").replaceAll("\"", "");

      return email;
    }

    // 스플릿이 잘 안 되었거나 다른 형식인 경우를 위한 백업
    final emailPattern = RegExp(r'[\w.+\-]+@[\w\-]+\.[a-zA-Z0-9\-.]+');
    final match = emailPattern.firstMatch(text);
    return match != null ? match.group(0)! : '';
  }

  // 이미 다른 계정으로 구독 중인 경우 다이얼로그
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
                  // 계정 전환 선택 시 로그아웃 처리
                  await AuthService().signOut();
                  if (!mounted) return;

                  // 모든 화면을 제거하고 HomeScreen으로 이동
                  // HomeScreen은 로그인 상태가 아니므로 LoginScreen을 표시함
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);

                  // 또는 아래와 같이 직접 라우트 생성 (HomeScreen 코드 참조)
                  /*
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false, // 모든 이전 라우트 제거
            );
            */
                },
                child: const Text('계정 전환하기'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // 구독 관리 페이지로 이동
                  Navigator.of(context).pop();
                  await provider.navigateToSubscriptionManagement();
                },
                child: const Text('구독 관리로 이동'),
              ),
            ],
          ),
    );
  }

  // 구독 처리 메서드 - 최종 결과(purchaseResultStream)를 기다려 성공/실패 결정
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

          // 구매창이 뜨지 않은 경우 이전 구독이 있을 가능성이 높음
          await _showSubscriptionExpiredDialog(context, provider, plan);
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
          final errorMsg = result.message ?? '';

          // 2-1. 에러 메시지가 "Already exists element: existing user:" 패턴을 포함하는지 확인
          if (errorMsg.contains('Already exists element') &&
              errorMsg.contains('existing user')) {
            // 이메일 추출
            final email = _extractEmail(errorMsg);

            // 2-1-1. 다른 계정 구독 중 다이얼로그 표시
            await _showAlreadyExistsDialog(context, provider, email);
          }
          // 2-2. 만료 관련 에러인지 확인
          else if (_isExpiredError(errorMsg)) {
            // 2-2-1. 만료 안내 다이얼로그 표시
            await _showSubscriptionExpiredDialog(context, provider, plan);
          }
          // 2-3. 그 외 일반 오류
          else {
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
          const SnackBar(
            content: Text('구독 처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 만료된 구독에 대한 안내 다이얼로그
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

                // 방법 1: 구독 초기화 시도
                Container(
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

                // 방법 2: 스토어 관리 페이지
                Container(
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
                  // 방법 1: 구독 복원 시도
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
                },
                child: const Text('구독 복원 시도'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // 방법 2: 구독 관리 페이지로 이동
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

  // 만료 관련 에러인지 확인하는 함수
  bool _isExpiredError(String errorMsg) {
    final lowerMsg = errorMsg.toLowerCase();
    // 만료 관련 키워드 체크
    return lowerMsg.contains('expired') ||
        lowerMsg.contains('ended') ||
        lowerMsg.contains('subscription ended') ||
        lowerMsg.contains('만료') ||
        lowerMsg.contains('기간이 지났') ||
        lowerMsg.contains('종료');
  }

  // 날짜 포맷팅
  String _formatDate(DateTime? date) {
    if (date == null) return '알 수 없음';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 가격 포맷팅
  String _formatPriceDisplay(SubscriptionPlan plan) {
    final currencyCode = (plan.currencyCode ?? '').toUpperCase();
    final priceString = plan.priceString;

    // 스토어가 제공한 포맷이 있으면 우선 사용 (예: '$1.99', '€2,29', '¥240')
    if (priceString != null && priceString.trim().isNotEmpty) {
      return priceString;
    }

    // KRW는 소수점 없이 천 단위 구분 + "원"
    if (currencyCode == 'KRW') {
      final formatter = NumberFormat.currency(
        locale: 'ko_KR',
        symbol: '원',
        decimalDigits: 0,
      );
      return formatter.format(plan.price);
    }

    // 그 외 통화는 심플 포맷
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
                // 플랫폼별 문구
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
}
