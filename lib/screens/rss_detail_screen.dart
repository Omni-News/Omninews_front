import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:provider/provider.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart';
import 'package:omninews_flutter/services/rss_service.dart';

// Premium gating 관련 import (RssAddScreen과 동일한 서비스/모델 사용)
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/omninews_subscription/omninews_subscription_service.dart';
import 'package:omninews_flutter/screens/omninews_subscription/omninews_subscription_home.dart';
import 'package:share_plus/share_plus.dart';

class RssDetailScreen extends StatefulWidget {
  final RssItem rssItem;
  final RssChannel? channel; // 채널 정보는 옵션

  const RssDetailScreen({super.key, required this.rssItem, this.channel});

  @override
  State<RssDetailScreen> createState() => _RssDetailScreenState();
}

class _RssDetailScreenState extends State<RssDetailScreen> {
  // 요약 상태
  String? _summary;
  String? _error;
  bool _loading = false;

  // 프리미엄 구독 상태
  SubscriptionStatus? _subscriptionStatus;
  bool _isCheckingSubscription = true;

  // 채널 해석 상태 (widget.channel이 없을 때 서버에서 구독 채널 목록을 가져와 매칭)
  RssChannel? _resolvedChannel;
  bool _resolvingChannel = false;

  bool get _isPremiumActive => _subscriptionStatus?.isActive == true;

  // Instagram / Naver Blog 생성 채널은 요약 버튼/기능 숨김
  // 1) channel.rssGenerator 기준
  // 2) 채널 미해결 시 아이템 링크 도메인 기준 보조판정
  bool get _hideSummaryFeature {
    final gen =
        (_resolvedChannel?.rssGenerator ?? widget.channel?.rssGenerator ?? '')
            .toLowerCase();
    final host = _hostOf(widget.rssItem.rssLink);

    final hideByGen =
        gen == 'omninews_instagram' ||
        gen == 'omninews_naver' ||
        gen.contains('instagram') ||
        gen.contains('naver') ||
        gen.contains('naver blog');

    final hideByDomain =
        host.contains('instagram.com') ||
        host.contains('naver.com') ||
        host.contains('blog.naver.com');

    final hide = hideByGen || hideByDomain;
    // 디버깅 로그
    debugPrint(
      '🔵 생성기: "$gen", 호스트: "$host", 숨김: $hide (생성기기준: $hideByGen, 도메인기준: $hideByDomain)',
    );
    return hide;
  }

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();

    // 전달받은 channel이 없으면 구독 채널에서 매칭 시도
    if (widget.channel != null) {
      _resolvedChannel = widget.channel;
    } else {
      _resolveChannelByItem();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isCheckingSubscription = true);
    final service = SubscriptionService();
    final status = await service.checkSubscriptionStatus();
    if (!mounted) return;
    setState(() {
      _subscriptionStatus = status;
      _isCheckingSubscription = false;
    });
  }

  // 아이템 링크의 호스트와 구독 채널의 링크 호스트를 비교해 채널을 추정
  Future<void> _resolveChannelByItem() async {
    setState(() => _resolvingChannel = true);
    try {
      final channels = await RssService.fetchSubscribedChannels();
      final itemHost = _hostOf(widget.rssItem.rssLink);
      RssChannel? found;

      for (final c in channels) {
        final chHost = _hostOf(c.channelLink);
        if (chHost.isEmpty || itemHost.isEmpty) continue;
        // 완전 일치 우선, 포함 관계 보조
        if (chHost == itemHost ||
            itemHost.contains(chHost) ||
            chHost.contains(itemHost)) {
          found = c;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _resolvedChannel = found;
      });
    } catch (e) {
      debugPrint('채널 매칭 중 오류: $e');
    } finally {
      if (mounted) {
        setState(() => _resolvingChannel = false);
      }
    }
  }

  Future<void> _requestSummary() async {
    if (_loading) return;

    // 미구독자는 구독 페이지로 유도
    if (!_isPremiumActive) {
      _goToSubscription();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await RssService.fetchRssSummary(widget.rssItem.rssLink);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null || result.trim().isEmpty) {
        _error = '요약을 가져오지 못했습니다. 잠시 후 다시 시도해 주세요.';
        _summary = null;
      } else {
        _summary = result.trim();
        _error = null;
      }
    });
  }

  void _goToSubscription() {
    if (Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('구독 정보는 서버에서 자동으로 관리됩니다.'),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionHomePage()),
      );
    }
  }

  String _hostOf(String url) {
    try {
      return Uri.parse(url).host.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailTheme = AppTheme.getNewsDetailStyle(Theme.of(context));
    final textTheme = detailTheme.textTheme;
    final colorScheme = detailTheme.colorScheme;
    final settings = Provider.of<SettingsProvider>(context).settings;

    // 이미지가 있는지 확인
    final hasImage =
        widget.rssItem.rssImageLink != null &&
        widget.rssItem.rssImageLink!.isNotEmpty;

    // 본문 영역에 표시할 텍스트: 요약이 있으면 요약, 아니면 원래 description
    final bodyText = _summary ?? _cleanHtml(widget.rssItem.rssDescription);

    final channelForUi = _resolvedChannel ?? widget.channel;

    return Scaffold(
      backgroundColor: detailTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 앱바 (이미지 있을 때만 확장)
                SliverAppBar(
                  expandedHeight: hasImage ? 240.0 : 0,
                  pinned: true,
                  backgroundColor: detailTheme.appBarTheme.backgroundColor,
                  elevation: 0,
                  leading: IconButton(
                    tooltip: '뒤로가기',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: detailTheme.cardColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: detailTheme.appBarTheme.iconTheme?.color,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace:
                      hasImage
                          ? FlexibleSpaceBar(
                            background: Image.network(
                              widget.rssItem.rssImageLink!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: detailTheme.colorScheme.surfaceVariant,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color:
                                          detailTheme
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : null,
                ),

                // 콘텐츠 영역
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // RSS 채널 정보 표시
                        if (channelForUi != null)
                          _buildChannelInfo(
                            channelForUi,
                            colorScheme,
                            textTheme,
                          ),

                        const SizedBox(height: 16),

                        // 날짜 및 저자 정보
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(widget.rssItem.rssPubDate),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                              ),
                            ),

                            // 저자 정보가 있으면 표시
                            if (widget.rssItem.rssAuthor != null &&
                                widget.rssItem.rssAuthor!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.rssItem.rssAuthor!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 제목
                        Text(
                          widget.rssItem.rssTitle,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // 요약하기 CTA (본문 상단)
                        if (!_hideSummaryFeature) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isCheckingSubscription || _resolvingChannel
                                      ? null
                                      : (_isPremiumActive
                                          ? _requestSummary
                                          : _goToSubscription),
                              icon:
                                  (_loading ||
                                          _isCheckingSubscription ||
                                          _resolvingChannel)
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Icon(
                                        _isPremiumActive
                                            ? Icons.auto_awesome_rounded
                                            : Icons.lock_outline,
                                        size: 18,
                                      ),
                              label: Text(
                                _isCheckingSubscription
                                    ? '확인 중...'
                                    : _resolvingChannel
                                    ? '채널 확인 중...'
                                    : _isPremiumActive
                                    ? (_summary == null
                                        ? 'AI로 요약하기'
                                        : '요약 다시 생성')
                                    : '구독하고 요약 사용하기',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: detailTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          // 로딩/에러 인라인 표시 (본문 위)
                          if (_loading || _error != null) ...[
                            const SizedBox(height: 10),
                            if (_loading)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '요약 생성 중...',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              )
                            else if (_error != null)
                              Text(
                                _error!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: detailTheme.colorScheme.error,
                                ),
                              ),
                          ],
                        ],

                        const SizedBox(height: 16),

                        // 본문(또는 요약) 콘텐츠 - 요약이 있으면 요약으로 대체
                        Text(bodyText, style: textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 하단 버튼 영역 (공유/원문 보기)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: detailTheme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: detailTheme.shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 공유하기 버튼
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Share.share(
                              '${widget.rssItem.rssTitle}\n\n${widget.rssItem.rssLink}',
                            );
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text(
                            '공유하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                detailTheme.brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            foregroundColor:
                                detailTheme.brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 원문 보기 버튼
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            UrlLauncherHelper.openUrl(
                              context,
                              widget.rssItem.rssLink,
                              settings.webOpenMode,
                            );
                          },
                          icon: const Icon(Icons.public, size: 18),
                          label: const Text(
                            '원문 보기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: detailTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // RSS 채널 정보 위젯
  Widget _buildChannelInfo(
    RssChannel channel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // 채널 아이콘/로고 표시
        if (channel.channelImageUrl != null &&
            channel.channelImageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              channel.channelImageUrl!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.rss_feed,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                );
              },
            ),
          )
        else
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.rss_feed, color: colorScheme.primary, size: 16),
          ),

        const SizedBox(width: 10),

        // 채널 이름
        Expanded(
          child: Text(
            channel.channelTitle,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 채널 언어 표시
        if (channel.channelLanguage != null &&
            channel.channelLanguage != 'None')
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              channel.channelLanguage!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }

  // HTML 태그 제거 함수
  String _cleanHtml(String html) {
    final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return html
        .replaceAll(exp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  // 날짜 포맷팅 함수
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}년 ${date.month}월 ${date.day}일 ${_formatTime(date.hour, date.minute)}';
    } catch (e) {
      return dateStr;
    }
  }

  // 시간 포맷팅 함수 (오전/오후가 앞에 오는 자연스러운 표기)
  String _formatTime(int hour, int minute) {
    final isPM = hour >= 12;
    final formattedHour =
        hour > 12
            ? hour - 12
            : hour == 0
            ? 12
            : hour;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '${isPM ? '오후' : '오전'} $formattedHour:$formattedMinute';
  }
}
