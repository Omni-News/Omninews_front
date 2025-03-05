import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omninews_flutter/models/rss_channel.dart';

class RssManager {
  static const String _subscribedChannelsKey = 'subscribed_channels';

  // Get all subscribed channels
  static Future<List<RssChannel>> getSubscribedChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subscribedJson = prefs.getString(_subscribedChannelsKey);

    if (subscribedJson == null || subscribedJson.isEmpty) {
      return [];
    }

    try {
      List<dynamic> subscribedList = json.decode(subscribedJson);
      return subscribedList.map((model) => RssChannel.fromJson(model)).toList();
    } catch (e) {
      return [];
    }
  }

  // Check if channel is subscribed
  static Future<bool> isChannelSubscribed(int channelId) async {
    final channels = await getSubscribedChannels();
    return channels.any((channel) => channel.channelId == channelId);
  }

  // Subscribe to a channel
  static Future<bool> subscribeChannel(RssChannel channel) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current subscriptions
      List<RssChannel> channels = await getSubscribedChannels();

      // Check if already subscribed
      if (channels.any((c) => c.channelId == channel.channelId)) {
        return false;
      }

      // Add new channel
      channels.add(channel);

      // Save updated list
      await prefs.setString(_subscribedChannelsKey,
          json.encode(channels.map((c) => c.toJson()).toList()));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Unsubscribe from a channel
  static Future<bool> unsubscribeChannel(int channelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current subscriptions
      List<RssChannel> channels = await getSubscribedChannels();

      // Remove the channel
      channels.removeWhere((c) => c.channelId == channelId);

      // Save updated list
      await prefs.setString(_subscribedChannelsKey,
          json.encode(channels.map((c) => c.toJson()).toList()));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get recent RSS channels from all subscriptions
  static Future<List<RssChannel>> getRecentChannels({int limit = 5}) async {
    final channels = await getSubscribedChannels();

    // Sort by rank (higher rank first)
    channels.sort((a, b) => b.channelRank.compareTo(a.channelRank));

    // Return limited number
    if (channels.length > limit) {
      return channels.sublist(0, limit);
    }
    return channels;
  }

  // Clear all subscriptions (for testing or reset)
  static Future<void> clearAllSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscribedChannelsKey);
  }
}
