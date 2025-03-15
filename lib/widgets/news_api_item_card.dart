import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omninews_flutter/models/news.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:omninews_flutter/services/news_bookmark_service.dart';

class NewsApiItemCard extends StatefulWidget {
  final NewsApi news;
  final VoidCallback? onBookmarkChanged;
  final bool isAlreadyBookmarked; // 추가된 속성

  const NewsApiItemCard({
    super.key,
    required this.news,
    this.onBookmarkChanged,
    this.isAlreadyBookmarked = false, // 기본값은 false
  });

  @override
  State<NewsApiItemCard> createState() => _NewsApiItemCardState();
}

class _NewsApiItemCardState extends State<NewsApiItemCard> {
  bool _isBookmarked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 이미 북마크된 상태라면 상태 변수를 true로 설정
    if (widget.isAlreadyBookmarked) {
      _isBookmarked = true;
    } else {
      _checkBookmarkStatus();
    }
  }

  Future<void> _checkBookmarkStatus() async {
    // 기존 확인 방식 대신 통합 확인 메서드 사용
    final isBookmarked =
        await NewsBookmarkService.isAnyBookmarked(widget.news.newsOriginalLink);
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
        success = await NewsBookmarkService.removeNewsApiBookmark(
            widget.news.newsOriginalLink);
      } else {
        success = await NewsBookmarkService.addNewsApiBookmark(widget.news);
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

  Future<void> _launchURL() async {
    final Uri uri = Uri.parse(widget.news.newsOriginalLink);
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
    return InkWell(
      onTap: _launchURL,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 뉴스 제목과 북마크 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _removeHtmlTags(widget.news.newsTitle),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 3,
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
                          color: _isBookmarked ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                  onPressed: _toggleBookmark,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 뉴스 내용 요약
            Text(
              _truncateDescription(
                  _removeHtmlTags(widget.news.newsDescription)),
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
                  _extractDomain(widget.news.newsOriginalLink),
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
    );
  }

  // HTML 태그 제거 유틸리티 함수
  String _removeHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  // 설명 텍스트 자르기
  String _truncateDescription(String description) {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }

  // 도메인 추출
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain;
    } catch (e) {
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
    } catch (e) {
      return dateStr;
    }
  }
}
