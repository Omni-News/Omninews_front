import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_folder.dart';
// import 'package:omninews_flutter/screens/webview_screen.dart'; // 1. 이 파일이 없으므로 주석 처리 또는 대체
import 'package:omninews_flutter/services/subscribe_service.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:intl/intl.dart';

class FolderItemCard extends StatefulWidget {
  final RssItem item;
  final RssFolder folder;

  const FolderItemCard({super.key, required this.item, required this.folder});

  @override
  State<FolderItemCard> createState() => _FolderItemCardState();
}

class _FolderItemCardState extends State<FolderItemCard> {
  bool _isBookmarked = false; // 초기값 설정
  bool _isLoading = false;
  RssChannel? _sourceChannel;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _findSourceChannel();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await SubscribeService.isBookmarked(
      widget.item.rssLink,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
      });
    }
  }

  void _findSourceChannel() {
    // 2. orElse에서 null 대신 RssChannel의 기본값 반환하도록 수정
    try {
      _sourceChannel = widget.folder.folderChannels.firstWhere(
        (channel) => channel.channelId == widget.item.channelId,
      );
    } catch (e) {
      _sourceChannel = null; // 명시적으로 null 할당
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
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    } catch (e) {
      return '날짜 없음';
    }
  }

  // 채널 이름을 가져오는 함수
  String _getChannelName() {
    if (_sourceChannel != null) {
      return _sourceChannel!.channelTitle;
    }
    return '알 수 없는 채널';
  }

  void _openArticle() {
    // 3. WebViewScreen으로 이동 부분 수정
    // WebViewScreen이 없다면 URL을 열 수 있는 다른 방법을 사용해야 함
    // 임시 해결책: 스낵바로 대체
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('링크 열기: ${widget.item.rssLink}'),
        action: SnackBarAction(label: '확인', onPressed: () {}),
      ),
    );

    // 실제 WebViewScreen이 있다면 아래 코드를 사용
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: widget.item.rssLink,
          title: widget.item.rssTitle,
        ),
      ),
    );
    */
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
            // 소스 채널 표시 (새로 추가)
            Row(
              children: [
                // 채널 이미지 (소형)
                if (_sourceChannel?.channelImageUrl != null &&
                    _sourceChannel!.channelImageUrl!.isNotEmpty)
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
                Text(
                  _getChannelName(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),

                const Spacer(),

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
              widget.item.rssDescription,
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
                                      ? theme
                                          .primaryColor // 4. bookmarkActiveColor 대신 primaryColor 사용
                                      : theme.iconTheme.color,
                            ),
                  ),
                ),

                const SizedBox(width: 16),

                // 공유 버튼
                InkWell(
                  onTap: () {
                    // 공유 기능 구현
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
