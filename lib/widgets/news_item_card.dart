import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsItemCard extends StatefulWidget {
  final News news;
  final VoidCallback? onBookmarkChanged;

  const NewsItemCard({
    super.key,
    required this.news,
    this.onBookmarkChanged,
  });

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

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked =
        await NewsBookmarkService.isAnyBookmarked(widget.news.newsLink);
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
            await NewsBookmarkService.removeNewsBookmark(widget.news.newsLink);
      } else {
        success = await NewsBookmarkService.addNewsBookmark(widget.news);
      }

      if (success && mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });

        // 북마크 변경 콜백 실행
        if (widget.onBookmarkChanged != null) {
          widget.onBookmarkChanged!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? '북마크에 추가되었습니다' : '북마크에서 제거되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('북마크 변경 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
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

  Future<void> _openNewsLink() async {
    Uri uri = Uri.parse(widget.news.newsLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크를 열 수 없습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidImage = _isValidImageUrl(widget.news.newsImageLink);

    return InkWell(
      onTap: _openNewsLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 텍스트 정보
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 북마크 버튼
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.news.newsTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color:
                                    _isBookmarked ? Colors.blue : Colors.grey,
                                size: 20,
                              ),
                        onPressed: _toggleBookmark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 뉴스 내용 요약
                  Text(
                    _truncateDescription(widget.news.newsDescription),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 출처 및 날짜
                  Row(
                    children: [
                      Text(
                        widget.news.newsSource,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(widget.news.newsPubDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 여백
            if (hasValidImage) const SizedBox(width: 12),

            // 우측: 썸네일 이미지 (있을 경우)
            if (hasValidImage) _buildThumbnail(),
          ],
        ),
      ),
    );
  }

  // 썸네일 이미지 위젯
  Widget _buildThumbnail() {
    return SizedBox(
      width: 100,
      height: 75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          widget.news.newsImageLink,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
                size: 24,
              ),
            );
          },
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
