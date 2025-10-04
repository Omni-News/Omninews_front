import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SearchRssChannelCard extends StatefulWidget {
  final RssChannel channel;
  final VoidCallback? onSubscriptionChanged;

  // 외부(리스트 상위)에서 캐시된 구독 상태를 전달받아 렌더링 지연/깜빡임을 줄이기 위한 옵션
  final bool? isSubscribedOverride;

  const SearchRssChannelCard({
    super.key,
    required this.channel,
    this.onSubscriptionChanged,
    this.isSubscribedOverride,
  });

  @override
  State<SearchRssChannelCard> createState() => _SearchRssChannelCardState();
}

class _SearchRssChannelCardState extends State<SearchRssChannelCard> {
  bool _isSubscribed = false;
  bool _isLoading = false;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    // 외부에서 구독 상태가 제공되면 사용하고, 그렇지 않으면 API 호출
    if (widget.isSubscribedOverride != null) {
      _isSubscribed = widget.isSubscribedOverride!;
      _initialCheckDone = true;
    } else {
      _checkSubscriptionStatus();
    }
  }

  @override
  void didUpdateWidget(covariant SearchRssChannelCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 다른 채널로 바뀌었으면 상태 초기화 후 재확인
    if (oldWidget.channel.channelRssLink != widget.channel.channelRssLink) {
      _isLoading = false;
      _initialCheckDone = false;
      if (widget.isSubscribedOverride != null) {
        _isSubscribed = widget.isSubscribedOverride!;
        _initialCheckDone = true;
      } else {
        _checkSubscriptionStatus();
      }
      setState(() {});
      return;
    }

    // 동일 채널이지만 외부 구독 상태 override가 변경된 경우 반영
    if (widget.isSubscribedOverride != oldWidget.isSubscribedOverride &&
        widget.isSubscribedOverride != null) {
      setState(() {
        _isSubscribed = widget.isSubscribedOverride!;
        _initialCheckDone = true;
      });
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    if (_initialCheckDone) return; // 이미 확인했으면 건너뜀

    final channelRssLink = widget.channel.channelRssLink;
    if (channelRssLink.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isSubscribed = await SubscribeService.isSubscribed(channelRssLink);
      if (!mounted) return;
      setState(() {
        _isSubscribed = isSubscribed;
        _isLoading = false;
        _initialCheckDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _initialCheckDone = true;
      });
      // 조용히 실패 로깅 (필요 시 로깅 시스템 연결)
      // debugPrint('구독 상태 확인 중 오류: $e');
    }
  }

  Future<void> _toggleSubscription() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      final channelId = widget.channel.channelId;
      if (channelId == null || channelId == 0) {
        throw Exception('채널 ID가 없어 구독 변경을 진행할 수 없습니다.');
      }

      if (_isSubscribed) {
        success = await SubscribeService.unsubscribe(channelId);
      } else {
        success = await SubscribeService.subscribe(channelId);
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isSubscribed = !_isSubscribed;
          _isLoading = false;
        });

        // 상위에 구독 상태 변경을 알림(검색 목록 캐시 갱신 등)
        widget.onSubscriptionChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSubscribed ? '구독이 추가되었습니다' : '구독이 취소되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('구독 변경 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _navigateToChannelDetail() async {
    // TODO: 채널 상세 화면으로 이동 로직 연결 (필요 시 구현)
  }

  String _safe(String? v, [String fallback = '']) =>
      v == null || v.trim().isEmpty ? fallback : v;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);
    final searchStyle = AppTheme.searchStyleOf(context);

    final title = _safe(widget.channel.channelTitle, '제목 없음');
    final description = _safe(widget.channel.channelDescription, '설명 없음');
    final imageUrl = _safe(widget.channel.channelImageUrl);
    final heroTag = 'channel_${widget.channel.channelRssLink}';

    return InkWell(
      onTap: _navigateToChannelDetail,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 채널 이미지
            Hero(
              tag: heroTag,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.orange[50],
                  borderRadius: BorderRadius.circular(
                    rssTheme.channelImageBorderRadius,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    imageUrl.isNotEmpty
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stack) => Icon(
                                Icons.rss_feed,
                                color: rssTheme.channelIconColor,
                                size: 24,
                              ),
                        )
                        : Icon(
                          Icons.rss_feed,
                          color: rssTheme.channelIconColor,
                          size: 24,
                        ),
              ),
            ),
            const SizedBox(width: 12),

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 태그 (채널)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: searchStyle.channelTagBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: searchStyle.channelTagBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '채널',
                      style: TextStyle(
                        fontSize: 10,
                        color: searchStyle.channelTagText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // 제목
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 설명
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 구독 버튼
            Semantics(
              button: true,
              label: _isSubscribed ? '구독 중' : '구독 추가',
              child:
                  _isLoading && !_initialCheckDone
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primaryColor,
                        ),
                      )
                      : IconButton(
                        tooltip: _isSubscribed ? '구독 중' : '구독',
                        icon: Icon(
                          _isSubscribed
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color:
                              _isSubscribed
                                  ? rssTheme.subscribeButtonActiveText
                                  : theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                          size: 24,
                        ),
                        onPressed: _toggleSubscription,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
