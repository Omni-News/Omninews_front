import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:omninews_flutter/models/rss_folder.dart';
import 'package:omninews_flutter/services/auth_service.dart';

class RssFolderService {
  static String baseUrl = AuthService.apiBaseUrl;
  // 인증 서비스 인스턴스
  static final AuthService _authService = AuthService();

  // 폴더 목록 조회
  static Future<List<RssFolder>> fetchFolders() async {
    try {
      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest('GET', '/folder');

      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List jsonResponse = json.decode(decodedResponse);
        return jsonResponse
            .map((folder) => RssFolder.fromJson(folder))
            .toList();
      } else {
        debugPrint(
          'Failed to fetch folders: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to load folders');
      }
    } catch (e) {
      debugPrint('Error fetching folders: $e');
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  // 새 폴더 생성
  static Future<bool> createFolder(String name) async {
    try {
      final body = {"folder_name": name};

      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest(
        'POST',
        '/folder',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          'Failed to create folder: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error creating folder: $e');
      throw Exception('Error creating folder: $e');
    }
  }

  // 폴더 삭제
  static Future<bool> deleteFolder(int folderId) async {
    try {
      final body = {"folder_id": folderId};

      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest(
        'DELETE',
        '/folder',
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Failed to delete folder: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting folder: $e');
      return false;
    }
  }

  // 채널을 폴더에 추가
  static Future<bool> addChannelToFolder(int channelId, int folderId) async {
    try {
      final body = {"folder_id": folderId, "channel_id": channelId};

      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest(
        'POST',
        '/folder/channel',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
          'Failed to add channel to folder: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error adding channel to folder: $e');
      return false;
    }
  }

  // 채널을 폴더에서 제거
  static Future<bool> removeChannelFromFolder(
    int channelId,
    int folderId,
  ) async {
    try {
      final body = {"channel_id": channelId, "folder_id": folderId};

      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest(
        'DELETE',
        '/folder/channel',
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Failed to remove channel from folder: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error removing channel from folder: $e');
      return false;
    }
  }

  // 폴더 수정 (이름/설명 변경)
  static Future<bool> updateFolder(String folderId, String? name) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['folder_name'] = name;

      // 업데이트할 내용이 없으면 바로 성공 반환
      if (updateData.isEmpty) return true;

      updateData['folder_id'] = folderId;

      // AuthService.apiRequest 사용으로 수정
      final response = await _authService.apiRequest(
        'PUT',
        '/folder',
        body: updateData,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Failed to update folder: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating folder: $e');
      return false;
    }
  }
}
