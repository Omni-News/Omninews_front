import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/custom_news.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:omninews_flutter/utils/url_launcher_helper.dart';
import 'package:provider/provider.dart';

class CustomNewsListView extends StatefulWidget {
  final Future<List<CustomNews>> newsList;
  final String categoryName;
  final String currentSortOption; // "sim" | "date"
  final Function(String) onSortChanged;
  final VoidCallback? onBookmarkChanged;

  const CustomNewsListView({
    super.key,
    required this.newsList,
    required this.categoryName,
    required this.currentSortOption,
    required this.onSortChanged,
    this.onBookmarkChanged,
  });

  @override
  State<CustomNewsListView> createState() => _CustomNewsListViewState();
}

class _CustomNewsListViewState extends State<CustomNewsListView> {
  // 북마크 상태
  final Map<String, bool> _bookmarkStatus = {};
  final Map<String, bool> _loadingStatus = {};

  // HTML 엔티티 처리
  final HtmlUnescape _htmlUnescape = HtmlUnescape();

  // HTML 엔티티를 일반 텍스트로 변환
  String _decodeHtmlEntities(String text) {
    if (text.isEmpty) return '';
    try {
      return _htmlUnescape.convert(text);
    } catch (e) {
      debugPrint('Error decoding HTML entities: $e');
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardStyle = AppTheme.newsCardStyleOf(context);
    final subscribeStyle = AppTheme.subscribeViewStyleOf(context);
    final settings = context.watch<SettingsProvider>().settings;

    return Column(
      children: [
        // 정렬 옵션
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption(
                context: context,
                label: "정확순",
                isSelected: widget.currentSortOption == "sim",
                onTap: () => widget.onSortChanged("sim"),
              ),
              const SizedBox(width: 16),
              _buildSortOption(
                context: context,
                label: "최신순",
                isSelected: widget.currentSortOption == "date",
                onTap: () => widget.onSortChanged("date"),
              ),
            ],
          ),
        ),

        // 뉴스 목록
        Expanded(
          child: FutureBuilder<List<CustomNews>>(
            future: widget.newsList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: theme.primaryColor),
                );
              }

              if (snapshot.hasError) {
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
                            color: subscribeStyle.emptyTextColor.withOpacity(
                              0.8,
                            ),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snapshot.data ?? [];
              if (data.isEmpty) {
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

              // 각 뉴스 북마크 상태 프리페치
              for (final item in data) {
                if (!_bookmarkStatus.containsKey(item.originalLink)) {
                  _checkBookmarkStatus(item.originalLink);
                }
              }

              return ListView.separated(
                padding: const EdgeInsets.only(top: 4),
                itemCount: data.length,
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerTheme.color,
                    ),
                itemBuilder: (context, index) {
                  final item = data[index];

                  return InkWell(
                    onTap: () {
                      RecentlyReadService.addCustomNews(item);
                      UrlLauncherHelper.openUrl(
                        context,
                        item.originalLink,
                        settings.webOpenMode,
                      );
                    },
                    child: Padding(
                      padding: cardStyle.cardPadding,
                      child: _buildNewsContent(item, cardStyle, theme),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 뉴스 내용 부분
  Widget _buildNewsContent(
    CustomNews item,
    NewsCardStyleExtension cardStyle,
    ThemeData theme,
  ) {
    // HTML 엔티티 디코딩
    final decodedTitle = _decodeHtmlEntities(item.plainTitle);
    final decodedDescription = _decodeHtmlEntities(item.plainDescription);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 + 북마크
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                decodedTitle,
                style: cardStyle.titleStyle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon:
                  _loadingStatus[item.originalLink] == true
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primaryColor,
                        ),
                      )
                      : Icon(
                        _bookmarkStatus[item.originalLink] == true
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color:
                            _bookmarkStatus[item.originalLink] == true
                                ? cardStyle.bookmarkActiveColor
                                : cardStyle.bookmarkInactiveColor,
                        size: 20,
                      ),
              tooltip:
                  _bookmarkStatus[item.originalLink] == true ? '북마크 해제' : '북마크',
              onPressed: () => _toggleBookmark(item),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 요약
        Text(
          _truncateDescription(decodedDescription),
          style: cardStyle.descriptionStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // 출처 · 날짜
        Row(
          children: [
            Flexible(
              child: Text(
                _extractDomain(item.originalLink),
                style: cardStyle.sourceStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(_formatDate(item.pubDate), style: cardStyle.dateStyle),
          ],
        ),
      ],
    );
  }

  // 북마크 상태 확인
  Future<void> _checkBookmarkStatus(String newsLink) async {
    try {
      final isBookmarked = await NewsBookmarkService.isNewsBookmarked(newsLink);
      if (!mounted) return;
      setState(() {
        _bookmarkStatus[newsLink] = isBookmarked;
      });
    } catch (_) {
      // 조용히 실패
    }
  }

  // 북마크 토글
  Future<void> _toggleBookmark(CustomNews customNews) async {
    final newsLink = customNews.originalLink;
    if (_loadingStatus[newsLink] == true) return;

    setState(() {
      _loadingStatus[newsLink] = true;
    });

    try {
      bool success;
      if (_bookmarkStatus[newsLink] == true) {
        success = await NewsBookmarkService.removeNewsBookmark(newsLink);
      } else {
        final news = _convertCustomNewsToNews(customNews);
        success = await NewsBookmarkService.addNewsBookmark(news);
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _bookmarkStatus[newsLink] = !(_bookmarkStatus[newsLink] ?? false);
        });

        // 콜백
        widget.onBookmarkChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _bookmarkStatus[newsLink] == true
                  ? '북마크에 추가되었습니다'
                  : '북마크에서 제거되었습니다',
            ),
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
          _loadingStatus[newsLink] = false;
        });
      }
    }
  }

  // CustomNews → News 변환
  News _convertCustomNewsToNews(CustomNews customNews) {
    final decodedTitle = _decodeHtmlEntities(customNews.plainTitle);
    final decodedDescription = _decodeHtmlEntities(customNews.plainDescription);

    return News(
      newsId: 0,
      newsTitle: decodedTitle,
      newsDescription: decodedDescription,
      newsSummary: customNews.plainDescription,
      newsLink: customNews.originalLink,
      newsSource: _extractDomain(customNews.originalLink),
      newsPubDate: customNews.pubDate,
      newsImageLink: "",
    );
  }

  // 정렬 버튼
  Widget _buildSortOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected
                        ? theme.primaryColor
                        : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: theme.primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  // 도메인 추출
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      var domain = uri.host;
      if (domain.startsWith('www.')) domain = domain.substring(4);
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

  // 설명 트렁케이트
  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }
}
