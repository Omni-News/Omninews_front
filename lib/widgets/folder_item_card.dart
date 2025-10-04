import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/screens/rss_detail_screen.dart';
import 'package:omninews_flutter/services/recently_read_service.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';

class FolderItemCard extends StatefulWidget {
  final RssItem item;
  final RssFolder folder;

  const FolderItemCard({super.key, required this.item, required this.folder});

  @override
  State<FolderItemCard> createState() => _FolderItemCardState();
}

class _FolderItemCardState extends State<FolderItemCard> {
  bool _isBookmarked = false;
  bool _isLoading = false;
  RssChannel? _sourceChannel;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _findSourceChannel();
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final isBookmarked = await SubscribeService.isBookmarked(
        widget.item.rssLink,
      );
      if (!mounted) return;
      setState(() {
        _isBookmarked = isBookmarked;
      });
    } catch (_) {
      // 조용히 실패
    }
  }

  void _findSourceChannel() {
    try {
      _sourceChannel = widget.folder.folderChannels.firstWhere(
        (channel) => channel.channelId == widget.item.channelId,
      );
    } catch (_) {
      _sourceChannel = null;
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      bool success;
      if (_isBookmarked) {
        // 폴더/로컬 컨텍스트에 맞춰 Local API 사용
        success = await SubscribeService.removeLocalBookmark(
          widget.item.rssLink,
        );
      } else {
        success = await SubscribeService.addLocalBookmark(widget.item);
      }

      if (!mounted) return;

      if (success) {
        setState(() => _isBookmarked = !_isBookmarked);

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
          content: Text('북마크 처리 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inHours < 24) {
        if (difference.inHours < 1) {
          return '${difference.inMinutes}분 전';
        }
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return DateFormat('yyyy년 MM월 dd일').format(date);
      }
    } catch (_) {
      return '날짜 없음';
    }
  }

  // 채널 이름
  String _getChannelName() {
    if (_sourceChannel != null) {
      return _sourceChannel!.channelTitle;
    }
    return '알 수 없는 채널';
  }

  void _openArticle() {
    // 읽은 기록 및 랭크 업데이트
    RecentlyReadService.addRssItem(widget.item);
    RssService.updateRssRank(widget.item.rssId);

    // 상세 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RssDetailScreen(rssItem: widget.item),
      ),
    );
  }

  // 간단한 HTML 제거 후 축약
  String _cleanAndTruncate(String text, {int max = 160}) {
    final cleaned =
        text
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    if (cleaned.length <= max) return cleaned;
    return '${cleaned.substring(0, max)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);

    return InkWell(
      onTap: _openArticle,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 소스 채널 + 날짜
            Row(
              children: [
                // 채널 이미지 (소형)
                if ((_sourceChannel?.channelImageUrl ?? '').isNotEmpty)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                        _sourceChannel!.channelImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: theme.primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.rss_feed,
                                size: 12,
                                color: theme.primaryColor,
                              ),
                            ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.rss_feed,
                      size: 12,
                      color: theme.primaryColor,
                    ),
                  ),
                const SizedBox(width: 8),

                // 채널 이름
                Expanded(
                  child: Text(
                    _getChannelName(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 날짜
                Text(
                  _formatDate(widget.item.rssPubDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 제목
            Text(
              widget.item.rssTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // 내용 (요약)
            Text(
              _cleanAndTruncate(widget.item.rssDescription, max: 160),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // 하단 액션 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 북마크 버튼
                InkWell(
                  onTap: _toggleBookmark,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.primaryColor,
                                ),
                              ),
                            )
                            : Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color:
                                  _isBookmarked
                                      ? theme.primaryColor
                                      : theme.iconTheme.color,
                            ),
                  ),
                ),

                const SizedBox(width: 16),

                // 공유 버튼 (향후 구현)
                InkWell(
                  onTap: () {
                    // TODO: 공유 기능 구현 (Share.share 등)
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: theme.iconTheme.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
