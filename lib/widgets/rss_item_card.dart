import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/models/app_setting.dart';
import 'package:omninews_test_flutter/models/rss_item.dart';
import 'package:omninews_test_flutter/provider/settings_provider.dart';
import 'package:omninews_test_flutter/services/recently_read_service.dart';
import 'package:omninews_test_flutter/services/subscribe_service.dart';
import 'package:intl/intl.dart';
import 'package:omninews_test_flutter/utils/url_launcher_helper.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:omninews_test_flutter/theme/app_theme.dart';

class RssItemCard extends StatefulWidget {
  final RssItem item;
  final VoidCallback? onBookmarkChanged;

  const RssItemCard({
    super.key,
    required this.item,
    this.onBookmarkChanged,
  });

  @override
  State<RssItemCard> createState() => _RssItemCardState();
}

class _RssItemCardState extends State<RssItemCard> {
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
        success =
            await SubscribeService.removeLocalBookmark(widget.item.rssLink);
      } else {
        success = await SubscribeService.addLocalBookmark(widget.item);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });

        // 북마크 상태가 변경되면 콜백 호출
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
            content: Text('오류가 발생했습니다: $e'),
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

  // URL이 유효한지 확인
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 설명 텍스트 자르기
  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final rssTheme = AppTheme.rssThemeOf(context);
    final bool hasValidImage = _isValidImageUrl(widget.item.rssImageLink);
    final settings = Provider.of<SettingsProvider>(context).settings;
    final showImage =
        hasValidImage && settings.viewMode == ViewMode.textAndImage;

    return InkWell(
      onTap: () {
        RecentlyReadService.addRssItem(widget.item);
        UrlLauncherHelper.openUrl(
            context, widget.item.rssLink, settings.webOpenMode);
      },
      child: Padding(
        padding: cardStyle.cardPadding,
        child: settings.viewMode == ViewMode.textOnly
            ? _buildTextOnlyLayout(cardStyle, rssTheme, theme)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextContent(cardStyle, rssTheme, theme),
                  ),

                  // 여백
                  if (showImage) const SizedBox(width: 12),

                  // 우측: 썸네일 이미지 (있을 경우)
                  if (showImage) _buildThumbnail(),
                ],
              ),
      ),
    );
  }

  // 썸네일 이미지 위젯
  Widget _buildThumbnail() {
    final theme = Theme.of(context);

    // 고유한 Hero 태그 생성
    final String heroTag = 'rss_image_${widget.item.rssLink}';

    return SizedBox(
      width: 100,
      height: 75,
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: widget.item.rssImageLink!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[600]
                      : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              child: Icon(
                Icons.image_not_supported_outlined,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey,
                size: 24,
              ),
            ),
            errorListener: (_) => {}, // 로그 출력 억제
          ),
        ),
      ),
    );
  }

  // URL에서 도메인 이름 추출
  String _getSourceName(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      // www. 제거
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
      return 'source';
    }
  }

// 텍스트 전용 레이아웃
  Widget _buildTextOnlyLayout(NewsCardStyleExtension cardStyle,
      RssThemeExtension rssTheme, ThemeData theme) {
    return _buildTextContent(cardStyle, rssTheme, theme);
  }

// 텍스트 콘텐츠 부분
  Widget _buildTextContent(NewsCardStyleExtension cardStyle,
      RssThemeExtension rssTheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 북마크 버튼
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.item.rssTitle,
                style: cardStyle.titleStyle,
                maxLines: 2,
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
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
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
          _truncateDescription(widget.item.rssDescription),
          style: cardStyle.descriptionStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // 출처 및 날짜
        Row(
          children: [
            // 소스 도메인 표시
            Text(
              _getSourceName(widget.item.rssLink),
              style: cardStyle.sourceStyle.copyWith(
                color: rssTheme.linkColor,
              ),
            ),
            const SizedBox(width: 8),

            // 게시일 표시
            Text(
              _formatDate(widget.item.rssPubDate),
              style: cardStyle.dateStyle,
            ),
          ],
        ),
      ],
    );
  }
}
