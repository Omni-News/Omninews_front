import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart';

class RssDetailScreen extends StatelessWidget {
  final RssItem rssItem;
  final RssChannel? channel; // 채널 정보는 옵션

  const RssDetailScreen({super.key, required this.rssItem, this.channel});

  @override
  Widget build(BuildContext context) {
    final detailTheme = AppTheme.getNewsDetailStyle(Theme.of(context));
    final textTheme = detailTheme.textTheme;
    final colorScheme = detailTheme.colorScheme;
    final settings = Provider.of<SettingsProvider>(context).settings;

    // 이미지가 있는지 확인
    final hasImage =
        rssItem.rssImageLink != null && rssItem.rssImageLink!.isNotEmpty;

    return Scaffold(
      backgroundColor: detailTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 앱바 (이미지 있을 때만 확장)
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
                          ),
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
                  flexibleSpace:
                      hasImage
                          ? FlexibleSpaceBar(
                            background: Image.network(
                              rssItem.rssImageLink!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: detailTheme.colorScheme.surfaceVariant,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color:
                                          detailTheme
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : null,
                ),

                // 콘텐츠 영역
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // RSS 채널 정보 표시
                        if (channel != null)
                          _buildChannelInfo(channel!, colorScheme, textTheme),

                        const SizedBox(height: 16),

                        // 날짜 및 저자 정보
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(rssItem.rssPubDate),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                              ),
                            ),

                            // 저자 정보가 있으면 표시
                            if (rssItem.rssAuthor != null &&
                                rssItem.rssAuthor!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: colorScheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rssItem.rssAuthor!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.secondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 제목
                        Text(
                          rssItem.rssTitle,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // RSS 본문 콘텐츠
                        Text(
                          _cleanHtml(rssItem.rssDescription),
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 하단 버튼 영역
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                              '${rssItem.rssTitle}\n\n${rssItem.rssLink}',
                            );
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text(
                            '공유하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
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

                    // 원문 보기 버튼
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 최근 읽은 기사 추가 등의 코드를 여기 추가할 수 있음
                            UrlLauncherHelper.openUrl(
                              context,
                              rssItem.rssLink,
                              settings.webOpenMode,
                            );
                          },
                          icon: const Icon(Icons.public, size: 18),
                          label: const Text(
                            '원문 보기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
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

  // RSS 채널 정보 위젯
  Widget _buildChannelInfo(
    RssChannel channel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        // 채널 아이콘/로고 표시
        if (channel.channelImageUrl != null &&
            channel.channelImageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              channel.channelImageUrl!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.rss_feed,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                );
              },
            ),
          )
        else
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.rss_feed, color: colorScheme.primary, size: 16),
          ),

        const SizedBox(width: 10),

        // 채널 이름
        Expanded(
          child: Text(
            channel.channelTitle,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 채널 언어 표시
        if (channel.channelLanguage != null &&
            channel.channelLanguage != 'None')
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              channel.channelLanguage!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }

  // HTML 태그 제거 함수
  String _cleanHtml(String html) {
    // 기본적인 HTML 태그 제거 (더 정교한 구현이 필요하다면 html 패키지 사용 권장)
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return html
        .replaceAll(exp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
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
    final formattedHour =
        hour > 12
            ? hour - 12
            : hour == 0
            ? 12
            : hour;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute ${isPM ? '오후' : '오전'}';
  }
}
