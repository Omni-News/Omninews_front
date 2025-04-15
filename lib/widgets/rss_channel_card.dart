import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/models/rss_channel.dart';
import 'package:omninews_test_flutter/theme/app_theme.dart';
import 'package:omninews_test_flutter/models/app_setting.dart'; // 추가

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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // 이미지 표시 여부 결정 (뷰 모드 설정에 따름)
    final showImage = true;

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Channel Image - 뷰 모드에 따라 표시/숨김
            if (showImage) ...[
              Hero(
                tag: 'channel_${widget.channel.channelRssLink}',
                child: _buildChannelImage(),
              ),
              const SizedBox(width: 16),
            ],

            // Channel Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channel.channelTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.channel.channelDescription,
                    style: textTheme.bodyMedium?.copyWith(
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

            // Subscribe/Unsubscribe Button
            _buildSubscriptionButton(),
          ],
        ),
      ),
    );
  }

  // 채널 이미지 위젯
  Widget _buildChannelImage() {
    final rssTheme = AppTheme.rssThemeOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
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
    final rssTheme = AppTheme.rssThemeOf(context);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rssTheme.channelImageGradientColors,
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? theme.iconTheme.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  // 구독 버튼 위젯
  Widget _buildSubscriptionButton() {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);

    return _isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.secondary,
            ),
          )
        : InkWell(
            onTap: widget.onSubscriptionChanged,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isSubscribed
                    ? rssTheme.subscribeButtonActiveBackground
                    : rssTheme.subscribeButtonInactiveBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isSubscribed ? Icons.check : Icons.add,
                    size: 16,
                    color: widget.isSubscribed
                        ? rssTheme.subscribeButtonActiveText
                        : rssTheme.subscribeButtonInactiveText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.isSubscribed ? '구독 중' : '구독',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.isSubscribed
                          ? rssTheme.subscribeButtonActiveText
                          : rssTheme.subscribeButtonInactiveText,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
