import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/app_setting.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/provider/settings_provider.dart';
import 'package:omninews_flutter/theme/app_theme.dart';
import 'package:provider/provider.dart';

class RssChannelCard extends StatefulWidget {
  final RssChannel channel;
  final VoidCallback onTap;
  final bool isSubscribed;
  final VoidCallback onSubscriptionChanged;

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
  bool _isLoading = false; // 향후 네트워크 연동 시 사용

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = context.watch<SettingsProvider>().settings;

    // 뷰 모드에 따라 채널 이미지 표시
    final bool showImage = settings.viewMode == ViewMode.textAndImage;

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
            if (showImage) ...[
              Hero(
                tag: 'channel_${widget.channel.channelRssLink}',
                child: _buildChannelImage(),
              ),
              const SizedBox(width: 16),
            ],

            // 채널 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
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

                  // 설명
                  Text(
                    widget.channel.channelDescription,
                    style: textTheme.bodyMedium?.copyWith(height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // 언어 · 랭크
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

            // 구독 버튼
            const SizedBox(width: 12),
            _buildSubscriptionButton(),
          ],
        ),
      ),
    );
  }

  // 채널 이미지 위젯
  Widget _buildChannelImage() {
    final rssTheme = AppTheme.rssThemeOf(context);
    final imageUrl = widget.channel.channelImageUrl ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(rssTheme.channelImageBorderRadius),
      child:
          imageUrl.isNotEmpty
              ? Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, _) {
                  if (frame != null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    color: Theme.of(context).cardColor.withOpacity(0.6),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
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
      child: const Icon(Icons.rss_feed, color: Colors.white, size: 26),
    );
  }

  // 정보 아이템 (아이콘 + 텍스트)
  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? theme.iconTheme.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }

  // 구독 버튼
  Widget _buildSubscriptionButton() {
    final theme = Theme.of(context);
    final rssTheme = AppTheme.rssThemeOf(context);

    if (_isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.secondary,
        ),
      );
    }

    final bool isOn = widget.isSubscribed;

    return Semantics(
      button: true,
      label: isOn ? '구독 중' : '구독하기',
      child: InkWell(
        onTap: widget.onSubscriptionChanged,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:
                isOn
                    ? rssTheme.subscribeButtonActiveBackground
                    : rssTheme.subscribeButtonInactiveBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOn ? Icons.check : Icons.add,
                size: 16,
                color:
                    isOn
                        ? rssTheme.subscribeButtonActiveText
                        : rssTheme.subscribeButtonInactiveText,
              ),
              const SizedBox(width: 4),
              Text(
                isOn ? '구독 중' : '구독하기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      isOn
                          ? rssTheme.subscribeButtonActiveText
                          : rssTheme.subscribeButtonInactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
