import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:omninews_flutter/widgets/news_item_card.dart';
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RssItem>> _bookmarkedItems;
  late Future<List<News>> _bookmarkedNews;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  final List<String> _tabs = ['RSS', 'News'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshBookmarks() {
    setState(() {
      _bookmarkedItems = SubscribeService.getLocalBookmarks();
      _bookmarkedNews = NewsBookmarkService.getAllBookmarkedNewsAsNews();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _refreshBookmarks();
      }
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _searchLocalBookmarks(query);
      } else {
        _refreshBookmarks();
      }
    });
  }

  void _searchLocalBookmarks(String query) {
    setState(() {
      _bookmarkedItems = _filterLocalBookmarks(query);
      _bookmarkedNews = NewsBookmarkService.searchAllBookmarkedNews(query);
    });
  }

  Future<List<RssItem>> _filterLocalBookmarks(String query) async {
    final items = await SubscribeService.getLocalBookmarks();
    final lowercaseQuery = query.toLowerCase();

    return items.where((item) {
      return item.rssTitle.toLowerCase().contains(lowercaseQuery) ||
          item.rssDescription.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Map<String, List<RssItem>> _groupItemsByDate(List<RssItem> items) {
    final Map<String, List<RssItem>> grouped = {};

    for (final item in items) {
      try {
        final date = DateTime.parse(item.rssPubDate);
        final dateString = DateFormat('yyyy년 MM월 dd일').format(date);

        if (!grouped.containsKey(dateString)) {
          grouped[dateString] = [];
        }
        grouped[dateString]!.add(item);
      } catch (e) {
        const dateString = '날짜 없음';
        if (!grouped.containsKey(dateString)) {
          grouped[dateString] = [];
        }
        grouped[dateString]!.add(item);
      }
    }

    // 최신 날짜부터 정렬
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '날짜 없음') return 1;
        if (b == '날짜 없음') return -1;

        try {
          final dateA = DateFormat('yyyy년 MM월 dd일').parse(a);
          final dateB = DateFormat('yyyy년 MM월 dd일').parse(b);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  Map<String, List<News>> _groupNewsByDate(List<News> items) {
    final Map<String, List<News>> grouped = {};

    for (final item in items) {
      try {
        final date = DateTime.parse(item.newsPubDate);
        final dateString = DateFormat('yyyy년 MM월 dd일').format(date);

        if (!grouped.containsKey(dateString)) {
          grouped[dateString] = [];
        }
        grouped[dateString]!.add(item);
      } catch (e) {
        const dateString = '날짜 없음';
        if (!grouped.containsKey(dateString)) {
          grouped[dateString] = [];
        }
        grouped[dateString]!.add(item);
      }
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '날짜 없음') return 1;
        if (b == '날짜 없음') return -1;

        try {
          final dateA = DateFormat('yyyy년 MM월 dd일').parse(a);
          final dateB = DateFormat('yyyy년 MM월 dd일').parse(b);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  String _formatDate(String dateString) {
    if (dateString == '날짜 없음') {
      return dateString;
    }

    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy년 MM월 dd일').parse(dateString);
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return '오늘';
      } else if (difference == 1) {
        return '어제';
      } else if (difference == 2) {
        return '그저께';
      }

      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 기본 테마 속성
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              leading: IconButton(
                icon: Icon(Icons.menu,
                    color: Theme.of(context).appBarTheme.iconTheme?.color),
                onPressed: () {
                  homeScaffoldKey.currentState?.openDrawer();
                },
              ),
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              centerTitle: true,
              title: _isSearching
                  ? _buildSearchField()
                  : Text(
                      'Bookmarks',
                      style: textTheme.headlineMedium,
                    ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                  onPressed: _refreshBookmarks,
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).primaryColor,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor:
                      Theme.of(context).textTheme.bodyLarge?.color,
                  indicatorWeight: 3,
                  labelStyle: textTheme.labelLarge,
                  unselectedLabelStyle: textTheme.labelMedium,
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
            _buildDateView(),
            _buildNewsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateView() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () async {
        _refreshBookmarks();
      },
      child: FutureBuilder<List<RssItem>>(
        future: _bookmarkedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState('데이터를 불러오는데 실패했습니다');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty ? '북마크한 항목이 없습니다' : '검색 결과가 없습니다',
              _searchQuery.isEmpty ? Icons.bookmark_border : Icons.search,
            );
          }

          final itemsByDate = _groupItemsByDate(snapshot.data!);

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            itemCount: itemsByDate.length,
            itemBuilder: (context, index) {
              final date = itemsByDate.keys.elementAt(index);
              final items = itemsByDate[date]!;
              final formattedDate = _formatDate(date);

              return StickyHeader(
                header: _buildDateHeader(formattedDate, items.length),
                content: Column(
                  children: [
                    ...items.map((item) => _buildBookmarkItem(item)),
                    if (index < itemsByDate.length - 1)
                      Container(
                        height: 8,
                        color: subscribeStyle.sectionDividerColor,
                        margin: const EdgeInsets.only(top: 8),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsView() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return RefreshIndicator(
      color: Theme.of(context).primaryColor,
      onRefresh: () async {
        _refreshBookmarks();
      },
      child: FutureBuilder<List<News>>(
        future: _bookmarkedNews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState('뉴스 데이터를 불러오는데 실패했습니다');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty ? '북마크한 뉴스가 없습니다' : '검색 결과가 없습니다',
              _searchQuery.isEmpty ? Icons.bookmark_border : Icons.search,
            );
          }

          final newsByDate = _groupNewsByDate(snapshot.data!);

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            itemCount: newsByDate.length,
            itemBuilder: (context, index) {
              final date = newsByDate.keys.elementAt(index);
              final newsItems = newsByDate[date]!;
              final formattedDate = _formatDate(date);

              return StickyHeader(
                header: _buildDateHeader(formattedDate, newsItems.length),
                content: Column(
                  children: [
                    ...newsItems
                        .map((newsItem) => _buildNewsBookmarkItem(newsItem)),
                    if (index < newsByDate.length - 1)
                      Container(
                        height: 8,
                        color: subscribeStyle.sectionDividerColor,
                        margin: const EdgeInsets.only(top: 8),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String date, int itemCount) {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Container(
      color: subscribeStyle.dateHeaderBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            date,
            style: subscribeStyle.dateTextStyle,
          ),
          const SizedBox(width: 8),
          Text(
            '·',
            style: TextStyle(
              color: subscribeStyle.dotColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$itemCount개의 항목',
            style: subscribeStyle.countTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkItem(RssItem item) {
    final cardStyle = AppTheme.newsCardStyleOf(context);

    return Column(
      children: [
        RssItemCard(
          item: item,
          onBookmarkChanged: _refreshBookmarks,
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: cardStyle.dividerColor,
        ),
      ],
    );
  }

  Widget _buildNewsBookmarkItem(News news) {
    final cardStyle = AppTheme.newsCardStyleOf(context);

    return Column(
      children: [
        NewsItemCard(
          news: news,
          onBookmarkChanged: _refreshBookmarks,
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: cardStyle.dividerColor,
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '검색어를 입력하세요',
        hintStyle: TextStyle(color: Theme.of(context).hintColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 16,
      ),
      onChanged: _handleSearch,
    );
  }

  Widget _buildErrorState(String message) {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: subscribeStyle.errorIconColor,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _refreshBookmarks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: subscribeStyle.emptyIconColor,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: subscribeStyle.emptyTextColor,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            if (_searchQuery.isEmpty && icon == Icons.bookmark_border) ...[
              const SizedBox(height: 16),
              Text(
                '관심 있는 컨텐츠를 북마크해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: subscribeStyle.emptyTextColor.withOpacity(0.8),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: subscribeStyle.hintBoxBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: subscribeStyle.hintBoxBorder),
                ),
                child: Text(
                  '각 콘텐츠에서 북마크 아이콘을 탭하면 이곳에 저장됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: subscribeStyle.hintTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Theme.of(context).shadowColor,
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
