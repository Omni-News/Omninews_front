import 'package:omninews_flutter/models/rss_channel.dart';

class RssFolder {
  final int folderId;
  final String folderName;
  final List<RssChannel> folderChannels;

  RssFolder({
    required this.folderId,
    required this.folderName,
    required this.folderChannels,
  });

  factory RssFolder.fromJson(Map<String, dynamic> json) {
    return RssFolder(
      folderId: json['folder_id'],
      folderName: json['folder_name'],
      folderChannels:
          (json['folder_channels'] as List)
              .map((channel) => RssChannel.fromJson(channel))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folder_id': folderId,
      'folder_name': folderName,
      'folder_channels':
          folderChannels.map((channel) => channel.toJson()).toList(),
    };
  }
}
