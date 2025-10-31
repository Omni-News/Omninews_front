import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:sticky_headers/sticky_headers.dart';

class FolderContentScreen extends StatefulWidget {
  final RssFolder folder;
  final VoidCallback onRefresh;

  const FolderContentScreen({
    super.key,
    required this.folder,
    required this.onRefresh,
  });

  @override
  State<FolderContentScreen> createState() => _FolderContentScreenState();
}

class _FolderContentScreenState extends State<FolderContentScreen> {
  // PAGENATION: FutureBuilder 대신 리스트 직접 관리
  List<RssItem> _folderItemsList = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _refreshData();

    // PAGENATION: 스크롤 리스너 추가
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        _loadMoreFolderItems();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose(); // PAGENATION: 컨트롤러 해제
    super.dispose();
  }

  // PAGENATION: 새로고침 (페이지 1로 리셋)
  Future<void> _refreshData() async {
    // 검색 중일 때는 검색 로직 실행
    if (_isSearching && _searchQuery.isNotEmpty) {
      _handleSearch(_searchQuery);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasMore = true;
      _currentPage = 1;
      _folderItemsList.clear();
    });

    // 첫 페이지 데이터 로드
    await _fetchPaginatedFolderItems();

    if (mounted) {
      widget.onRefresh(); // 부모에게 알림
    }
  }

  // PAGENATION: 다음 페이지 로드
  Future<void> _loadMoreFolderItems() async {
    if (_isLoading || !_hasMore || _isSearching) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    await _fetchPaginatedFolderItems();
  }

  // PAGENATION: 페이지네이션용 데이터 fetching 로직
  Future<void> _fetchPaginatedFolderItems() async {
    // 검색 중이 아닐 때만 실행 (안전장치)
    if (_isSearching) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final channelIds =
        widget.folder.folderChannels
            .map((channel) => channel.channelId)
            .toList();

    if (channelIds.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
      return;
    }

    try {
      final items = await SubscribeService.getSubscribedItemsByChannelIds(
        channelIds,
        _currentPage,
      );

      if (mounted) {
        setState(() {
          if (items.isEmpty) {
            _hasMore = false;
          } else {
            _folderItemsList.addAll(items);
            // 기존 로직 유지: 새 데이터 추가 후 전체 목록 정렬
            _folderItemsList.sort((a, b) {
              final da = _parsePubDate(a.rssPubDate);
              final db = _parsePubDate(b.rssPubDate);
              return db.compareTo(da);
            });
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching folder items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_currentPage > 1) _currentPage--; // "더 보기" 실패 시 페이지 롤백
        });
      }
    }
  }

  // PAGENATION: 검색 로직 (기존 로직 유지 - 모든 아이템 로컬 필터링)
  void _handleSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        _searchQuery = query;
      });

      if (query.isEmpty) {
        // 검색어 비었으면 페이지네이션 뷰로 복귀
        _refreshData();
        return;
      }

      // 검색 모드: 페이지네이션 중지, 로딩 시작
      setState(() {
        _isLoading = true;
        _hasMore = false; // 검색 결과는 '더 보기' 없음
        _folderItemsList.clear();
      });

      // 기존 로직(로컬 필터링)을 위해 모든 아이템을 가져옴
      final allItems = await _fetchAllItemsForFolder();

      // 기존 로직: 로컬 필터링
      final q = query.toLowerCase();
      final filteredItems =
          allItems.where((item) {
            final title = (item.rssTitle).toLowerCase();
            final desc = (item.rssDescription).toLowerCase();
            return title.contains(q) || desc.contains(q);
          }).toList();

      // 기존 로직: 정렬
      filteredItems.sort((a, b) {
        final da = _parsePubDate(a.rssPubDate);
        final db = _parsePubDate(b.rssPubDate);
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _folderItemsList = filteredItems;
          _isLoading = false;
        });
      }
    });
  }

  // PAGENATION: 검색을 위해 모든 페이지의 아이템을 가져오는 헬퍼
  Future<List<RssItem>> _fetchAllItemsForFolder() async {
    final channelIds =
        widget.folder.folderChannels
            .map((channel) => channel.channelId)
            .toList();
    if (channelIds.isEmpty) return [];

    List<RssItem> allItems = [];
    int page = 1;
    bool hasMoreItems = true;

    while (hasMoreItems) {
      try {
        final items = await SubscribeService.getSubscribedItemsByChannelIds(
          channelIds,
          page,
        );
        if (items.isEmpty) {
          hasMoreItems = false;
        } else {
          allItems.addAll(items);
          page++;
        }
      } catch (e) {
        debugPrint('Error fetching all items for search: $e');
        hasMoreItems = false; // 에러 발생 시 중지
      }
    }
    return allItems;
  }

  DateTime _parsePubDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      // 파싱 실패 시 아주 과거 날짜로 취급해 뒤로 밀리도록 처리
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        // _searchQuery = ''; // _handleSearch가 처리
        _handleSearch(''); // 검색 종료 시 데이터 복구
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title:
            _isSearching ? _buildSearchField() : Text(widget.folder.folderName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '뒤로가기',
        ),
        actions: [
          if (_isSearching && _searchQuery.isNotEmpty)
            IconButton(
              tooltip: '검색어 지우기',
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _handleSearch('');
              },
            ),
          IconButton(
            tooltip: _isSearching ? '검색 닫기' : '검색',
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: '새로고침',
            icon: Icon(
              Icons.refresh,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: _refreshData,
          ),
        ],
      ),
      // PAGENATION: FutureBuilder 대신 _buildBody() 사용
      body: _buildBody(),
    );
  }

  // PAGENATION: 바디 위젯 분리
  Widget _buildBody() {
    final theme = Theme.of(context);

    // 1. 초기 로딩 상태
    if (_isLoading && _folderItemsList.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
    }

    // 2. 데이터가 없는 상태 (검색 결과 없음 포함)
    if (_folderItemsList.isEmpty && !_isLoading) {
      return _buildEmptyState(
        _searchQuery.isEmpty ? '폴더에 컨텐츠가 없습니다' : '검색 결과가 없습니다',
        _searchQuery.isEmpty ? Icons.folder_open : Icons.search,
        context,
      );
    }

    // 3. 데이터가 있는 상태
    final itemsByDate = _groupItemsByDate(_folderItemsList);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.cardColor,
      child: ListView.builder(
        controller: _scrollController, // PAGENATION: 스크롤 컨트롤러 연결
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        // PAGENATION: 로딩 인디케이터를 위해 +1
        itemCount: itemsByDate.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // PAGENATION: 마지막 아이템이면 로딩 인디케이터 표시
          if (index == itemsByDate.length) {
            return _isLoading
                ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  ),
                )
                : const SizedBox.shrink();
          }

          // --- 기존 아이템 빌더 로직 ---
          final dateKey = itemsByDate.keys.elementAt(index);
          final items = itemsByDate[dateKey]!;
          final formattedDate = _formatDate(dateKey);

          return StickyHeader(
            header: _buildDateHeader(formattedDate, items.length, context),
            content: Column(
              children: [
                // 인덱스로 순회하여 indexOf 호출을 피하고 성능 개선
                ...List.generate(items.length, (i) {
                  final item = items[i];
                  return Column(
                    children: [
                      RssItemCard(
                        item: item,
                        // PAGENATION: 북마크 변경 시 _refreshData(페이지1) 대신
                        // _handleBookmarkChanged(로컬) 등으로 최적화할 수 있으나,
                        // 일단 기존 로직(전체 새로고침)을 유지합니다.
                        onBookmarkChanged: _refreshData,
                      ),
                      if (i < items.length - 1)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: theme.dividerTheme.color?.withOpacity(0.5),
                        ),
                    ],
                  );
                }),
                if (index < itemsByDate.length - 1)
                  Container(
                    height: 8,
                    color:
                        AppTheme.subscribeViewStyleOf(
                          context,
                        ).sectionDividerColor,
                    margin: const EdgeInsets.only(top: 8),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 날짜별로 아이템을 그룹화
  Map<String, List<RssItem>> _groupItemsByDate(List<RssItem> items) {
    final Map<String, List<RssItem>> grouped = {};

    for (final item in items) {
      final date = _parsePubDate(item.rssPubDate);
      final dateString =
          date.millisecondsSinceEpoch == 0
              ? '날짜 없음'
              : DateFormat('yyyy년 MM월 dd일').format(date);

      grouped.putIfAbsent(dateString, () => []);
      grouped[dateString]!.add(item);
    }

    // 최신순 정렬, '날짜 없음'은 항상 마지막으로
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          if (a == '날짜 없음') return 1;
          if (b == '날짜 없음') return -1;
          try {
            final da = DateFormat('yyyy년 MM월 dd일').parse(a);
            final db = DateFormat('yyyy년 MM월 dd일').parse(b);
            return db.compareTo(da);
          } catch (_) {
            return 0;
          }
        });

    return {for (final k in sortedKeys) k: grouped[k]!};
  }

  // 날짜 형식 변환
  String _formatDate(String dateString) {
    if (dateString == '날짜 없음') return dateString;

    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy년 MM월 dd일').parse(dateString);
      final difference = now.difference(date).inDays;

      if (difference == 0) return '오늘';
      if (difference == 1) return '어제';
      return dateString;
    } catch (_) {
      return dateString;
    }
  }

  Widget _buildDateHeader(String date, int itemCount, BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            date,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.5,
              color: subscribeStyle.dateHeaderColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '·',
            style: TextStyle(
              color: theme.dividerTheme.color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$itemCount개의 항목',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    // 에러 상태에서도 당겨서 새로고침 가능하도록 래핑
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.cardColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: subscribeStyle.errorIconColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: subscribeStyle.emptyTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    // 빈 상태에서도 당겨서 새로고침 가능하도록 래핑
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: theme.primaryColor,
      backgroundColor: theme.cardColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: subscribeStyle.emptyIconColor),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: subscribeStyle.emptyTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '이 폴더에 채널을 추가하세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: subscribeStyle.hintTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '폴더 내 검색...',
        hintStyle: TextStyle(color: theme.hintColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
      onChanged: _handleSearch,
      textInputAction: TextInputAction.search,
      onSubmitted: (v) => _handleSearch(v),
    );
  }
}
