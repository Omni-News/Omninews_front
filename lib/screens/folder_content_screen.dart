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
  late Future<List<RssItem>> _folderItems;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final future = _getFolderItems();
    setState(() {
      _folderItems = future;
    });
    // 부모에게도 새로고침을 알림 (필요 시 외부 목록 갱신)
    await future;
    if (mounted) {
      widget.onRefresh();
    }
  }

  Future<List<RssItem>> _getFolderItems() async {
    final channelIds =
        widget.folder.folderChannels
            .map((channel) => channel.channelId)
            .toList();

    if (channelIds.isEmpty) {
      return [];
    }

    try {
      final items = await SubscribeService.getSubscribedItemsByChannelIds(
        channelIds,
      );

      // 최신순으로 정렬 (pubDate 내림차순)
      items.sort((a, b) {
        final da = _parsePubDate(a.rssPubDate);
        final db = _parsePubDate(b.rssPubDate);
        return db.compareTo(da);
      });

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return items.where((item) {
          final title = (item.rssTitle).toLowerCase();
          final desc = (item.rssDescription).toLowerCase();
          return title.contains(q) || desc.contains(q);
        }).toList();
      }

      return items;
    } catch (e) {
      debugPrint('Error fetching folder items: $e');
      return [];
    }
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
        _searchQuery = '';
        _refreshData();
      }
    });
  }

  void _handleSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _folderItems = _getFolderItems();
      });
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
      body: FutureBuilder<List<RssItem>>(
        future: _folderItems,
        builder: (context, snapshot) {
          final isWaiting = snapshot.connectionState == ConnectionState.waiting;
          if (isWaiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState('데이터를 불러오는 데 실패했습니다', context);
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty ? '폴더에 컨텐츠가 없습니다' : '검색 결과가 없습니다',
              _searchQuery.isEmpty ? Icons.folder_open : Icons.search,
              context,
            );
          }

          final itemsByDate = _groupItemsByDate(data);

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: theme.primaryColor,
            backgroundColor: theme.cardColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: itemsByDate.length,
              itemBuilder: (context, index) {
                final dateKey = itemsByDate.keys.elementAt(index);
                final items = itemsByDate[dateKey]!;
                final formattedDate = _formatDate(dateKey);

                return StickyHeader(
                  header: _buildDateHeader(
                    formattedDate,
                    items.length,
                    context,
                  ),
                  content: Column(
                    children: [
                      // 인덱스로 순회하여 indexOf 호출을 피하고 성능 개선
                      ...List.generate(items.length, (i) {
                        final item = items[i];
                        return Column(
                          children: [
                            RssItemCard(
                              item: item,
                              onBookmarkChanged: _refreshData,
                            ),
                            if (i < items.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: theme.dividerTheme.color?.withOpacity(
                                  0.5,
                                ),
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
