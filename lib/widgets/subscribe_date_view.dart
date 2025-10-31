import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class SubscribeDateView extends StatelessWidget {
  // --- ▼ 1. PAGENATION: props 변경 ---
  // Future<List<RssItem>> -> List<RssItem>
  final List<RssItem> items;
  final String searchQuery;
  final VoidCallback onRefresh;
  // PAGENATION: 새 props 추가
  final bool isLoading;
  final ScrollController controller;
  final bool hasMore;
  // --- ▲ 1. PAGENATION: props 변경 ---

  const SubscribeDateView({
    super.key,
    required this.items,
    required this.searchQuery,
    required this.onRefresh,
    // --- ▼ 2. PAGENATION: 생성자 변경 ---
    required this.isLoading,
    required this.controller,
    required this.hasMore,
    // --- ▲ 2. PAGENATION: 생성자 변경 ---
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- ▼ 3. PAGENATION: FutureBuilder 제거, 새 로직 적용 ---
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor,
      // 데이터가 비어있고, 로딩 중일 때 (초기 로딩)
      child:
          (isLoading && items.isEmpty)
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              // 로딩이 끝났는데 데이터가 없을 때 (빈 상태)
              : (!isLoading && items.isEmpty)
              ? _buildEmptyState(
                searchQuery.isEmpty ? '구독 항목이 없습니다' : '검색 결과가 없습니다',
                searchQuery.isEmpty ? Icons.feed_outlined : Icons.search,
                context,
              )
              // 데이터가 있을 때
              : _buildListView(context, theme),
    );
    // --- ▲ 3. PAGENATION: FutureBuilder 제거 ---
  }

  // --- ▼ 4. PAGENATION: ListView.builder를 별도 메서드로 분리 ---
  Widget _buildListView(BuildContext context, ThemeData theme) {
    // 날짜별로 아이템 그룹화 (snapshot.data! 대신 props.items 사용)
    final itemsByDate = _groupItemsByDate(items);

    return ListView.builder(
      // PAGENATION: 부모로부터 받은 컨트롤러 연결
      controller: controller,
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      // PAGENATION: '더 보기' 로딩 인디케이터를 위해 +1
      itemCount: itemsByDate.length + 1,
      itemBuilder: (context, index) {
        // PAGENATION: 마지막 아이템(로딩 인디케이터) 처리
        if (index == itemsByDate.length) {
          if (hasMore) {
            // 로딩 중이고 더 많은 아이템이 있으면 인디케이터 표시
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            // 더 이상 아이템이 없으면 아무것도 표시 안 함
            return const SizedBox.shrink();
          }
        }

        // --- 기존 StickyHeader 렌더링 로직 ---
        final date = itemsByDate.keys.elementAt(index);
        final dayItems = itemsByDate[date]!;
        final formattedDate = _formatDate(date);

        return StickyHeader(
          header: _buildDateHeader(formattedDate, dayItems.length, context),
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
  }
  // --- ▲ 4. PAGENATION: ListView.builder를 별도 메서드로 분리 ---

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

  // --- 5. PAGENATION: _buildErrorState 제거 ---
  // 에러 처리는 이제 부모 위젯(SubscribeScreen)에서 담당하므로
  // 이 위젯에서는 더 이상 필요하지 않습니다.

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
