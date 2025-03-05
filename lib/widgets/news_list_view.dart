import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/screens/news_detail_screen.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅용

class NewsListView extends StatelessWidget {
  final Future<List<News>> newsList;

  const NewsListView({super.key, required this.newsList});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<News>>(
      future: newsList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: Colors.blue,
          ));
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load news',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          List<News> data = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RssDetailScreen(news: data[index]),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측: 텍스트 정보
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 뉴스 제목
                            Text(
                              data[index].newsTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // 뉴스 내용 요약
                            Text(
                              _truncateDescription(data[index].newsDescription),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // 출처 및 날짜
                            Row(
                              children: [
                                Text(
                                  data[index].newsSource,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(data[index].newsPubDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 여백
                      const SizedBox(width: 12),

                      // 우측: 썸네일 이미지
                      _buildThumbnail(data[index].newsImageLink),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.newspaper, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  '뉴스가 없습니다',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // 썸네일 이미지 위젯
  Widget _buildThumbnail(String imageUrl) {
    return SizedBox(
      width: 100,
      height: 75,
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: Colors.grey,
                size: 30,
              ),
            ),
    );
  }

  // 날짜 포맷팅
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return DateFormat('MM/dd').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  // 설명 텍스트 자르기
  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }
}

