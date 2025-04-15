import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/recently_read_item.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:omninews_flutter/widgets/news_item_card.dart';
import 'package:provider/provider.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:html/parser.dart' show parse; // HTML 파싱 추가

class RecentlyReadScreen extends StatefulWidget {
  const RecentlyReadScreen({super.key});

  @override
  State<RecentlyReadScreen> createState() => _RecentlyReadScreenState();
}

class _RecentlyReadScreenState extends State<RecentlyReadScreen> {
  late Future<List<RecentlyReadItem>> _items;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = RecentlyReadService.getRecentlyReadItems();
    });
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: const Text('모든 최근 읽은 글 기록을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await RecentlyReadService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('최근 읽은 글 기록이 삭제되었습니다'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadItems();
      }
    }
  }

  // HTML 태그를 제거하는 함수
  String _stripHtmlTags(String htmlString) {
    if (htmlString.isEmpty) {
      return '';
    }

    try {
      final document = parse(htmlString);
      final String plainText = parse(document.body!.text).documentElement!.text;
      return plainText.trim();
    } catch (e) {
      // HTML 파싱에 실패한 경우 간단한 정규식으로 태그 제거 시도
      return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }
  }

  // URL에서 도메인만 추출하는 함수
  String _getDomainFromUrl(String url) {
    if (url.isEmpty) {
      return '';
    }

    try {
      final uri = Uri.parse(url);
      String domain = uri.host;

      // www. 접두사 제거
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }

      return domain;
    } catch (e) {
      // URL 파싱에 실패한 경우 원본 URL 반환
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    // 설정 프로바이더 가져오기
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('최근 읽은 글'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearHistory,
            tooltip: '기록 삭제',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadItems();
        },
        child: FutureBuilder<List<RecentlyReadItem>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return _buildErrorState('데이터를 불러오는데 실패했습니다');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            // HTML 태그를 제거하고 처리된 아이템 목록 생성
            final processedItems = snapshot.data!.map((item) {
              // 제목과 설명에서 HTML 태그 제거
              final cleanTitle = _stripHtmlTags(item.title);
              final cleanDescription = _stripHtmlTags(item.description);

              // 도메인 추출
              final domain = _getDomainFromUrl(item.link);

              // 새 아이템 생성 (복사본)
              return RecentlyReadItem(
                id: item.id,
                title: cleanTitle,
                description: cleanDescription,
                link: item.link, // 원본 링크는
                source: domain, // 도메인만 표시하도록 변경
                pubDate: item.pubDate,
                type: item.type,
                readAt: item.readAt,
                imageUrl: item.imageUrl,
              );
            }).toList();

            // 날짜별로 그룹화
            final itemsByDate = _groupItemsByDate(processedItems);

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
                      ...items.map((item) => _buildRecentItem(item, settings)),
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
      ),
    );
  }

  // 날짜별로 아이템 그룹화
  Map<String, List<RecentlyReadItem>> _groupItemsByDate(
      List<RecentlyReadItem> items) {
    final Map<String, List<RecentlyReadItem>> grouped = {};

    for (final item in items) {
      final dateString = DateFormat('yyyy년 MM월 dd일').format(item.readAt);

      if (!grouped.containsKey(dateString)) {
        grouped[dateString] = [];
      }
      grouped[dateString]!.add(item);
    }

    // 날짜순 정렬 (최신순)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
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

  // 날짜 형식화
  String _formatDate(String dateString) {
    final now = DateTime.now();

    try {
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

  // 날짜 헤더 위젯
  Widget _buildDateHeader(String date, int itemCount) {
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

  // 최근 읽은 아이템 위젯
  Widget _buildRecentItem(RecentlyReadItem item, AppSettings settings) {
    // 각 카드에 뷰모드와 웹오픈모드 설정 전달
    if (item.type == ReadItemType.rss) {
      final rssItem = item.toRssItem();
      return RssItemCard(
        item: rssItem,
      );
    } else {
      final news = item.toNews();
      return NewsItemCard(
        news: news,
      );
    }
  }

  // 에러 상태 위젯
  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
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
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadItems,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: theme.primaryColor,
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

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 64,
              color: subscribeStyle.emptyIconColor,
            ),
            const SizedBox(height: 20),
            Text(
              '최근 읽은 글이 없습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: subscribeStyle.emptyTextColor,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '뉴스나 RSS 피드의 글을 읽으면\n이곳에 저장됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: subscribeStyle.emptyTextColor.withOpacity(0.8),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
