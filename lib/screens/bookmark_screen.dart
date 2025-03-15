import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:omninews_flutter/widgets/news_item_card.dart'; // News 카드 위젯 (아래에 만들 예정)
import 'package:omninews_flutter/screens/home_screen.dart';
import 'package:sticky_headers/sticky_headers.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RssItem>> _bookmarkedItems;
  late Future<List<News>> _bookmarkedNews; // 북마크된 뉴스

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  final List<String> _tabs = ['Rss', 'News'];

  @override
  bool get wantKeepAlive => true; // 탭 전환 시 상태 유지

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
      // RSS 북마크
      _bookmarkedItems = SubscribeService.getLocalBookmarks();

      // 뉴스 북마크 (News와 NewsApi 통합)
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

  // 로컬 북마크에서 검색하는 메서드
  void _searchLocalBookmarks(String query) {
    setState(() {
      _bookmarkedItems = _filterLocalBookmarks(query);
      _bookmarkedNews = NewsBookmarkService.searchAllBookmarkedNews(query);
    });
  }

  // 로컬 북마크 필터링
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
        // 날짜 파싱 오류 시 '날짜 없음' 그룹에 추가
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
          return dateB.compareTo(dateA); // 최신 날짜부터
        } catch (e) {
          return 0;
        }
      });

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  // 뉴스를 날짜별로 그룹화
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
        // 날짜 파싱 오류 시 '날짜 없음' 그룹에 추가
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

  String _formatDate(String dateString) {
    if (dateString == '날짜 없음') {
      return dateString;
    }

    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy년 MM월 dd일').parse(dateString);
      final difference = now.difference(date).inDays;

      // 오늘, 어제, 그저께만 특별히 처리
      if (difference == 0) {
        return '오늘';
      } else if (difference == 1) {
        return '어제';
      } else if (difference == 2) {
        return '그저께';
      }

      // 나머지는 날짜 그대로 표시
      return dateString;
    } catch (e) {
      return dateString;
    }
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
              centerTitle: true,
              title: _isSearching
                  ? _buildSearchField()
                  : const Text(
                      'Bookmarks',
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
                  onPressed: _refreshBookmarks,
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
            _buildDateView(),

            // News 탭
            _buildNewsView(),
          ],
        ),
      ),
    );
  }

  // 날짜별 북마크 보기
  Widget _buildDateView() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshBookmarks();
      },
      child: FutureBuilder<List<RssItem>>(
        future: _bookmarkedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState('데이터를 불러오는데 실패했습니다');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty ? '북마크한 항목이 없습니다' : '검색 결과가 없습니다',
              _searchQuery.isEmpty ? Icons.bookmark_border : Icons.search,
            );
          }

          // 날짜별로 아이템 그룹화
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
                    // 아이템 목록
                    ...items.map((item) => _buildBookmarkItem(item)),

                    // 날짜 섹션 구분선 - 마지막 날짜가 아니면 추가
                    if (index < itemsByDate.length - 1)
                      Container(
                        height: 8,
                        color: Colors.grey[100],
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

  // News 탭 구현
  Widget _buildNewsView() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshBookmarks();
      },
      child: FutureBuilder<List<News>>(
        future: _bookmarkedNews,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState('뉴스 데이터를 불러오는데 실패했습니다');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty ? '북마크한 뉴스가 없습니다' : '검색 결과가 없습니다',
              _searchQuery.isEmpty ? Icons.bookmark_border : Icons.search,
            );
          }

          // 날짜별로 뉴스 그룹화
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
                    // 뉴스 아이템 목록
                    ...newsItems
                        .map((newsItem) => _buildNewsBookmarkItem(newsItem)),

                    // 날짜 섹션 구분선 - 마지막 날짜가 아니면 추가
                    if (index < newsByDate.length - 1)
                      Container(
                        height: 8,
                        color: Colors.grey[100],
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

  // 날짜 헤더 위젯
  Widget _buildDateHeader(String date, int itemCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            date,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.5,
              color: Colors.indigo[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '·',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$itemCount개의 항목',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 북마크된 RSS 아이템 표시 위젯
  Widget _buildBookmarkItem(RssItem item) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 메인 카드
              Expanded(
                child: RssItemCard(
                  item: item,
                  onBookmarkChanged: _refreshBookmarks, // 북마크 변경 시 화면 새로고침
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Colors.grey.shade200,
        ),
      ],
    );
  }

  // 북마크된 뉴스 아이템 표시 위젯
  Widget _buildNewsBookmarkItem(News news) {
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
          color: Colors.grey.shade200,
        ),
      ],
    );
  }

// 검색 필드 위젯
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

// 오류 상태 표시 위젯
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[800],
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

// 빈 상태 표시 위젯
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            if (_searchQuery.isEmpty && icon == Icons.bookmark_border) ...[
              const SizedBox(height: 8),
              Text(
                '관심 있는 컨텐츠를 북마크해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[500], letterSpacing: -0.2),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(
                  '각 콘텐츠에서 북마크 아이콘을 탭하면 이곳에 저장됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
