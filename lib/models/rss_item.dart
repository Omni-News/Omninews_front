class RssItem {
  final int rssId;
  final int channelId;
  final String rssTitle;
  final String rssDescription;
  final String rssLink;
  final String? rssAuthor;
  final String rssPubDate;
  final int rssRank;
  final String? rssImageLink;

  RssItem({
    required this.rssId,
    required this.channelId,
    required this.rssTitle,
    required this.rssDescription,
    required this.rssLink,
    this.rssAuthor,
    required this.rssPubDate,
    required this.rssRank,
    this.rssImageLink,
  });

  factory RssItem.fromJson(Map<String, dynamic> json) {
    return RssItem(
      rssId: json['rss_id'],
      channelId: json['channel_id'],
      rssTitle: json['rss_title'],
      rssDescription: json['rss_description'] ?? '',
      rssLink: json['rss_link'],
      rssAuthor: json['rss_author'],
      rssPubDate: json['rss_pub_date'],
      rssRank: json['rss_rank'],
      rssImageLink: json['rss_image_link'],
    );
  }

  // JSON으로 변환하는 메서드 추가
  Map<String, dynamic> toJson() {
    return {
      'rss_id': rssId,
      'channel_id': channelId,
      'rss_title': rssTitle,
      'rss_description': rssDescription,
      'rss_link': rssLink,
      'rss_author': rssAuthor,
      'rss_pub_date': rssPubDate,
      'rss_rank': rssRank,
      'rss_image_link': rssImageLink,
    };
  }
}
