import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/subscribe_service.dart';

class SearchRssChannelCard extends StatefulWidget {
  final RssChannel channel;
  final VoidCallback? onSubscriptionChanged;

  const SearchRssChannelCard({
    super.key,
    required this.channel,
    this.onSubscriptionChanged,
  });

  @override
  State<SearchRssChannelCard> createState() => _SearchRssChannelCardState();
}

class _SearchRssChannelCardState extends State<SearchRssChannelCard> {
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    // null 체크 추가
    final channelUrl = widget.channel.channelRssLink ?? '';
    if (channelUrl.isEmpty) return;

    final isSubscribed = await SubscribeService.isSubscribed(channelUrl);
    if (mounted) {
      setState(() {
        _isSubscribed = isSubscribed;
      });
    }
  }

  Future<void> _toggleSubscription() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      // null 체크 추가
      final channelUrl = widget.channel.channelRssLink ?? '';
      if (channelUrl.isEmpty) throw Exception('구독 URL이 없습니다');

      if (_isSubscribed) {
        success = await SubscribeService.unsubscribe(channelUrl);
      } else {
        success = await SubscribeService.subscribe(widget.channel);
      }

      if (success && mounted) {
        setState(() {
          _isSubscribed = !_isSubscribed;
        });

        if (widget.onSubscriptionChanged != null) {
          widget.onSubscriptionChanged!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSubscribed ? '구독이 추가되었습니다' : '구독이 취소되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 변경 중 오류가 발생했습니다: $e'),
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

  Future<void> _navigateToChannelDetail() async {
    // 채널 상세 화면으로 이동
    // 구현할 경우 여기에 코드 추가
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _navigateToChannelDetail,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 채널 아이콘/이미지
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: (widget.channel.channelImageUrl ?? '').isNotEmpty // null 체크 추가
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.channel.channelImageUrl ?? '', // null 체크 추가
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.rss_feed,
                          color: Colors.orange[300],
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.rss_feed,
                      color: Colors.orange[300],
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            
            // 채널 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 태그 표시 (채널)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200, width: 1),
                    ),
                    child: Text(
                      '채널',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // 채널 제목
                  Text(
                    widget.channel.channelTitle ?? '제목 없음', // null 체크 추가
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 채널 설명
                  Text(
                    widget.channel.channelDescription ?? '설명 없음', // null 체크 추가
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // 구독 버튼
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isSubscribed ? Icons.check_circle : Icons.add_circle_outline,
                      color: _isSubscribed ? Colors.green : Colors.grey[700],
                      size: 24,
                    ),
                    onPressed: _toggleSubscription,
                  ),
          ],
        ),
      ),
    );
  }
}
