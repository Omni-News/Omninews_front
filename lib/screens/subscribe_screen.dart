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

    // 테마 및 스타일 속성 가져오기
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: theme.appBarTheme.iconTheme?.color,
                ),
                onPressed: () {
                  homeScaffoldKey.currentState?.openDrawer();
                },
              ),
              pinned: true,
              elevation: 0,
              centerTitle: true,
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: _isSearching
                  ? _buildSearchField()
                  : Text(
                      'Subscribe',
                      style: textTheme.headlineMedium,
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: theme.appBarTheme.iconTheme?.color,
                  ),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: theme.appBarTheme.iconTheme?.color,
                  ),
                  onPressed: _refreshData,
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: theme.primaryColor,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: textTheme.bodyLarge?.color,
                  indicatorWeight: 3,
                  labelStyle: textTheme.labelLarge,
                  unselectedLabelStyle: textTheme.labelMedium,
                  tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
                ),
                theme: theme,
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
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '검색어를 입력하세요',
        hintStyle: TextStyle(color: theme.hintColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 16,
      ),
      onChanged: _handleSearch,
    );
  }
}

// TabBar를 SliverPersistentHeader로 만들기 위한 delegate 클래스
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ThemeData theme;

  _SliverAppBarDelegate(this.child, {required this.theme});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
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
