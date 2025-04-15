import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_test_flutter/models/rss_item.dart';
import 'package:omninews_test_flutter/provider/settings_provider.dart';
import 'package:omninews_test_flutter/services/recently_read_service.dart';
import 'package:omninews_test_flutter/services/subscribe_service.dart';
import 'package:omninews_test_flutter/theme/app_theme.dart';
import 'package:omninews_test_flutter/models/app_setting.dart';
import 'package:omninews_test_flutter/utils/url_launcher_helper.dart';
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

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked =
        await SubscribeService.isBookmarked(widget.item.rssLink);
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
        success = await SubscribeService.removeBookmark(widget.item.rssLink);
      } else {
        success = await SubscribeService.addBookmark(widget.item);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });

        // 북마크 변경 시 콜백 실행
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

  void _openLink(AppSettings settings) {
    RecentlyReadService.addRssItem(widget.item);
    // 설정된 웹 열기 방식으로 URL 열기
    UrlLauncherHelper.openUrl(
        context, widget.item.rssLink, settings.webOpenMode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final searchStyle = AppTheme.searchStyleOf(context);
    final rssTheme = AppTheme.rssThemeOf(context);

    final settings = Provider.of<SettingsProvider>(context).settings;

    // 미래의 이미지 표시 기능을 위한 처리
    final hasImage = widget.item.rssImageLink != null &&
        widget.item.rssImageLink!.isNotEmpty;
    final showImage = hasImage && settings.viewMode == ViewMode.textAndImage;

    return InkWell(
      onTap: () => _openLink(settings),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 표시 (RSS)
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

            // 제목과 북마크 버튼
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
                const SizedBox(width: 4),
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

            // 설명
            Text(
              _truncateDescription(widget.item.rssDescription),
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
                    widget.item.rssTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: rssTheme.linkColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.item.rssPubDate),
                  style: cardStyle.dateStyle,
                ),
              ],
            ),

            // 이미지가 있고 뷰 모드가 텍스트+이미지일 때만 이미지 표시
            // 현재는 RSS 아이템에 이미지가 없지만 미래에 추가될 경우를 대비
            if (showImage && widget.item.rssImageLink != null) ...[
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
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
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

  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

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
