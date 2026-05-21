import 'package:omninews_flutter/models/rss_item.dart';

class NotificationRssPayload {
  final RssItem item;

  const NotificationRssPayload({required this.item});

  static NotificationRssPayload? fromData(Map<dynamic, dynamic> data) {
    if (_stringValue(data['type']) != 'rss_item') {
      return null;
    }

    final rssId = _intValue(data['rss_id']);
    final channelId = _intValue(data['channel_id']);
    final title = _requiredString(data['rss_title']);
    final link = _requiredString(data['rss_link']);
    final pubDate = _requiredString(data['rss_pub_date']);

    if (rssId == null ||
        channelId == null ||
        title == null ||
        link == null ||
        pubDate == null) {
      return null;
    }

    return NotificationRssPayload(
      item: RssItem(
        rssId: rssId,
        channelId: channelId,
        rssTitle: title,
        rssDescription: _stringValue(data['rss_description']) ?? '',
        rssLink: link,
        rssAuthor: _nullableString(data['rss_author']),
        rssPubDate: pubDate,
        rssRank: _intValue(data['rss_rank']) ?? 0,
        rssImageLink: _nullableString(data['rss_image_link']),
      ),
    );
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _requiredString(dynamic value) {
    final text = _stringValue(value);
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String? _nullableString(dynamic value) {
    final text = _stringValue(value);
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}
