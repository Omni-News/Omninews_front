import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';

class RssChannelCard extends StatefulWidget {
  final RssChannel channel;
  final Function() onTap;
  final bool isSubscribed;
  final Function() onSubscriptionChanged;

  const RssChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    required this.isSubscribed,
    required this.onSubscriptionChanged,
  });

  @override
  State<RssChannelCard> createState() => _RssChannelCardState();
}

class _RssChannelCardState extends State<RssChannelCard> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Channel Image - 둥근 모서리로 개선
            _buildChannelImage(),

            const SizedBox(width: 16),

            // Channel Info - 정보 배치 개선
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channel.channelTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.channel.channelDescription,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.language,
                        text: widget.channel.channelLanguage ?? 'Unknown',
                      ),
                      const SizedBox(width: 12),
                      _buildInfoItem(
                        icon: Icons.star,
                        text: widget.channel.channelRank.toString(),
                        iconColor: Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Subscribe/Unsubscribe Button - 개선된 버튼 스타일
            _buildSubscriptionButton(),
          ],
        ),
      ),
    );
  }

  // 채널 이미지 위젯
  Widget _buildChannelImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: widget.channel.channelImageUrl != null &&
              widget.channel.channelImageUrl!.isNotEmpty
          ? Image.network(
              widget.channel.channelImageUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultChannelIcon();
              },
            )
          : _buildDefaultChannelIcon(),
    );
  }

  // 기본 채널 아이콘 위젯
  Widget _buildDefaultChannelIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[400]!, Colors.blue[700]!],
        ),
      ),
      child: const Icon(
        Icons.rss_feed,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  // 정보 아이템 위젯 (아이콘 + 텍스트)
  Widget _buildInfoItem(
      {required IconData icon, required String text, Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // 구독 버튼 위젯
  Widget _buildSubscriptionButton() {
    return _isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[600],
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSubscribed
                  ? Colors.blue.shade50
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isSubscribed ? Icons.check : Icons.add,
                  size: 16,
                  color:
                      widget.isSubscribed ? Colors.blue[700] : Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isSubscribed ? '구독 중' : '구독',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.isSubscribed
                        ? Colors.blue[700]
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
  }
}
