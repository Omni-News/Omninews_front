class RssChannel {
  final int channelId;
  final String channelTitle;
  final String channelLink;
  final String channelDescription;
  final String? channelImageUrl;
  final String? channelLanguage;
  final String? rssGenerator;
  final int channelRank;
  final String channelRssLink;

  RssChannel({
    required this.channelId,
    required this.channelTitle,
    required this.channelLink,
    required this.channelDescription,
    this.channelImageUrl,
    this.channelLanguage,
    this.rssGenerator,
    required this.channelRank,
    required this.channelRssLink,
  });

  factory RssChannel.fromJson(Map<String, dynamic> json) {
    return RssChannel(
      channelId: json['channel_id'],
      channelTitle: json['channel_title'],
      channelLink: json['channel_link'],
      channelDescription: json['channel_description'],
      channelImageUrl: json['channel_image_url'],
      channelLanguage: json['channel_language'] ?? 'None',
      rssGenerator: json['rss_generator'] ?? 'None',
      channelRank: json['channel_rank'],
      channelRssLink: json['channel_rss_link'],
    );
  }

  // JSON으로 변환하는 메서드 추가
  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'channel_title': channelTitle,
      'channel_link': channelLink,
      'channel_description': channelDescription,
      'channel_image_url': channelImageUrl,
      'channel_language': channelLanguage,
      'rss_generator': rssGenerator,
      'channel_rank': channelRank,
      'channel_rss_link': channelRssLink,
    };
  }
}
