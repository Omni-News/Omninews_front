import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/services/rss_service.dart';

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
  bool _isLoading = false;

  Future<void> _toggleSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (widget.isSubscribed) {
        success =
            await RssService.unsubscribeChannel(widget.channel.channelRssLink);
      } else {
        success = await RssService.subscribeChannel(widget.channel);
      }

      if (success && mounted) {
        widget.onSubscriptionChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Channel Image
              if (widget.channel.channelImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.channel.channelImageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.rss_feed,
                          color: Colors.white,
                          size: 30,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.rss_feed,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

              // Channel Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.channel.channelTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.channel.channelDescription,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.language,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            widget.channel.channelLanguage ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.channel.channelRank}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Subscribe/Unsubscribe Button
              IconButton(
                onPressed: _isLoading ? null : _toggleSubscription,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        widget.isSubscribed
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: widget.isSubscribed ? Colors.green : Colors.blue,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
