import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/widgets/subscribe_date_view.dart';
import 'package:omninews_flutter/widgets/subscribe_channel_view.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RssItem>> _subscribedItems;
  late Future<Map<RssChannel, List<RssItem>>> _channelItems;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              elevation: 0,
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
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black87,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: '날짜별 보기'),
                  Tab(text: '채널별 보기'),
                ],
              ),
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
