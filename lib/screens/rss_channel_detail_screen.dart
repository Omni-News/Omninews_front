import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/rss_channel.dart';
import 'package:omninews_flutter/models/rss_item.dart';
import 'package:omninews_flutter/services/rss_service.dart';
import 'package:omninews_flutter/widgets/rss_item_card.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RssChannelDetailScreen extends StatefulWidget {
  final RssChannel channel;
  final bool isSubscribed;
  final Function() onSubscriptionChanged;

  const RssChannelDetailScreen({
    super.key,
    required this.channel,
    required this.isSubscribed,
    required this.onSubscriptionChanged,
  });

  @override
  State<RssChannelDetailScreen> createState() => _RssChannelDetailScreenState();
}

class _RssChannelDetailScreenState extends State<RssChannelDetailScreen> {
  late Future<List<RssItem>> _rssItems;
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _loadRssItems();
  }

  void _loadRssItems() {
    _rssItems = RssService.fetchChannelItems(widget.channel.channelTitle);
  }

  Future<void> _toggleSubscription() async {
    setState(() {
      _isSubscribing = true;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSubscribed ? '구독이 취소되었습니다' : '구독되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
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
          _isSubscribing = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RSS 채널',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadRssItems();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Channel Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.channel.channelImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.channel.channelImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.rss_feed,
                                color: Colors.white,
                                size: 36,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.rss_feed,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.channel.channelTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () => _launchUrl(widget.channel.channelLink),
                            child: Text(
                              widget.channel.channelLink,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.channel.channelDescription,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        '언어: ${widget.channel.channelLanguage}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey[100],
                    ),
                    const SizedBox(width: 8),
                    if (widget.channel.rssGenerator != null &&
                        widget.channel.rssGenerator != 'None')
                      Chip(
                        label: Text(
                          widget.channel.rssGenerator!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey[100],
                      ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${widget.channel.channelRank}')
                        ],
                      ),
                      backgroundColor: Colors.grey[100],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubscribing ? null : _toggleSubscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.isSubscribed ? Colors.red : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isSubscribing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            widget.isSubscribed
                                ? Icons.remove_circle_outline
                                : Icons.add_circle_outline,
                            size: 20,
                          ),
                    label: Text(
                      widget.isSubscribed ? '구독 취소' : '구독하기',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 8,
            color: Colors.grey[200],
          ),

          // Channel Items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  '최신 피드',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<RssItem>>(
              future: _rssItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load feed',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return RssItemCard(item: snapshot.data![index]);
                    },
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          '피드 항목이 없습니다',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
