import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/models/app_setting.dart';
import 'package:omninews_test_flutter/models/news.dart';
import 'package:omninews_test_flutter/services/recently_read_service.dart';
import 'package:share/share.dart';
import 'package:omninews_test_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:omninews_test_flutter/provider/settings_provider.dart';
import 'package:omninews_test_flutter/utils/url_launcher_helper.dart';

class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    // 뉴스 상세 화면에 최적화된 테마 스타일 적용
    final detailTheme = AppTheme.getNewsDetailStyle(Theme.of(context));
    final textTheme = detailTheme.textTheme;
    final colorScheme = detailTheme.colorScheme;

    // 설정 프로바이더 가져오기
    final settings = Provider.of<SettingsProvider>(context).settings;

    // 이미지 표시 여부 결정 (뷰 모드에 따라)
    final hasImage = news.newsImageLink.isNotEmpty &&
        settings.viewMode == ViewMode.textAndImage;

    return Scaffold(
      backgroundColor: detailTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 스크롤 가능한 내용
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 앱바 (뷰 모드에 따라 이미지 표시)
                SliverAppBar(
                  expandedHeight: hasImage ? 240.0 : 0,
                  pinned: true,
                  backgroundColor: detailTheme.appBarTheme.backgroundColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: detailTheme.cardColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: detailTheme.appBarTheme.iconTheme?.color,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: hasImage
                      ? FlexibleSpaceBar(
                          background: Image.network(
                            news.newsImageLink,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: detailTheme.colorScheme.surfaceVariant,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 48,
                                    color: detailTheme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : null,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                news.newsSource,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(news.newsPubDate),
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 제목
                        Text(
                          news.newsTitle,
                          style: textTheme.titleLarge,
                        ),

                        const SizedBox(height: 20),

                        // 본문 설명
                        Text(
                          news.newsDescription,
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 하단 고정 버튼 영역
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: detailTheme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: detailTheme.shadowColor,
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
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Share.share(
                                '${news.newsTitle}\n\n${news.newsLink}');
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text(
                            '공유하기',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                detailTheme.brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            foregroundColor:
                                detailTheme.brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 원문 보기 버튼 (설정에 따라 열기 방식 적용)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            RecentlyReadService.addNews(news);
                            // 설정에 따라 URL 열기
                            UrlLauncherHelper.openUrl(
                                context, news.newsLink, settings.webOpenMode);
                          },
                          icon: const Icon(Icons.public, size: 18),
                          label: const Text(
                            '원문 보기',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: detailTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
    final formattedHour = hour > 12
        ? hour - 12
        : hour == 0
            ? 12
            : hour;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute ${isPM ? '오후' : '오전'}';
  }
}
