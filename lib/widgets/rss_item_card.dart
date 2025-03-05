import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 추가된 import

class RssItemCard extends StatelessWidget {
  final RssItem item;

  const RssItemCard({super.key, required this.item});

  Future<void> _openArticle(BuildContext context) async {
    if (!await launchUrl(Uri.parse(item.rssLink))) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크를 열 수 없습니다'),
            duration: Duration(seconds: 2),
          ),
        );
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
        return DateFormat('yyyy.MM.dd').format(date);
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

  @override
  Widget build(BuildContext context) {
    // 이미지 URL이 유효한지 확인
    final bool hasValidImage = _isValidImageUrl(item.rssImageLink);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _openArticle(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: hasValidImage 
            // 유효한 이미지가 있는 경우: Row 레이아웃 사용
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text content with image
                  Expanded(
                    flex: 3,
                    child: _buildTextContent(),
                  ),

                  // Spacer
                  const SizedBox(width: 12),

                  // Thumbnail with CachedNetworkImage
                  SizedBox(
                    width: 100,
                    height: 75,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: item.rssImageLink!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const SizedBox.shrink(),
                        // 로그 출력 억제
                        errorListener: (error) => {},
                      ),
                    ),
                  ),
                ],
              )
            // 유효한 이미지가 없는 경우: 텍스트만 표시
            : _buildTextContent(),
        ),
      ),
    );
  }
  
  // 텍스트 내용을 구성하는 위젯
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.rssTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        if (item.rssDescription.isNotEmpty) ...[
          Text(
            item.rssDescription,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(
              Icons.public,
              size: 14,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                Uri.parse(item.rssLink).host,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(item.rssPubDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
