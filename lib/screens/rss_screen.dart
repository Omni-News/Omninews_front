import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/screens/rss_add_screen.dart';
import 'package:omninews_flutter/screens/rss_channel_detail_screen.dart';

class RssScreen extends StatefulWidget {
  const RssScreen({super.key});

  @override
  State<RssScreen> createState() => _RssScreenState();
}

class _RssScreenState extends State<RssScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late Future<List<RssChannel>> subscribedChannels;
  late Future<List<RssChannel>> recommendedChannels;
  List<RssChannel> subscribedChannelsList = [];
  late TabController _tabController;
  final List<String> _tabs = ['구독 중', '추천 RSS'];
  bool _isLoading = true;

  // 구독 버튼 상태를 저장하는 맵 (채널 RSS 링크를 키로 사용)
  final Map<String, bool> _subscribingStatus = {};

  @override
  bool get wantKeepAlive => true; // 탭 전환 시 상태 유지

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침 로직
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // 구독 정보를 완전히 새로 가져오기
    subscribedChannels = RssService.fetchSubscribedChannels();

    // 구독 목록을 먼저 가져온 후, 추천 목록에서 구독 중인 채널을 제외
    subscribedChannelsList = await subscribedChannels;

    // 추천 채널을 가져온 후 구독 중인 채널은 제외하도록 수정
    recommendedChannels = _fetchFilteredRecommendedChannels();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 구독 중인 채널을 제외한 추천 채널 목록을 가져오는 함수
  Future<List<RssChannel>> _fetchFilteredRecommendedChannels() async {
    // 모든 추천 채널 가져오기
    final allRecommended = await RssService.fetchRecommendedChannels();

    // 구독 중인 채널의 RSS 링크 목록
    final subscribedLinks =
        subscribedChannelsList.map((e) => e.channelRssLink).toSet();

    // 구독 중이지 않은 채널만 필터링
    return allRecommended
        .where((channel) => !subscribedLinks.contains(channel.channelRssLink))
        .toList();
  }

  // 채널 구독 처리 함수 - 추가
  Future<void> _subscribeToChannel(RssChannel channel) async {
    // 이미 구독 처리 중인 채널은 중복 실행 방지
    if (_subscribingStatus[channel.channelRssLink] == true) {
      return;
    }

    setState(() {
      _subscribingStatus[channel.channelRssLink] = true;
    });

    try {
      final success = await RssService.subscribeChannel(channel.channelRssLink);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${channel.channelTitle} 구독되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 데이터 갱신
        _refreshData();

        _tabController.animateTo(0);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독 처리 중 오류가 발생했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
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
          _subscribingStatus[channel.channelRssLink] = false;
        });
      }
    }
  }

  // 채널 구독 취소 처리 함수 - 추가
  Future<void> _unsubscribeFromChannel(RssChannel channel) async {
    // 이미 구독 취소 처리 중인 채널은 중복 실행 방지
    if (_subscribingStatus[channel.channelRssLink] == true) {
      return;
    }

    setState(() {
      _subscribingStatus[channel.channelRssLink] = true;
    });

    try {
      final success =
          await RssService.unsubscribeChannel(channel.channelRssLink);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${channel.channelTitle} 구독 취소되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 데이터 갱신
        _refreshData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독 취소 처리 중 오류가 발생했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
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
          _subscribingStatus[channel.channelRssLink] = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () {
                  homeScaffoldKey.currentState?.openDrawer();
                },
              ),
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text(
                'RSS Feeds',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  onPressed: _refreshData,
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.black87,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                  ),
                  tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
                ),
              ),
              floating: true,
              pinned: true,
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // 구독 중인 RSS 탭
                  _buildSubscribedTab(),

                  // 추천 RSS 탭
                  _buildRecommendedTab(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RssAddScreen(
                onChannelAdded: () {
                  _refreshData();
                },
              ),
            ),
          );
          // 화면으로 돌아왔을 때 새로고침
          _refreshData();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 구독 중인 RSS 탭 빌드
  Widget _buildSubscribedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: FutureBuilder<List<RssChannel>>(
        future: subscribedChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    '데이터를 불러올 수 없습니다',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final channel = snapshot.data![index];
                return _buildChannelListItem(
                  channel: channel,
                  isSubscribed: true,
                );
              },
            );
          } else {
            return _buildEmptyState('구독 중인 RSS가 없습니다', Icons.rss_feed);
          }
        },
      ),
    );
  }

  // 추천 RSS 탭 빌드 - 구독 중인 채널은 제외됨
  Widget _buildRecommendedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: FutureBuilder<List<RssChannel>>(
        future: recommendedChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    '추천 채널을 불러오는데 실패했습니다',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final channel = snapshot.data![index];
                // 필터링된 목록이므로 모두 구독되지 않은 상태
                return _buildChannelListItem(
                  channel: channel,
                  isSubscribed: false,
                );
              },
            );
          } else {
            // 필터링 후 표시할 추천 채널이 없는 경우 메시지 변경
            return _buildEmptyState('모든 추천 채널을 이미 구독 중입니다', Icons.check_circle);
          }
        },
      ),
    );
  }

  // 채널 리스트 아이템 위젯 - 수정: 구독 버튼 동작 추가
  Widget _buildChannelListItem({
    required RssChannel channel,
    required bool isSubscribed,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RssChannelDetailScreen(
              channel: channel,
              isSubscribed: isSubscribed,
              onSubscriptionChanged: _refreshData,
            ),
          ),
        ).then((_) => _refreshData());
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 채널 아이콘/이미지
            _buildChannelImage(channel),
            const SizedBox(width: 16),

            // 채널 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.channelTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.channelDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.language, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        channel.channelLanguage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${channel.channelRank}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 구독 상태 표시 - 수정: 클릭 가능하게 변경
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                if (isSubscribed) {
                  _unsubscribeFromChannel(channel);
                } else {
                  _subscribeToChannel(channel);
                }
              },
              child: _buildSubscriptionIndicator(
                  isSubscribed, channel.channelRssLink),
            ),
          ],
        ),
      ),
    );
  }

  // 채널 이미지 위젯
  Widget _buildChannelImage(RssChannel channel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child:
          channel.channelImageUrl != null && channel.channelImageUrl!.isNotEmpty
              ? Image.network(
                  channel.channelImageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultChannelImage();
                  },
                )
              : _buildDefaultChannelImage(),
    );
  }

  // 기본 채널 이미지 위젯
  Widget _buildDefaultChannelImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.blue,
      child: const Icon(
        Icons.rss_feed,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  // 구독 상태 표시 위젯 - 수정: 로딩 상태 추가
  Widget _buildSubscriptionIndicator(bool isSubscribed, String channelRssLink) {
    // 구독/구독취소 처리 중인지 확인
    final isProcessing = _subscribingStatus[channelRssLink] == true;

    if (isProcessing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isSubscribed ? Colors.blue.shade700 : Colors.grey.shade600,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSubscribed ? Colors.blue.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSubscribed ? Icons.check : Icons.add,
            size: 16,
            color: isSubscribed ? Colors.blue.shade700 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isSubscribed ? '구독 중' : '구독하기',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSubscribed ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// TabBar를 SliverPersistentHeader로 만들기 위한 delegate 클래스
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      height: 48.0,
      child: child,
    );
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return true;
  }
}
