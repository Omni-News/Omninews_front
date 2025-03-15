import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/widgets/subscribe_date_view.dart';
import 'package:omninews_flutter/widgets/subscribe_channel_view.dart';
import 'package:omninews_flutter/screens/home_screen.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RssItem>> _subscribedItems;
  late Future<Map<RssChannel, List<RssItem>>> _channelItems;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  final List<String> _tabs = ['날짜별 보기', '채널별 보기'];

  @override
  bool get wantKeepAlive => true; // 탭 전환 시 상태 유지

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _subscribedItems = SubscribeService.getSubscribedItems();
      _channelItems = SubscribeService.getItemsByChannel();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _refreshData();
      }
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _subscribedItems = SubscribeService.searchBookmarkedItems(query);
        _channelItems = SubscribeService.searchItemsByChannel(query);
      } else {
        _refreshData();
      }
    });
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
              centerTitle: true,
              backgroundColor: Colors.white,
              title: _isSearching
                  ? _buildSearchField()
                  : const Text(
                      'Subscribe',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.black87,
                  ),
                  onPressed: _toggleSearch,
                ),
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
        body: TabBarView(
          controller: _tabController,
          children: [
            // 날짜별 보기 탭
            SubscribeDateView(
              items: _subscribedItems,
              searchQuery: _searchQuery,
              onRefresh: _refreshData,
            ),

            // 채널별 보기 탭
            SubscribeChannelView(
              channelItems: _channelItems,
              searchQuery: _searchQuery,
              onRefresh: _refreshData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '검색어를 입력하세요',
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.black, fontSize: 16),
      onChanged: _handleSearch,
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
