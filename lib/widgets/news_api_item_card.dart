import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart';
import 'package:provider/provider.dart';
import 'package:html/parser.dart' show parse;
import 'package:html_unescape/html_unescape.dart';

class NewsApiItemCard extends StatefulWidget {
  final NewsApi news;
  final VoidCallback? onBookmarkChanged;
  final bool isAlreadyBookmarked;

  const NewsApiItemCard({
    super.key,
    required this.news,
    this.onBookmarkChanged,
    this.isAlreadyBookmarked = false,
  });

  @override
  State<NewsApiItemCard> createState() => _NewsApiItemCardState();
}

class _NewsApiItemCardState extends State<NewsApiItemCard> {
  bool _isBookmarked = false;
  bool _isLoading = false;
  final HtmlUnescape _htmlUnescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    if (widget.isAlreadyBookmarked) {
      _isBookmarked = true;
    } else {
      _checkBookmarkStatus();
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked =
        await NewsBookmarkService.isAnyBookmarked(widget.news.newsOriginalLink);
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isBookmarked) {
        success = await NewsBookmarkService.removeNewsApiBookmark(
            widget.news.newsOriginalLink);
      } else {
        success = await NewsBookmarkService.addNewsApiBookmark(widget.news);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });

        if (widget.onBookmarkChanged != null) {
          widget.onBookmarkChanged!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? '북마크에 추가되었습니다' : '북마크에서 제거되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('북마크 변경 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openNewsLink(AppSettings settings) {
    RecentlyReadService.addApiNews(widget.news);
    // 설정된 웹 열기 방식을 사용하여 URL 열기
    UrlLauncherHelper.openUrl(
        context, widget.news.newsOriginalLink, settings.webOpenMode);
  }

  @override
  Widget build(BuildContext context) {
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    // 뉴스 제목과 설명에서 HTML 태그와 엔티티 처리
    final cleanTitle = _cleanHtmlContent(widget.news.newsTitle);
    final cleanDescription = _cleanHtmlContent(widget.news.newsDescription);

    return InkWell(
      onTap: () => _openNewsLink(settings), // 설정에 따라 URL 열기
      child: Padding(
        padding: cardStyle.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 뉴스 제목과 북마크 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    cleanTitle,
                    style: cardStyle.titleStyle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.primaryColor,
                          ),
                        )
                      : Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isBookmarked
                              ? cardStyle.bookmarkActiveColor
                              : cardStyle.bookmarkInactiveColor,
                          size: 20,
                        ),
                  onPressed: _toggleBookmark,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 뉴스 내용 요약
            Text(
              _truncateDescription(cleanDescription),
              style: cardStyle.descriptionStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // 출처 및 날짜
            Row(
              children: [
                Text(
                  _extractDomain(widget.news.newsOriginalLink),
                  style: cardStyle.sourceStyle,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.news.newsPubDate),
                  style: cardStyle.dateStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // HTML 태그와 엔티티를 모두 처리하는 향상된 함수
  String _cleanHtmlContent(String htmlString) {
    if (htmlString.isEmpty) {
      return '';
    }

    try {
      // 먼저 HTML 파싱하여 태그 제거
      final document = parse(htmlString);
      String plainText = document.body?.text ?? '';

      // HTML 엔티티 디코딩 (예: &quot; -> ")
      plainText = _htmlUnescape.convert(plainText);

      // 추가 정리 (줄바꿈, 공백 처리)
      plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();

      return plainText;
    } catch (e) {
      // 파싱에 실패한 경우 간단한 방법으로 처리
      String result = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
      result = _htmlUnescape.convert(result);
      return result.trim();
    }
  }

  // 설명 텍스트 자르기
  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

  // 도메인 추출
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return url;
    }
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
}
