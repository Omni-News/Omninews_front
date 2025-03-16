import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/screens/news_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';

class NewsListView extends StatefulWidget {
  final Future<List<News>> newsList;
  final VoidCallback? onBookmarkChanged;

  const NewsListView({
    super.key,
    required this.newsList,
    this.onBookmarkChanged,
  });

  @override
  State<NewsListView> createState() => _NewsListViewState();
}

class _NewsListViewState extends State<NewsListView> {
  final Map<String, bool> _bookmarkStatus = {};
  final Map<String, bool> _loadingStatus = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);
    final settings = Provider.of<SettingsProvider>(context).settings;

    return FutureBuilder<List<News>>(
      future: widget.newsList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.primaryColor,
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: subscribeStyle.errorIconColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load news',
                    style: TextStyle(
                      color: subscribeStyle.emptyTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: subscribeStyle.hintTextColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          List<News> data = snapshot.data!;

          // 각 뉴스의 북마크 상태 확인
          for (var news in data) {
            if (!_bookmarkStatus.containsKey(news.newsLink)) {
              _checkBookmarkStatus(news.newsLink);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final news = data[index];
              final hasImage = news.newsImageLink.isNotEmpty;
              final showImage =
                  hasImage && settings.viewMode == ViewMode.textAndImage;

              return InkWell(
                onTap: () {
                  // NewsDetailScreen으로 이동하며 webOpenMode 설정도 함께 전달
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsDetailScreen(news: news),
                    ),
                  );
                },
                child: Padding(
                  padding: cardStyle.cardPadding,
                  child: settings.viewMode == ViewMode.textOnly
                      ? _buildTextOnlyLayout(news, cardStyle, theme)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 좌측: 텍스트 정보
                            Expanded(
                              flex: 3,
                              child: _buildNewsContent(news, cardStyle, theme),
                            ),

                            // 여백과 이미지 (이미지 모드일 때만)
                            if (showImage) ...[
                              const SizedBox(width: 12),
                              _buildThumbnail(
                                  news.newsImageLink, news.newsLink),
                            ],
                          ],
                        ),
                ),
              );
            },
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.newspaper,
                  size: 48,
                  color: subscribeStyle.emptyIconColor,
                ),
                const SizedBox(height: 12),
                Text(
                  '뉴스가 없습니다',
                  style: TextStyle(
                    color: subscribeStyle.emptyTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // 텍스트 전용 레이아웃
  Widget _buildTextOnlyLayout(
      News news, NewsCardStyleExtension cardStyle, ThemeData theme) {
    return _buildNewsContent(news, cardStyle, theme);
  }

  // 뉴스 내용 위젯 (텍스트만)
  Widget _buildNewsContent(
      News news, NewsCardStyleExtension cardStyle, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 뉴스 제목과 북마크 버튼
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                news.newsTitle,
                style: cardStyle.titleStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 북마크 버튼
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: _loadingStatus[news.newsLink] == true
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    )
                  : Icon(
                      _bookmarkStatus[news.newsLink] == true
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: _bookmarkStatus[news.newsLink] == true
                          ? cardStyle.bookmarkActiveColor
                          : cardStyle.bookmarkInactiveColor,
                      size: 20,
                    ),
              onPressed: () => _toggleBookmark(news),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 뉴스 내용 요약
        Text(
          _truncateDescription(news.newsDescription),
          style: cardStyle.descriptionStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // 출처 및 날짜
        Row(
          children: [
            Text(
              news.newsSource,
              style: cardStyle.sourceStyle,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(news.newsPubDate),
              style: cardStyle.dateStyle,
            ),
          ],
        ),
      ],
    );
  }

  // 북마크 상태 확인
  Future<void> _checkBookmarkStatus(String newsLink) async {
    final isBookmarked = await NewsBookmarkService.isNewsBookmarked(newsLink);
    if (mounted) {
      setState(() {
        _bookmarkStatus[newsLink] = isBookmarked;
      });
    }
  }

  // 북마크 토글
  Future<void> _toggleBookmark(News news) async {
    if (_loadingStatus[news.newsLink] == true) return;

    setState(() {
      _loadingStatus[news.newsLink] = true;
    });

    try {
      bool success;
      if (_bookmarkStatus[news.newsLink] == true) {
        success = await NewsBookmarkService.removeNewsBookmark(news.newsLink);
      } else {
        success = await NewsBookmarkService.addNewsBookmark(news);
      }

      if (success && mounted) {
        setState(() {
          _bookmarkStatus[news.newsLink] =
              !(_bookmarkStatus[news.newsLink] ?? false);
        });

        // 북마크 상태 변경 시 콜백 호출
        if (widget.onBookmarkChanged != null) {
          widget.onBookmarkChanged!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_bookmarkStatus[news.newsLink] == true
                ? '북마크에 추가되었습니다'
                : '북마크에서 제거되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
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
          _loadingStatus[news.newsLink] = false;
        });
      }
    }
  }

  // 썸네일 이미지 위젯
  Widget _buildThumbnail(String imageUrl, String newsLink) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 100,
      height: 75,
      child: imageUrl.isNotEmpty
          ? Hero(
              tag: 'news_image_$newsLink', // Hero 애니메이션 추가
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.image_outlined,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[400],
                size: 30,
              ),
            ),
    );
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

  // 설명 텍스트 자르기
  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }
}
