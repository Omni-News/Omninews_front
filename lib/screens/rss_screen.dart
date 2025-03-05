import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/widgets/rss_channel_card.dart';
import 'package:omninews_flutter/screens/rss_add_screen.dart';
import 'package:omninews_flutter/screens/rss_channel_detail_screen.dart';

class RssScreen extends StatefulWidget {
  const RssScreen({super.key});

  @override
  State<RssScreen> createState() => _RssScreenState();
}

class _RssScreenState extends State<RssScreen> with AutomaticKeepAliveClientMixin {
  late Future<List<RssChannel>> subscribedChannels;
  late Future<List<RssChannel>> recommendedChannels;
  List<RssChannel> _cachedSubscribedChannels = []; // 캐시된 구독 목록

  @override
  bool get wantKeepAlive => true; // 탭 전환 시 상태 유지

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // 화면이 다시 포커스를 받을 때마다 데이터 새로고침
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 활성화될 때마다 새로고침 로직
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() async {
    // 구독 정보를 완전히 새로 가져오기
    setState(() {
      subscribedChannels = RssService.fetchSubscribedChannels();
      recommendedChannels = RssService.fetchRecommendedChannels();
    });
    
    // 구독 목록 캐시 업데이트
    _cachedSubscribedChannels = await RssService.fetchSubscribedChannels();
  }

bool _isChannelSubscribed(RssChannel channel) {
  for (var c in _cachedSubscribedChannels) {
    debugPrint('Comparing channel: ${c.channelTitle} with ${channel.channelTitle}');
    
    // 올바른 필드 이름으로 비교
    if (c.channelId == channel.channelId || c.channelLink == channel.channelLink) {
      return true;
    }
  }
  return false;
}

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            homeScaffoldKey.currentState?.openDrawer();
          },
        ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '내 구독',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        // 화면 이동 후 돌아올 때 강제로 새로고침
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
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('새 RSS 추가'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<RssChannel>>(
                  future: subscribedChannels,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: Text('구독 정보를 불러오는데 실패했습니다'),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final channel = snapshot.data![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: RssChannelCard(
                              channel: channel,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RssChannelDetailScreen(
                                      channel: channel,
                                      isSubscribed: true,
                                      onSubscriptionChanged: _refreshData,
                                    ),
                                  ),
                                ).then((_) => _refreshData());
                              },
                              isSubscribed: true,
                              onSubscriptionChanged: _refreshData,
                            ),
                          );
                        },
                      );
                    } else {
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rss_feed,
                                  color: Colors.grey[400], size: 28),
                              const SizedBox(height: 8),
                              Text(
                                '구독 중인 RSS가 없습니다',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '추천 RSS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<RssChannel>>(
                  future: recommendedChannels,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (snapshot.hasError) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('추천 채널을 불러오는데 실패했습니다: ${snapshot.error}'),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final channel = snapshot.data![index];
                          // 개선된 구독 체크 로직
                          final bool isSubscribed = _isChannelSubscribed(channel);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: RssChannelCard(
                              channel: channel,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RssChannelDetailScreen(
                                      channel: channel,
                                      isSubscribed: isSubscribed,
                                      onSubscriptionChanged: _refreshData,
                                    ),
                                  ),
                                ).then((_) => _refreshData());
                              },
                              isSubscribed: isSubscribed,
                              onSubscriptionChanged: _refreshData,
                            ),
                          );
                        },
                      );
                    } else {
                      return const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('추천 채널이 없습니다'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
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
}
