import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      // 폴더 내 모든 채널의 아이템 가져오기
      _folderItems = _getFolderItems();
    });
  }

  Future<List<RssItem>> _getFolderItems() async {
    // 폴더에 있는 모든 채널의 ID 가져오기
    final channelIds =
        widget.folder.folderChannels
            .map((channel) => channel.channelId)
            .toList();

    if (channelIds.isEmpty) {
      return [];
    }

    try {
      // 해당 채널들의 모든 아이템 가져오기
      final items = await SubscribeService.getSubscribedItemsByChannelIds(
        channelIds,
      );

      // 검색어가 있으면 필터링
      if (_searchQuery.isNotEmpty) {
        return items.where((item) {
          return item.rssTitle.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              item.rssDescription.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
        }).toList();
      }

      return items;
    } catch (e) {
      debugPrint('Error fetching folder items: $e');
      return [];
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
    setState(() {
      _searchQuery = query;
      _folderItems = _getFolderItems();
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
      body: FutureBuilder<List<RssItem>>(
        future: _folderItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState('데이터를 불러오는데 실패했습니다', context);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty ? '폴더에 컨텐츠가 없습니다' : '검색 결과가 없습니다',
              _searchQuery.isEmpty ? Icons.folder_open : Icons.search,
              context,
            );
          }

          // 날짜별로 아이템 그룹화
          final itemsByDate = _groupItemsByDate(snapshot.data!);

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: theme.primaryColor,
            backgroundColor: theme.cardColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: itemsByDate.length,
              itemBuilder: (context, index) {
                final date = itemsByDate.keys.elementAt(index);
                final items = itemsByDate[date]!;
                final formattedDate = _formatDate(date);

                return StickyHeader(
                  header: _buildDateHeader(
                    formattedDate,
                    items.length,
                    context,
                  ),
                  content: Column(
                    children: [
                      // 통일된 RssItemCard 사용
                      ...items.map((item) {
                        return Column(
                          children: [
                            // RssItemCard를 사용하여 디자인 통일
                            RssItemCard(
                              item: item,
                              onBookmarkChanged: _refreshData,
                            ),

                            // 마지막 아이템이 아니면 구분선 추가
                            if (items.indexOf(item) != items.length - 1)
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

                      // 날짜 섹션 구분선 - 마지막 날짜가 아니면 추가
                      if (index < itemsByDate.length - 1)
                        Container(
                          height: 8,
                          color:
                              theme.brightness == Brightness.dark
                                  ? theme.cardColor.withOpacity(0.2)
                                  : theme.cardColor.withOpacity(0.8),
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

  // 날짜별로 아이템을 그룹화하는 함수
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
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
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

  // 날짜 형식 변환
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
      }
      return dateString;
    } catch (e) {
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  Widget _buildEmptyState(String message, IconData icon, BuildContext context) {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
