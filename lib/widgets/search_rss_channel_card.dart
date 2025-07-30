import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SearchRssChannelCard extends StatefulWidget {
  final RssChannel channel;
  final VoidCallback? onSubscriptionChanged;

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
  void didUpdateWidget(SearchRssChannelCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 외부에서 구독 상태가 변경되면 반영
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
      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;
          _isLoading = false;
          _initialCheckDone = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initialCheckDone = true;
        });
      }
      print('구독 상태 확인 중 오류: $e');
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
      if (channelId == null || channelId == 0) throw Exception('구독 URL이 없습니다');

      if (_isSubscribed) {
        success = await SubscribeService.unsubscribe(channelId);
      } else {
        success = await SubscribeService.subscribe(channelId);
      }

      if (success && mounted) {
        setState(() {
          _isSubscribed = !_isSubscribed;
          _isLoading = false;
        });

        // 구독 상태 변경 콜백 호출
        if (widget.onSubscriptionChanged != null) {
          widget.onSubscriptionChanged!();
        }

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
      if (mounted) {
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
  }

  Future<void> _navigateToChannelDetail() async {
    // 채널 상세 화면으로 이동
    // 구현할 경우 여기에 코드 추가
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);
    final searchStyle = AppTheme.searchStyleOf(context);

    // 이미지 표시 여부 결정 (뷰 모드에 따름)
    final showImage = true;

    return InkWell(
      onTap: _navigateToChannelDetail,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 채널 아이콘/이미지 (뷰 모드에 따라 표시 여부 결정)
            if (showImage) ...[
              Hero(
                tag: 'channel_${widget.channel.channelRssLink ?? "unknown"}',
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
                  child:
                      (widget.channel.channelImageUrl ?? '').isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              rssTheme.channelImageBorderRadius,
                            ),
                            child: Image.network(
                              widget.channel.channelImageUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.rss_feed,
                                    color: rssTheme.channelIconColor,
                                    size: 24,
                                  ),
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
            ],

            // 채널 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 태그 표시 (채널)
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

                  // 채널 제목
                  Text(
                    widget.channel.channelTitle ?? '제목 없음',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 채널 설명
                  Text(
                    widget.channel.channelDescription ?? '설명 없음',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 구독 버튼
            _isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryColor,
                  ),
                )
                : IconButton(
                  icon: Icon(
                    _isSubscribed
                        ? Icons.check_circle
                        : Icons.add_circle_outline,
                    color:
                        _isSubscribed
                            ? rssTheme.subscribeButtonActiveText
                            : theme.textTheme.bodyMedium?.color?.withOpacity(
                              0.7,
                            ),
                    size: 24,
                  ),
                  onPressed: _toggleSubscription,
                ),
          ],
        ),
      ),
    );
  }
}
