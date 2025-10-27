import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/models/app_setting.dart'; // 앱 설정 모델
import 'package:omninews_flutter/utils/url_launcher_helper.dart'; // URL 실행 도우미
import 'package:provider/provider.dart'; // 프로바이더

class RssChannelDetailScreen extends StatefulWidget {
  final RssChannel channel;
  final bool isSubscribed;
  final Function() onSubscriptionChanged;

  const RssChannelDetailScreen({
    super.key,
    required this.channel,
    required this.isSubscribed,
    required this.onSubscriptionChanged,
  });

  @override
  State<RssChannelDetailScreen> createState() => _RssChannelDetailScreenState();
}

class _RssChannelDetailScreenState extends State<RssChannelDetailScreen> {
  final List<RssItem> _rssItems = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  bool _isSubscribing = false;
  late bool _localIsSubscribed;

  @override
  void initState() {
    super.initState();
    _localIsSubscribed = widget.isSubscribed;
    _loadRssItems();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading) {
        _loadRssItems();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRssItems() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newItems = await RssService.fetchChannelItems(
        widget.channel.channelId,
        page: _page,
      );
      if (mounted) {
        setState(() {
          if (newItems.isNotEmpty) {
            _rssItems.addAll(newItems);
            _page++;
          } else {
            _hasMore = false;
          }
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
            content: Text('피드를 불러오는 데 실패했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshRssItems() async {
    setState(() {
      _rssItems.clear();
      _page = 1;
      _hasMore = true;
      _isLoading = false;
    });
    await _loadRssItems();
  }

  Future<void> _toggleSubscription() async {
    setState(() {
      _isSubscribing = true;
    });

    try {
      bool success;
      if (_localIsSubscribed) {
        success = await RssService.unsubscribeChannel(widget.channel.channelId);
      } else {
        success = await RssService.subscribeChannel(widget.channel.channelId);
      }

      if (success && mounted) {
        widget.onSubscriptionChanged();
        setState(() {
          _localIsSubscribed = !_localIsSubscribed; // 내부 상태 토글
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_localIsSubscribed ? '구독되었습니다.' : '구독이 취소되었습니다.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubscribing = false;
        });
      }
    }
  }

  // URL 열기 함수 - UrlLauncherHelper 사용
  void _launchUrl(String url, AppSettings settings) {
    UrlLauncherHelper.openUrl(context, url, settings.webOpenMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 0,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.appBarTheme.backgroundColor,
              leading: IconButton(
                tooltip: '뒤로가기',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: theme.iconTheme.color,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('RSS 채널', style: textTheme.headlineMedium),
              actions: [
                IconButton(
                  tooltip: '새로고침',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                  ),
                  onPressed: _refreshRssItems,
                ),
              ],
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshRssItems,
          color: theme.primaryColor,
          backgroundColor: theme.cardColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChannelHeader(settings),
                    Container(height: 8, color: theme.dividerTheme.color),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Icon(Icons.article, size: 18, color: theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '최신 피드',
                            style: textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          const Spacer(),
                          Text('아래로 당겨 새로고침', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildRssItems(),
            ],
          ),
        ),
      ),
    );
  }

  // 채널 헤더 섹션
  Widget _buildChannelHeader(AppSettings settings) {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);
    final textTheme = theme.textTheme;

    // 이미지 표시 여부 (뷰 모드에 따라 결정)
    final showImage = true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 채널 이미지 및 기본 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 채널 이미지 - 뷰 모드에 따라 표시/숨김
              if (showImage) ...[
                _buildChannelImage(),
                const SizedBox(width: 16),
              ],

              // 채널 기본 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.channelTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap:
                          () =>
                              _launchUrl(widget.channel.channelLink, settings),
                      child: Text(
                        widget.channel.channelLink,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 채널 설명
          Text(
            widget.channel.channelDescription,
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // 채널 태그 정보
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.language,
                label: '언어: ${widget.channel.channelLanguage}',
              ),
              if (widget.channel.rssGenerator != null &&
                  widget.channel.rssGenerator != 'None')
                _buildInfoChip(
                  icon: Icons.settings,
                  label: widget.channel.rssGenerator!,
                ),
              _buildInfoChip(
                icon: Icons.star,
                label: '${widget.channel.channelRank}',
                iconColor: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 구독/구독취소 버튼 - _localIsSubscribed 상태 사용
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubscribing ? null : _toggleSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _localIsSubscribed
                        ? theme.colorScheme.error
                        : rssTheme.subscribeButtonActiveBackground,
                foregroundColor:
                    _localIsSubscribed
                        ? Colors.white
                        : rssTheme.subscribeButtonActiveText,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor:
                    _localIsSubscribed
                        ? theme.colorScheme.error.withOpacity(0.6)
                        : theme.primaryColor.withOpacity(0.6),
              ),
              icon:
                  _isSubscribing
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(
                        _localIsSubscribed
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 20,
                      ),
              label: Text(
                _localIsSubscribed ? '구독 취소' : '구독하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 채널 이미지 위젯
  Widget _buildChannelImage() {
    final rssTheme = AppTheme.rssThemeOf(context);

    return Hero(
      tag: 'channel_${widget.channel.channelRssLink}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
        child:
            widget.channel.channelImageUrl != null &&
                    widget.channel.channelImageUrl!.isNotEmpty
                ? Image.network(
                  widget.channel.channelImageUrl!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultChannelIcon();
                  },
                )
                : _buildDefaultChannelIcon(),
      ),
    );
  }

  // 기본 채널 아이콘
  Widget _buildDefaultChannelIcon() {
    final rssTheme = AppTheme.rssThemeOf(context);

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rssTheme.channelImageGradientColors,
        ),
      ),
      child: const Icon(Icons.rss_feed, color: Colors.white, size: 42),
    );
  }

  // 정보 칩 위젯
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? theme.iconTheme.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(label, style: chipTheme.labelStyle),
        ],
      ),
    );
  }

  // RSS 아이템 목록 위젯
  Widget _buildRssItems() {
    final theme = Theme.of(context);

    if (_rssItems.isEmpty && _isLoading) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          ),
        ),
      );
    } else if (_rssItems.isEmpty && !_hasMore) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < _rssItems.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    RssItemCard(
                      item: _rssItems[index],
                      onBookmarkChanged: () {
                        // 필요 시 새로고침 처리
                      },
                    ),
                    Divider(height: 30, color: theme.dividerTheme.color),
                  ],
                ),
              );
            } else if (_hasMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
          childCount: _rssItems.length + (_hasMore ? 1 : 0),
        ),
      );
    }
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 48, color: subscribeStyle.emptyIconColor),
          const SizedBox(height: 16),
          Text(
            '피드 항목이 없습니다.',
            style: TextStyle(
              color: subscribeStyle.emptyTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나중에 다시 확인해 주세요.',
            style: TextStyle(
              color: subscribeStyle.emptyTextColor.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
