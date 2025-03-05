import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';
import 'package:flutter/services.dart';

class RssDetailScreen extends StatelessWidget {
  final News news;

  const RssDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 스크롤 가능한 내용
            CustomScrollView(
              slivers: [
                // 앱바
                SliverAppBar(
                  expandedHeight: news.newsImageLink.isNotEmpty ? 240.0 : 0,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark_border, color: Colors.black87),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('뉴스가 저장되었습니다')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: news.newsImageLink.isNotEmpty
                        ? Image.network(
                            news.newsImageLink,
                            fit: BoxFit.cover,
                          )
                        : Container(color: Colors.grey[200]),
                  ),
                ),

                // 기사 내용
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 출처 및 날짜
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                news.newsSource,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(news.newsPubDate),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 제목
                        Text(
                          news.newsTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 본문 설명
                        Text(
                          news.newsDescription,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.black87,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                        
                        // 원문 링크 표시 부분 제거됨
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // 하단 고정 버튼 영역 - 두 개의 버튼으로 분할
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 공유하기 버튼
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            Share.share('${news.newsTitle}\n\n${news.newsLink}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '공유하기',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // 원문 보기 버튼
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ElevatedButton(
                          onPressed: () => _launchUrl(news.newsLink),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.public, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '원문 보기',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // URL 실행 함수
  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw '웹사이트를 열 수 없습니다: $url';
      }
    } catch (e) {
      print('URL 실행 오류: $e');
    }
  }

  // 날짜 포맷팅 함수
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}년 ${date.month}월 ${date.day}일 ${_formatTime(date.hour, date.minute)}';
    } catch (e) {
      return dateStr;
    }
  }

  // 시간 포맷팅 함수
  String _formatTime(int hour, int minute) {
    final isPM = hour >= 12;
    final formattedHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute ${isPM ? '오후' : '오전'}';
  }
}
