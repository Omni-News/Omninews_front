import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/models/rss_channel.dart';
import 'package:omninews_test_flutter/models/rss_item.dart';
import 'package:omninews_test_flutter/provider/settings_provider.dart';
import 'package:omninews_test_flutter/services/rss_service.dart';
import 'package:omninews_test_flutter/widgets/rss_item_card.dart';
import 'package:omninews_test_flutter/theme/app_theme.dart';
import 'package:omninews_test_flutter/models/app_setting.dart'; // 앱 설정 모델
import 'package:omninews_test_flutter/utils/url_launcher_helper.dart';
import 'package:provider/provider.dart'; // URL 실행 도우미

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
  late Future<List<RssItem>> _rssItems;
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _loadRssItems();
  }

  void _loadRssItems() {
    setState(() {
      _rssItems = RssService.fetchChannelItems(widget.channel.channelRssLink);
    });
  }

  Future<void> _toggleSubscription() async {
    setState(() {
      _isSubscribing = true;
    });

    try {
      bool success;
      if (widget.isSubscribed) {
        success =
            await RssService.unsubscribeChannel(widget.channel.channelRssLink);
      } else {
        success =
            await RssService.subscribeChannel(widget.channel.channelRssLink);
      }

      if (success && mounted) {
        widget.onSubscriptionChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSubscribed ? '구독이 취소되었습니다' : '구독되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
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
              title: Text(
                'RSS 채널',
                style: textTheme.headlineMedium,
              ),
              actions: [
                IconButton(
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
                  onPressed: _loadRssItems,
                ),
              ],
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () async {
            _loadRssItems();
          },
          color: theme.primaryColor,
          backgroundColor: theme.cardColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 채널 헤더 섹션
                _buildChannelHeader(settings),

                // 구분선
                Container(
                  height: 8,
                  color: theme.dividerTheme.color,
                ),

                // 최신 피드 섹션
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.article,
                        size: 18,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '최신 피드',
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '새로고침하려면 아래로 당기세요',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // RSS 아이템 목록
                _buildRssItems(),
              ],
            ),
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
                      onTap: () =>
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
            style: textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
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

          // 구독/구독취소 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubscribing ? null : _toggleSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isSubscribed
                    ? theme.colorScheme.error
                    : rssTheme.subscribeButtonActiveBackground,
                foregroundColor: widget.isSubscribed
                    ? Colors.white
                    : rssTheme.subscribeButtonActiveText,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: widget.isSubscribed
                    ? theme.colorScheme.error.withOpacity(0.6)
                    : theme.primaryColor.withOpacity(0.6),
              ),
              icon: _isSubscribing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      widget.isSubscribed
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      size: 20,
                    ),
              label: Text(
                widget.isSubscribed ? '구독 취소' : '구독하기',
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
        child: widget.channel.channelImageUrl != null &&
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
      child: const Icon(
        Icons.rss_feed,
        color: Colors.white,
        size: 42,
      ),
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
          Text(
            label,
            style: chipTheme.labelStyle,
          ),
        ],
      ),
    );
  }

  // RSS 아이템 목록 위젯
  Widget _buildRssItems() {
    final theme = Theme.of(context);

    return FutureBuilder<List<RssItem>>(
      future: _rssItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.primaryColor,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) =>
                Divider(height: 30, color: theme.dividerTheme.color),
            itemBuilder: (context, index) {
              return RssItemCard(
                item: snapshot.data![index],
                onBookmarkChanged: () {
                  // Refresh if needed
                },
              );
            },
          );
        } else {
          return _buildEmptyState();
        }
      },
    );
  }

  // 에러 상태 위젯
  Widget _buildErrorState(Object? error) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: subscribeStyle.errorIconColor),
          const SizedBox(height: 16),
          Text(
            '피드를 불러오는데 실패했습니다',
            style: TextStyle(
              color: textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadRssItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
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
            '피드 항목이 없습니다',
            style: TextStyle(
              color: subscribeStyle.emptyTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나중에 다시 확인해보세요',
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
