import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/screens/news_detail_screen.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';

class NewsItemCard extends StatefulWidget {
  final News news;
  final VoidCallback? onBookmarkChanged;

  const NewsItemCard({super.key, required this.news, this.onBookmarkChanged});

  @override
  State<NewsItemCard> createState() => _NewsItemCardState();
}

class _NewsItemCardState extends State<NewsItemCard> {
  bool _isBookmarked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  @override
  void didUpdateWidget(covariant NewsItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.news.newsLink != widget.news.newsLink) {
      _checkBookmarkStatus();
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await NewsBookmarkService.isAnyBookmarked(
      widget.news.newsLink,
    );
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
        success = await NewsBookmarkService.removeNewsBookmark(
          widget.news.newsLink,
        );
      } else {
        success = await NewsBookmarkService.addNewsBookmark(widget.news);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });

        // 북마크 변경 콜백 실행
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

  // 뉴스 상세 페이지로 이동하는 메서드
  void _openNewsDetail() {
    // 최근 읽은 뉴스에 추가
    RecentlyReadService.addNews(widget.news);

    // NewsDetailScreen으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: widget.news),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final bool hasValidImage = _isValidImageUrl(widget.news.newsImageLink);

    final settings = Provider.of<SettingsProvider>(context).settings;
    // 뷰 모드에 따라 이미지 표시 여부 결정
    final showImage =
        hasValidImage && settings.viewMode == ViewMode.textAndImage;

    return InkWell(
      onTap: _openNewsDetail, // URL 열기 대신 상세 페이지로 이동
      child: Padding(
        padding: cardStyle.cardPadding,
        child:
            settings.viewMode == ViewMode.textOnly
                ? _buildTextOnlyLayout(theme, cardStyle)
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 좌측: 텍스트 정보
                    Expanded(
                      flex: 3,
                      child: _buildNewsContent(theme, cardStyle),
                    ),

                    // 여백과 이미지 (이미지 모드이고 유효한 이미지가 있을 경우)
                    if (showImage) ...[
                      const SizedBox(width: 12),
                      _buildThumbnail(),
                    ],
                  ],
                ),
      ),
    );
  }

  // 텍스트 전용 레이아웃
  Widget _buildTextOnlyLayout(
    ThemeData theme,
    NewsCardStyleExtension cardStyle,
  ) {
    return _buildNewsContent(theme, cardStyle);
  }

  // 뉴스 콘텐츠 (텍스트 부분)
  Widget _buildNewsContent(ThemeData theme, NewsCardStyleExtension cardStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 북마크 버튼
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.news.newsTitle,
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
              tooltip: _isBookmarked ? '북마크 해제' : '북마크',
              onPressed: _toggleBookmark,
            ),
          ],
        ),

        const SizedBox(height: 6),

        // 뉴스 내용 요약
        Text(
          _truncateDescription(widget.news.newsDescription),
          style: cardStyle.descriptionStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // 출처 및 날짜
        Row(
          children: [
            Text(widget.news.newsSource, style: cardStyle.sourceStyle),
            const SizedBox(width: 8),
            Text(
              _formatDate(widget.news.newsPubDate),
              style: cardStyle.dateStyle,
            ),
          ],
        ),
      ],
    );
  }

  // 썸네일 이미지 위젯
  Widget _buildThumbnail() {
    final theme = Theme.of(context);

    return SizedBox(
      width: 100,
      height: 75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Hero(
          // Hero 태그를 고유하게 수정하여 충돌 방지
          tag: 'news_item_list_${widget.news.newsLink}_image',
          child: Image.network(
            widget.news.newsImageLink,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color:
                    theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color:
                    theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey[600]
                          : Colors.grey[400],
                  size: 24,
                ),
              );
            },
          ),
        ),
      ),
    );
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
