import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 싱글톤 패턴 구현
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // 초기화 완료 여부 추적
  bool _isInitialized = false;

  // 초기화 대기를 위한 Future
  Future<void>? _initializeFuture;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    clientId:
        '1008455298981-96a4gkqhnmr1hhbqab80df7rljbhocai.apps.googleusercontent.com',
  );

  static String apiBaseUrl = 'http://61.253.113.42:1027/v1/api';

  // 토큰 정보
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiresAt;
  DateTime? _refreshTokenExpiresAt;

  // 사용자 정보
  Map<String, dynamic>? _user;

  // 현재 사용자 정보
  Map<String, dynamic>? get user => _user;

  // 로그인 상태 확인
  bool get isLoggedIn => _accessToken != null;

  // 액세스 토큰 getter 추가
  String? get accessToken => _accessToken;

  // 초기화 - 저장된 토큰과 사용자 정보 불러오기
  Future<void> initialize() async {
    // 중복 초기화 방지 및 대기 가능하게 처리
    if (_initializeFuture != null) {
      return _initializeFuture;
    }

    _initializeFuture = _initializeInternal();
    return _initializeFuture;
  }

  Future<void> _initializeInternal() async {
    if (_isInitialized) return;

    debugPrint('AuthService 초기화 시작');
    await _loadAuthData();
    _isInitialized = true;
    debugPrint('AuthService 초기화 완료: accessToken=${_accessToken != null}');
  }

  // 로그아웃
  Future<bool> signOut() async {
    try {
      // 소셜 로그인 SDK 로그아웃
      await _googleSignIn.signOut();
      try {
        await kakao.UserApi.instance.logout();
      } catch (e) {
        debugPrint('카카오 로그아웃 실패: $e');
      }

      // 서버에 로그아웃 요청 - 이미 인증된 사용자만 로그아웃 가능
      if (_accessToken != null) {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/user/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        );

        if (response.statusCode != 200) {
          debugPrint('서버 로그아웃 요청 실패: ${response.statusCode}, ${response.body}');
        }
      }

      // 로컬 데이터 삭제
      await _clearAuthData();
      return true;
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      return false;
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

      // 서버에 인증 정보 전송 (ParamUser 형식에 맞춤)
      final paramUser = {
        'user_email': googleUser.email,
        'user_display_name': googleUser.displayName,
        'user_photo_url': googleUser.photoUrl,
        'user_social_login_provider': 'google',
        'user_social_provider_id': googleUser.id,
        'user_notification_push': true,
      };

      return await _authenticateWithServer(paramUser);
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

      // 서버에 인증 정보 전송 (ParamUser 형식에 맞춤)
      final paramUser = {
        'user_email': kakaoUser.kakaoAccount?.email,
        'user_display_name': kakaoUser.kakaoAccount?.profile?.nickname,
        'user_photo_url': kakaoUser.kakaoAccount?.profile?.profileImageUrl,
        'user_social_login_provider': 'kakao',
        'user_social_provider_id': kakaoUser.id.toString(),
        'user_notification_push': true,
      };

      return await _authenticateWithServer(paramUser);
    } catch (e) {
      debugPrint('카카오 로그인 오류: $e');
      return false;
    }
  }

  // 애플 로그인 (틀만 구현)
  Future<bool> signInWithApple() async {
    try {
      debugPrint('애플 로그인 시작');

      // TODO: 애플 로그인 구현 (실기기 테스트 필요.)

      // 서버에 인증 정보 전송 (예시)
      // final paramUser = {
      //   'user_email': appleUser.email,
      //   'user_display_name': appleUser.displayName,
      //   'user_photo_url': appleUser.photoUrl,
      //   'user_social_login_provider': 'apple',
      //   'user_social_provider_id': appleUser.id,
      //   'user_notification_push': true,
      // };
      //
      // return await _authenticateWithServer(paramUser);

      // 임시 반환
      throw UnimplementedError('애플 로그인이 아직 구현되지 않았습니다.');
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
      return false;
    }
  }

  // 서버로 인증 정보 전송
  Future<bool> _authenticateWithServer(Map<String, dynamic> paramUser) async {
    try {
      debugPrint('서버 인증 요청: $paramUser');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(paramUser),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('서버 응답: $data');

        // 이메일로 사용자 정보 설정
        _user = {
          'email': paramUser['user_email'],
          'displayName': paramUser['user_display_name'],
          'photoUrl': paramUser['user_photo_url'],
          'provider': paramUser['user_social_login_provider'],
        };

        // 서버에서 토큰 정보 전달받음 - 토큰이 이미 유효하면 null이 올 수 있음
        _handleTokenResponse(data);

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

  // 토큰 응답 처리
  void _handleTokenResponse(Map<String, dynamic> data) {
    // 서버가 토큰을 보내면 업데이트, 그렇지 않으면 기존 토큰 유지 (이미 유효한 경우)
    if (data['access_token'] != null) {
      _accessToken = data['access_token'];
      debugPrint('새 액세스 토큰 설정: $_accessToken');
    }

    if (data['refresh_token'] != null) {
      _refreshToken = data['refresh_token'];
    }

    if (data['access_token_expires_at'] != null) {
      _accessTokenExpiresAt = DateTime.parse(data['access_token_expires_at']);
    }

    if (data['refresh_token_expires_at'] != null) {
      _refreshTokenExpiresAt = DateTime.parse(data['refresh_token_expires_at']);
    }
  }

  // 인증 데이터 로컬 저장
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 토큰 저장
      if (_accessToken != null) {
        debugPrint("access_token 저장: $_accessToken");
        await prefs.setString('access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      if (_accessTokenExpiresAt != null) {
        await prefs.setString(
          'access_token_expires_at',
          _accessTokenExpiresAt!.toIso8601String(),
        );
      }
      if (_refreshTokenExpiresAt != null) {
        await prefs.setString(
          'refresh_token_expires_at',
          _refreshTokenExpiresAt!.toIso8601String(),
        );
      }

      // 사용자 정보 저장
      if (_user != null) {
        await prefs.setString('user_data', json.encode(_user));
      }
    } catch (e) {
      debugPrint('인증 데이터 저장 오류: $e');
    }
  }

  // 저장된 인증 데이터 로드
  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 토큰 정보 로드
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');

      debugPrint('SharedPreferences에서 액세스 토큰 로드: $_accessToken');

      final accessExpiry = prefs.getString('access_token_expires_at');
      if (accessExpiry != null) {
        _accessTokenExpiresAt = DateTime.parse(accessExpiry);
      }

      final refreshExpiry = prefs.getString('refresh_token_expires_at');
      if (refreshExpiry != null) {
        _refreshTokenExpiresAt = DateTime.parse(refreshExpiry);
      }

      // 사용자 정보 로드
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = json.decode(userData);
      }

      debugPrint('저장된 인증 데이터 로드: ${_user != null ? "성공" : "데이터 없음"}');
      debugPrint('액세스 토큰: ${_accessToken != null ? "있음" : "없음"}');

      // 디버깅을 위해 SharedPreferences의 모든 키 출력
      final keys = prefs.getKeys();
      debugPrint('SharedPreferences에 저장된 모든 키: $keys');
    } catch (e) {
      debugPrint('인증 데이터 로드 오류: $e');
    }
  }

  // 인증 데이터 삭제
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('access_token_expires_at');
      await prefs.remove('refresh_token_expires_at');
      await prefs.remove('user_data');

      _accessToken = null;
      _refreshToken = null;
      _accessTokenExpiresAt = null;
      _refreshTokenExpiresAt = null;
      _user = null;

      debugPrint('인증 데이터 삭제 완료');
    } catch (e) {
      debugPrint('인증 데이터 삭제 오류: $e');
    }
  }

  // HTTP 요청 헤더 준비 (인증 필요한 API 요청용)
  Map<String, String> getAuthHeaders() {
    // 초기화가 완료되지 않았으면 대기
    if (!_isInitialized) {
      debugPrint('경고: AuthService가 초기화되기 전에 getAuthHeaders() 호출됨');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  // 초기화 완료 확인 및 대기
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // API 요청 래퍼 메소드 - 모든 API 요청에 사용
  Future<http.Response> apiRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    // 초기화 확인
    await ensureInitialized();

    final headers = getAuthHeaders();
    final url = Uri.parse('$apiBaseUrl$endpoint');

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null, // DELETE 요청에도 본문 추가
          );
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메소드: $method');
      }

      // 서버에서 새로운 토큰을 보내주면 저장
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('access_token')) {
              _handleTokenResponse(responseData);
              await _saveAuthData();
            }
          }
        } catch (e) {
          // JSON 파싱 실패는 무시 (모든 응답이 JSON이 아닐 수 있음)
        }
      }

      return response;
    } catch (e) {
      debugPrint('API 요청 오류: $e');
      rethrow;
    }
  }

  // 인증 제공자 정보 가져오기
  String? getAuthProvider() {
    return _user?['provider'];
  }

  // ============ 자동 로그인 기능 추가 ============

  // 액세스 토큰 유효성 검증
  Future<bool> verifyAccessToken() async {
    if (_accessToken == null) {
      debugPrint('액세스 토큰이 없음');
      return false;
    }

    // 액세스 토큰 만료 시간 검증 (로컬)
    if (_accessTokenExpiresAt != null &&
        _accessTokenExpiresAt!.isBefore(DateTime.now())) {
      debugPrint('액세스 토큰 만료됨: ${_accessTokenExpiresAt?.toIso8601String()}');
      return await refreshAccessToken();
    }

    try {
      // 서버에 토큰 검증 요청
      final response = await http.get(
        Uri.parse('$apiBaseUrl/user/access-token'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('액세스 토큰 검증 성공');
        return true;
      } else {
        debugPrint('액세스 토큰 검증 실패: ${response.statusCode}');
        // 토큰 갱신 시도
        return await refreshAccessToken();
      }
    } catch (e) {
      debugPrint('토큰 검증 중 오류 발생: $e');
      return false;
    }
  }

  // 리프레시 토큰으로 액세스 토큰 갱신
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null || _user == null || _user?['email'] == null) {
      debugPrint('리프레시 토큰 또는 사용자 정보 없음');
      return false;
    }

    // 리프레시 토큰 만료 체크
    if (_refreshTokenExpiresAt != null &&
        _refreshTokenExpiresAt!.isBefore(DateTime.now())) {
      debugPrint('리프레시 토큰 만료됨');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'refresh_token': _refreshToken,
          'user_email': _user?['email'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 새로운 액세스 토큰 저장
        if (data['access_token'] != null) {
          _accessToken = data['access_token'];

          if (data['access_token_expires_at'] != null) {
            _accessTokenExpiresAt = DateTime.parse(
              data['access_token_expires_at'],
            );
          }

          await _saveAuthData();
          debugPrint('액세스 토큰 갱신 성공');
          return true;
        }
      }

      debugPrint('토큰 갱신 실패: ${response.statusCode}, ${response.body}');
      return false;
    } catch (e) {
      debugPrint('토큰 갱신 중 오류 발생: $e');
      return false;
    }
  }

  // 자동 로그인 시도 - 토큰 검증 및 필요시 갱신
  Future<bool> tryAutoLogin() async {
    await ensureInitialized();

    if (_accessToken == null) {
      debugPrint('저장된 액세스 토큰 없음, 자동 로그인 실패');
      return false;
    }

    final isValid = await verifyAccessToken();

    if (!isValid) {
      debugPrint('토큰 검증 실패, 로그아웃 처리');
      await _clearAuthData();
      return false;
    }

    debugPrint('자동 로그인 성공: ${_user?['displayName']}');
    return true;
  }
}
