import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
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

  @override
  void didUpdateWidget(covariant NewsApiItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 아이템으로 변경되면 상태 동기화
    if (oldWidget.news.newsOriginalLink != widget.news.newsOriginalLink) {
      if (widget.isAlreadyBookmarked) {
        setState(() {
          _isBookmarked = true;
        });
      } else {
        _checkBookmarkStatus();
      }
    }
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final isBookmarked = await NewsBookmarkService.isAnyBookmarked(
        widget.news.newsOriginalLink,
      );
      if (!mounted) return;
      setState(() {
        _isBookmarked = isBookmarked;
      });
    } catch (_) {
      // 조용히 실패
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
          widget.news.newsOriginalLink,
        );
      } else {
        success = await NewsBookmarkService.addNewsApiBookmark(widget.news);
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });

        widget.onBookmarkChanged?.call();

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('북마크 변경 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
    UrlLauncherHelper.openUrl(
      context,
      widget.news.newsOriginalLink,
      settings.webOpenMode,
    );
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
      onTap: () => _openNewsLink(settings),
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
                  tooltip: _isBookmarked ? '북마크 해제' : '북마크',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      _isLoading
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
                            color:
                                _isBookmarked
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
              _truncateDescription(cleanDescription, 160),
              style: cardStyle.descriptionStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // 출처 및 날짜
            Row(
              children: [
                Flexible(
                  child: Text(
                    _extractDomain(widget.news.newsOriginalLink),
                    style: cardStyle.sourceStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  // HTML 태그와 엔티티를 모두 처리하는 함수
  String _cleanHtmlContent(String htmlString) {
    if (htmlString.isEmpty) return '';
    try {
      final document = parse(htmlString);
      String plainText = document.body?.text ?? '';
      plainText = _htmlUnescape.convert(plainText);
      plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
      return plainText;
    } catch (_) {
      String result = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
      result = _htmlUnescape.convert(result);
      return result.trim();
    }
  }

  // 설명 텍스트 자르기
  String _truncateDescription(String description, [int max = 100]) {
    if (description.length > max) {
      return '${description.substring(0, max)}...';
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
    } catch (_) {
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
    } catch (_) {
      return dateStr;
    }
  }
}
