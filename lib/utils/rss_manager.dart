import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RssManager {
  static const String _subscribedChannelsKey = 'subscribed_channels';

  // Get all subscribed channels
  static Future<List<String>> getSubscribedChannelLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subscribedJson = prefs.getString(_subscribedChannelsKey);

    if (subscribedJson == null || subscribedJson.isEmpty) {
      return [];
    }

    try {
      List<dynamic> subscribedList = json.decode(subscribedJson);
      return subscribedList.map((model) => model.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // Check if channel is subscribed
  static Future<bool> isChannelSubscribed(String channelRssLink) async {
    final channels = await getSubscribedChannelLinks();
    return channels.any((channel) => channel == channelRssLink);
  }

  // Subscribe to a channel
  static Future<bool> subscribeChannel(String channelRssLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current subscriptions
      List<String> channels = await getSubscribedChannelLinks();

      // Check if already subscribed
      if (channels.any((c) => c == channelRssLink)) {
        return false;
      }

      // Add new channel
      channels.add(channelRssLink);

      // Save updated list
      await prefs.setString(_subscribedChannelsKey,
          json.encode(channels.map((c) => c.toString()).toList()));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Unsubscribe from a channel
  static Future<bool> unsubscribeChannel(String channelRssLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current subscriptions
      List<String> channels = await getSubscribedChannelLinks();

      // Remove the channel
      channels.removeWhere((c) => c == channelRssLink);

      // Save updated list
      await prefs.setString(_subscribedChannelsKey,
          json.encode(channels.map((c) => c.toString()).toList()));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear all subscriptions (for testing or reset)
  static Future<void> clearAllSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscribedChannelsKey);
  }
}
