import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:omninews_flutter/services/auth_service.dart';

class FeedbackService {
  // 서버 엔드포인트 URL
  static const String _apiUrl = 'http://61.253.113.42:1027/feedback';
  static final AuthService _authService = AuthService();

  /// 피드백을 서버로 전송하는 함수
  ///
  /// [email] 사용자 이메일 (선택사항)
  /// [content] 피드백 내용
  ///
  /// 성공 시 true, 실패 시 false 반환
  static Future<bool> submitFeedback({
    required String content,
    String? email,
  }) async {
    try {
      // 요청 바디 구성
      final Map<String, String> body = {'feedback_content': content};

      // 이메일이 있으면 추가
      if (email != null && email.isNotEmpty) {
        body['feedback_email'] = email;
      }

      final headers = _authService.getAuthHeaders();
      // HTTP POST 요청 보내기
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      // 응답 상태 코드 확인
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('피드백 제출 오류: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('피드백 제출 중 예외 발생: $e');
      return false;
    }
  }
}
