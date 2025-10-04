import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart';
import 'package:provider/provider.dart';

class SearchRssItemCard extends StatefulWidget {
  final RssItem item;
  final VoidCallback? onBookmarkChanged;

  const SearchRssItemCard({
    super.key,
    required this.item,
    this.onBookmarkChanged,
  });

  @override
  State<SearchRssItemCard> createState() => _SearchRssItemCardState();
}

class _SearchRssItemCardState extends State<SearchRssItemCard> {
  bool _isBookmarked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  // 동일 위젯 재사용 시 다른 item이 들어오면 상태 동기화
  @override
  void didUpdateWidget(covariant SearchRssItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.rssLink != widget.item.rssLink) {
      _checkBookmarkStatus();
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await SubscribeService.isBookmarked(
      widget.item.rssLink,
    );
    if (!mounted) return;
    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isBookmarked) {
        success = await SubscribeService.removeBookmark(widget.item.rssLink);
      } else {
        success = await SubscribeService.addBookmark(widget.item);
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

  void _openLink(AppSettings settings) {
    RecentlyReadService.addRssItem(widget.item);
    UrlLauncherHelper.openUrl(
      context,
      widget.item.rssLink,
      settings.webOpenMode,
    );
  }

  String _hostOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final searchStyle = AppTheme.searchStyleOf(context);
    final rssTheme = AppTheme.rssThemeOf(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    final hasImage =
        widget.item.rssImageLink != null &&
        widget.item.rssImageLink!.isNotEmpty;
    final showImage = hasImage && settings.viewMode == ViewMode.textAndImage;

    final host = _hostOf(widget.item.rssLink);

    return InkWell(
      onTap: () => _openLink(settings),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 (RSS)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: searchStyle.rssTagBackground,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: searchStyle.rssTagBorder, width: 1),
              ),
              child: Text(
                'RSS',
                style: TextStyle(
                  fontSize: 10,
                  color: searchStyle.rssTagText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 제목 + 북마크 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.rssTitle,
                    style: cardStyle.titleStyle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: _isBookmarked ? '북마크 해제' : '북마크',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      _isLoading
                          ? SizedBox(
                            width: 18,
                            height: 18,
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

            // 설명 (HTML 제거 후 축약)
            Text(
              _truncate(_cleanHtml(widget.item.rssDescription), 160),
              style: cardStyle.descriptionStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // 출처(도메인) · 날짜
            Row(
              children: [
                if (host.isNotEmpty)
                  Flexible(
                    child: Text(
                      host,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: rssTheme.linkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (host.isNotEmpty) ...[
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
                ],
                Text(
                  _formatDate(widget.item.rssPubDate),
                  style: cardStyle.dateStyle,
                ),
              ],
            ),

            // 이미지 (옵션)
            if (showImage) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.item.rssImageLink!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 간단한 HTML 제거
  String _cleanHtml(String html) {
    final exp = RegExp(r'<[^>]*>', multiLine: true);
    return html
        .replaceAll(exp, ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max).trim()}...';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}분 전';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}시간 전';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}일 전';
      } else {
        return DateFormat('MM/dd').format(date);
      }
    } catch (_) {
      return dateStr;
    }
  }
}
