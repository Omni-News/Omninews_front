import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('링크를 열 수 없습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 0,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'RSS 채널',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh, color: Colors.black87),
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 채널 헤더 섹션
                _buildChannelHeader(),

                // 구분선
                Container(
                  height: 8,
                  color: Colors.grey[100],
                ),

                // 최신 피드 섹션
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.article, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '최신 피드',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '새로고침하려면 아래로 당기세요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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
  Widget _buildChannelHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(),
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
              // 채널 이미지
              _buildChannelImage(),

              const SizedBox(width: 16),

              // 채널 기본 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.channelTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        height: 1.2,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _launchUrl(widget.channel.channelLink),
                      child: Text(
                        widget.channel.channelLink,
                        style: const TextStyle(
                          color: Colors.blue,
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
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
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
                backgroundColor:
                    widget.isSubscribed ? Colors.red[600] : Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor:
                    widget.isSubscribed ? Colors.red[300] : Colors.blue[300],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
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
    );
  }

  // 기본 채널 아이콘
  Widget _buildDefaultChannelIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[400]!, Colors.blue[700]!],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // RSS 아이템 목록 위젯
  Widget _buildRssItems() {
    return FutureBuilder<List<RssItem>>(
      future: _rssItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
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
            separatorBuilder: (context, index) => const Divider(height: 30),
            itemBuilder: (context, index) {
              return RssItemCard(item: snapshot.data![index]);
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
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '피드를 불러오는데 실패했습니다',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadRssItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
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
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '피드 항목이 없습니다',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나중에 다시 확인해보세요',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
