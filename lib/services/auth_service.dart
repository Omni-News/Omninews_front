import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    clientId:
        '1008455298981-96a4gkqhnmr1hhbqab80df7rljbhocai.apps.googleusercontent.com',
  );

  // API 기본 URL - 실제 서버 URL로 변경 필요
  static const String apiBaseUrl = 'http://61.253.113.42:1027';

  // 사용자 인증 정보
  String? _authToken;
  Map<String, dynamic>? _user;

  // 현재 사용자 정보
  Map<String, dynamic>? get user => _user;

  // 로그인 상태 확인
  bool get isLoggedIn => _authToken != null;

  // 초기화 - 저장된 토큰과 사용자 정보 불러오기
  Future<void> initialize() async {
    await _loadAuthData();
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      // 소셜 로그인 SDK 로그아웃
      await _googleSignIn.signOut();
      try {
        await kakao.UserApi.instance.logout();
      } catch (e) {
        debugPrint('카카오 로그아웃 실패: $e');
      }

      // 서버에 로그아웃 요청
      await _sendLogoutRequest();

      // 로컬 데이터 삭제
      await _clearAuthData();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
    }
  }

  // Google 로그인
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('Google 로그인 시작');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google 로그인 취소됨');
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 서버에 인증 정보 전송
      Map<String, dynamic> authData = {
        'provider': 'google',
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
      };

      return await _authenticateWithServer(authData);
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      return false;
    }
  }

  // 카카오 로그인
  Future<bool> signInWithKakao() async {
    try {
      debugPrint('카카오 로그인 시작');

      // 카카오톡 설치 여부 확인
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          debugPrint('카카오톡 로그인 실패: $error');

          // 사용자가 취소한 경우 처리
          if (error.toString().contains('CANCELED')) {
            return false;
          }

          // 카카오 계정으로 로그인 시도
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // 카카오톡이 설치되어 있지 않으면 카카오 계정으로 로그인
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 카카오 사용자 정보 가져오기
      kakao.User kakaoUser = await kakao.UserApi.instance.me();

      // 액세스 토큰 가져오기
      final token =
          await kakao.TokenManagerProvider.instance.manager.getToken();
      String? accessToken = token?.accessToken;

      // 서버에 인증 정보 전송
      Map<String, dynamic> authData = {
        'provider': 'kakao',
        'id': kakaoUser.id.toString(),
        'email': kakaoUser.kakaoAccount?.email,
        'displayName': kakaoUser.kakaoAccount?.profile?.nickname,
        'photoUrl': kakaoUser.kakaoAccount?.profile?.profileImageUrl,
        'accessToken': accessToken,
      };

      return await _authenticateWithServer(authData);
    } catch (e) {
      debugPrint('카카오 로그인 오류: $e');
      return false;
    }
  }

  // 애플 로그인 (틀만 구현)
  Future<bool> signInWithApple() async {
    try {
      debugPrint('애플 로그인 시작');

      // TODO: 애플 로그인 구현

      // 서버에 인증 정보 전송 (예시)
      // Map<String, dynamic> authData = {
      //   'provider': 'apple',
      //   'id': appleUser.id,
      //   'email': appleUser.email,
      //   'displayName': appleUser.displayName,
      //   'identityToken': identityToken,
      // };
      //
      // return await _authenticateWithServer(authData);

      // 임시 반환
      throw UnimplementedError('애플 로그인이 아직 구현되지 않았습니다.');
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
      return false;
    }
  }

  // 서버로 인증 정보 전송
  Future<bool> _authenticateWithServer(Map<String, dynamic> authData) async {
    try {
      debugPrint('서버 인증 요청: $authData');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(authData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // 토큰과 사용자 정보 저장
        _authToken = data['token'];
        _user = data['user'];

        // 로컬 저장소에 저장
        await _saveAuthData();

        debugPrint('서버 인증 성공: ${_user?['displayName']}');
        return true;
      } else {
        debugPrint('서버 인증 실패: ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('서버 통신 오류: $e');
      return false;
    }
  }

  // 서버에 로그아웃 요청
  Future<void> _sendLogoutRequest() async {
    if (_authToken == null) return;

    try {
      await http.post(
        Uri.parse('$apiBaseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      debugPrint('서버 로그아웃 요청 완료');
    } catch (e) {
      debugPrint('서버 로그아웃 요청 실패: $e');
    }
  }

  // 인증 데이터 로컬 저장
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_authToken != null) {
        await prefs.setString('auth_token', _authToken!);
      }
      if (_user != null) {
        await prefs.setString('user_data', json.encode(_user));
      }

      // 로그인 제공자 저장
      if (_user != null && _user!.containsKey('provider')) {
        await prefs.setString('auth_provider', _user!['provider']);
      }
    } catch (e) {
      debugPrint('인증 데이터 저장 오류: $e');
    }
  }

  // 저장된 인증 데이터 로드
  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');

      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = json.decode(userData);
      }

      debugPrint('저장된 인증 데이터 로드: ${_user != null ? "성공" : "데이터 없음"}');
    } catch (e) {
      debugPrint('인증 데이터 로드 오류: $e');
    }
  }

  // 인증 데이터 삭제
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      await prefs.remove('auth_provider');

      _authToken = null;
      _user = null;

      debugPrint('인증 데이터 삭제 완료');
    } catch (e) {
      debugPrint('인증 데이터 삭제 오류: $e');
    }
  }

  // HTTP 요청 헤더 준비 (인증 필요한 API 요청용)
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  // 인증 제공자 정보 가져오기
  Future<String?> getAuthProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_provider');
  }
}
