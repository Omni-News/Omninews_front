import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/screens/rss_detail_screen.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';

class RssItemCard extends StatefulWidget {
  final RssItem item;
  final VoidCallback? onBookmarkChanged;

  const RssItemCard({super.key, required this.item, this.onBookmarkChanged});

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

  @override
  void didUpdateWidget(covariant RssItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 아이템으로 바뀌면 북마크 상태 재확인
    if (oldWidget.item.rssLink != widget.item.rssLink) {
      _checkBookmarkStatus();
    }
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final isBookmarked = await SubscribeService.isBookmarked(
        widget.item.rssLink,
      );
      if (!mounted) return;
      setState(() => _isBookmarked = isBookmarked);
    } catch (_) {
      // 조용히 실패 (네트워크/저장소 오류 등)
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      if (_isBookmarked) {
        success = await SubscribeService.removeLocalBookmark(
          widget.item.rssLink,
        );
      } else {
        success = await SubscribeService.addLocalBookmark(widget.item);
      }

      if (!mounted) return;

      if (success) {
        setState(() => _isBookmarked = !_isBookmarked);

        // 부모에 알림
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
          content: Text('오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // URL이 유효한지 확인
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // 설명 텍스트 전처리 및 자르기 (간단한 HTML 제거 포함)
  String _truncateDescription(String description, {int max = 100}) {
    final cleaned = _cleanHtml(description);
    if (cleaned.length > max) {
      return '${cleaned.substring(0, max)}...';
    }
    return cleaned;
  }

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

  // URL에서 도메인 이름 추출
  String _getSourceName(String url) {
    try {
      final uri = Uri.parse(url);
      var domain = uri.host;
      if (domain.startsWith('www.')) domain = domain.substring(4);
      return domain;
    } catch (_) {
      return 'source';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final rssTheme = AppTheme.rssThemeOf(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    final hasValidImage = _isValidImageUrl(widget.item.rssImageLink);
    final showImage =
        hasValidImage && settings.viewMode == ViewMode.textAndImage;

    return InkWell(
      onTap: _handleTap,
      child: Padding(
        padding: cardStyle.cardPadding,
        child:
            settings.viewMode == ViewMode.textOnly
                ? _buildTextOnlyLayout(cardStyle, rssTheme, theme)
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextContent(cardStyle, rssTheme, theme),
                    ),
                    if (showImage) const SizedBox(width: 12),
                    if (showImage) _buildThumbnail(),
                  ],
                ),
      ),
    );
  }

  void _handleTap() {
    // 읽은 기록 추가
    RecentlyReadService.addRssItem(widget.item);

    // 순위 업데이트
    RssService.updateRssRank(widget.item.rssId);

    // 상세 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RssDetailScreen(rssItem: widget.item),
      ),
    );
  }

  // 썸네일 이미지 위젯
  Widget _buildThumbnail() {
    final theme = Theme.of(context);
    final imageUrl = widget.item.rssImageLink!;
    final String heroTag = 'rss_image_${widget.item.rssLink}'; // 고유한 Hero 태그

    return SizedBox(
      width: 100,
      height: 75,
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color:
                          theme.brightness == Brightness.dark
                              ? Colors.grey[600]
                              : Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color:
                        theme.brightness == Brightness.dark
                            ? Colors.grey[600]
                            : Colors.grey,
                    size: 24,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  // 텍스트 전용 레이아웃
  Widget _buildTextOnlyLayout(
    NewsCardStyleExtension cardStyle,
    RssThemeExtension rssTheme,
    ThemeData theme,
  ) {
    return _buildTextContent(cardStyle, rssTheme, theme);
  }

  // 텍스트 콘텐츠 부분
  Widget _buildTextContent(
    NewsCardStyleExtension cardStyle,
    RssThemeExtension rssTheme,
    ThemeData theme,
  ) {
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
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color:
                            _isBookmarked
                                ? cardStyle.bookmarkActiveColor
                                : cardStyle.bookmarkInactiveColor,
                        size: 20,
                      ),
              onPressed: _toggleBookmark,
              tooltip: _isBookmarked ? '북마크 해제' : '북마크',
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
            Flexible(
              child: Text(
                _getSourceName(widget.item.rssLink),
                style: cardStyle.sourceStyle.copyWith(
                  color: rssTheme.linkColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
