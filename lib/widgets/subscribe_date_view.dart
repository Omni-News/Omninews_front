import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:sticky_headers/sticky_headers.dart';

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
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: FutureBuilder<List<RssItem>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState('데이터를 불러오는데 실패했습니다', context);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              searchQuery.isEmpty ? '구독 항목이 없습니다' : '검색 결과가 없습니다',
              searchQuery.isEmpty ? Icons.feed_outlined : Icons.search,
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
                    ...items.map((item) => Column(
                          children: [
                            RssItemCard(item: item),
                            // 마지막 아이템이 아니면 구분선 추가
                            if (items.indexOf(item) != items.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Colors.grey.shade200,
                              ),
                          ],
                        )),

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

  // 날짜 형식을 더 깔끔하게 변환하는 함수
  String _formatDate(String dateString) {
    if (dateString == '날짜 없음') {
      return dateString;
    }

    try {
      final now = DateTime.now();
      final date = DateFormat('yyyy년 MM월 dd일').parse(dateString);
      final difference = now.difference(date).inDays;

      // 오늘, 어제만 특별히 처리
      if (difference == 0) {
        return '오늘';
      } else if (difference == 1) {
        return '어제';
      }
      // 나머지는 모두 yyyy년 MM월 dd일 형식으로 표현
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

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
              color: Colors.indigo[700], // 진한 남색으로 변경하여 본문과 구분
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

  Widget _buildErrorState(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[800],
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
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (searchQuery.isEmpty && icon == Icons.feed_outlined) ...[
            const SizedBox(height: 16),
            const Text(
              '아직 구독한 채널이 없습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'RSS 화면에서 채널을 구독해보세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
