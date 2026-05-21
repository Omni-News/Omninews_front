import 'package:flutter_test/flutter_test.dart';
import 'package:omninews_flutter/services/notification_navigation.dart';

void main() {
  test('parses rss_item notification data into an RssItem', () {
    final payload = NotificationRssPayload.fromData({
      'type': 'rss_item',
      'rss_id': '42',
      'channel_id': '7',
      'rss_title': '새 글',
      'rss_description': '본문 요약',
      'rss_link': 'https://example.com/post',
      'rss_author': '작성자',
      'rss_pub_date': '2026-05-21T12:34:56',
      'rss_rank': '0',
      'rss_image_link': 'https://example.com/image.png',
    });

    expect(payload, isNotNull);
    expect(payload!.item.rssId, 42);
    expect(payload.item.channelId, 7);
    expect(payload.item.rssTitle, '새 글');
    expect(payload.item.rssLink, 'https://example.com/post');
    expect(payload.item.rssPubDate, '2026-05-21T12:34:56');
  });

  test('rejects notification data that is not an rss item route', () {
    final payload = NotificationRssPayload.fromData({
      'type': 'news_item',
      'rss_id': '42',
      'channel_id': '7',
      'rss_title': '새 글',
      'rss_link': 'https://example.com/post',
      'rss_pub_date': '2026-05-21T12:34:56',
    });

    expect(payload, isNull);
  });
}
