import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SubscribeDateView extends StatelessWidget {
  final Future<List<RssItem>> items;
  final String searchQuery;
  final VoidCallback onRefresh;

  const SubscribeDateView({
    super.key,
    required this.items,
    required this.searchQuery,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: FutureBuilder<List<RssItem>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // RefreshIndicator가 동작하도록 스크롤 가능한 위젯 반환
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 200),
                Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return _buildErrorState('데이터를 불러오는데 실패했습니다', context);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              searchQuery.isEmpty ? '구독 항목이 없습니다' : '검색 결과가 없습니다',
              searchQuery.isEmpty ? Icons.feed_outlined : Icons.search,
              context,
            );
          }

          // 날짜별로 아이템 그룹화
          final itemsByDate = _groupItemsByDate(snapshot.data!);

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            itemCount: itemsByDate.length,
            itemBuilder: (context, index) {
              final date = itemsByDate.keys.elementAt(index);
              final dayItems = itemsByDate[date]!;
              final formattedDate = _formatDate(date);

              return StickyHeader(
                header: _buildDateHeader(
                  formattedDate,
                  dayItems.length,
                  context,
                ),
                content: Column(
                  children: [
                    // index 기반으로 렌더링하여 indexOf 비용 방지
                    ...List.generate(dayItems.length, (i) {
                      final item = dayItems[i];
                      return Column(
                        children: [
                          RssItemCard(
                            item: item,
                            onBookmarkChanged: onRefresh, // 북마크 변경 시 상위 새로고침
                          ),
                          if (i < dayItems.length - 1)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: theme.dividerTheme.color,
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
          );
        },
      ),
    );
  }

  // 날짜별로 아이템을 그룹화하는 함수 (각 그룹 내에서도 최신순 정렬)
  Map<String, List<RssItem>> _groupItemsByDate(List<RssItem> items) {
    final Map<String, List<RssItem>> grouped = {};

    for (final item in items) {
      DateTime? parsed;
      try {
        parsed = DateTime.parse(item.rssPubDate);
      } catch (_) {
        parsed = null;
      }

      final dateKey =
          parsed == null ? '날짜 없음' : DateFormat('yyyy년 MM월 dd일').format(parsed);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(item);
    }

    // 키(날짜)를 최신순 정렬, '날짜 없음'은 마지막으로
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          if (a == '날짜 없음') return 1;
          if (b == '날짜 없음') return -1;
          try {
            final da = DateFormat('yyyy년 MM월 dd일').parse(a);
            final db = DateFormat('yyyy년 MM월 dd일').parse(b);
            return db.compareTo(da); // 최신 날짜부터
          } catch (_) {
            return 0;
          }
        });

    // 각 날짜 그룹 내 아이템도 발행일 기준 최신순 정렬
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        DateTime pa, pb;
        try {
          pa = DateTime.parse(a.rssPubDate);
        } catch (_) {
          pa = DateTime.fromMillisecondsSinceEpoch(0);
        }
        try {
          pb = DateTime.parse(b.rssPubDate);
        } catch (_) {
          pb = DateTime.fromMillisecondsSinceEpoch(0);
        }
        return pb.compareTo(pa);
      });
    }

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  // 날짜 형식을 더 깔끔하게 변환하는 함수
  String _formatDate(String dateString) {
    if (dateString == '날짜 없음') {
      return dateString;
    }

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

  // 에러 상태도 당겨서 새로고침 되도록 스크롤 가능 위젯으로 구성
  Widget _buildErrorState(String message, BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        Center(
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
                onPressed: onRefresh,
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
      ],
    );
  }

  // 빈 상태도 당겨서 새로고침 되도록 스크롤 가능 위젯으로 구성
  Widget _buildEmptyState(String message, IconData icon, BuildContext context) {
    final theme = Theme.of(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        Center(
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
              if (searchQuery.isEmpty && icon == Icons.feed_outlined) ...[
                const SizedBox(height: 16),
                Text(
                  '아직 구독한 채널이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: subscribeStyle.hintTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RSS 화면에서 채널을 구독해보세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: subscribeStyle.hintTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
