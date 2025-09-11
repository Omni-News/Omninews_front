import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  static String apiBaseUrl = 'http://localhost:1027/v1/api';

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

  // 토큰 갱신 중 플래그 (중복 갱신 방지)
  bool _isRefreshing = false;

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

    // 초기화 과정에서 액세스 토큰 유효성 확인 및 갱신
    if (_accessToken != null && isTokenExpired()) {
      debugPrint('초기화 중 만료된 액세스 토큰 감지, 갱신 시도');
      await refreshAccessToken();
    }

    _isInitialized = true;
    debugPrint('AuthService 초기화 완료: accessToken=${_accessToken != null}');
  }

  // 토큰 만료 확인 헬퍼 메서드
  bool isTokenExpired() {
    // 만료 시간이 설정되지 않았다면 만료된 것으로 간주
    if (_accessTokenExpiresAt == null) return true;

    // 만료 시간 1분 전에 갱신하도록 설정 (버퍼)
    final expiryWithBuffer = _accessTokenExpiresAt!.subtract(
      const Duration(minutes: 1),
    );
    return expiryWithBuffer.isBefore(DateTime.now());
  }

  // 로그아웃
  Future<bool> signOut() async {
    try {
      // 소셜 로그인 SDK 로그아웃
      String? provider = getAuthProvider();

      // 구글 로그아웃
      if (provider == 'google') {
        await _googleSignIn.signOut();
      }

      // 카카오 로그아웃
      if (provider == 'kakao') {
        try {
          await kakao.UserApi.instance.logout();
        } catch (e) {
          debugPrint('카카오 로그아웃 실패: $e');
        }
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

      // 로컬 데이터 삭제 (구독 정보 포함)
      await _clearAuthData();

      // 구독 정보도 삭제 (별도 처리)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_subscription');

      return true;
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      return false;
    }
  }

  // ============ 회원 탈퇴(계정 삭제) ============

  /// 서버 회원 탈퇴 API 호출 후 로컬 데이터 정리
  /// - DELETE /user/delete
  /// - 백엔드 미들웨어에서 인증 검증
  Future<bool> deleteAccount() async {
    try {
      await ensureInitialized();

      final resp = await apiRequest('DELETE', '/user/delete');
      debugPrint('회원 탈퇴 응답: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // 1) 알림 비활성화(서버에 push off 전달)
        try {
          await disableNotifications();
          // 선택: FCM 토큰 자체 삭제
          await FirebaseMessaging.instance.deleteToken();
        } catch (e) {
          debugPrint('알림 비활성화/토큰 삭제 중 오류: $e');
        }

        // 2) 로컬 인증/사용자 데이터 정리
        await _clearAuthData();

        // 3) 기타 캐시/상태 제거
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_subscription');
        await prefs.remove('last_login_time');
        await prefs.remove('last_login_email');

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('회원 탈퇴 중 오류: $e');
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

      final GoogleSignInAuthentication _googleAuth =
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

      debugPrint('카카오 사용자 정보: $paramUser');
      return await _authenticateWithServer(paramUser);
    } catch (e) {
      debugPrint('카카오 로그인 오류: $e');
      return false;
    }
  }

  // 애플 로그인
  Future<bool> signInWithApple() async {
    try {
      // nonce 생성 추가
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce, // nonce 추가
      );

      // 로그인 결과 정보 디버깅
      debugPrint('Apple ID 정보 받음');
      debugPrint('이메일: ${credential.email}');
      debugPrint('이름: ${credential.givenName}');
      debugPrint('성: ${credential.familyName}');
      debugPrint('ID: ${credential.userIdentifier}');

      // 사용자 이름 처리 (Apple은 최초 로그인시에만 이름 제공)
      String? displayName;
      if (credential.givenName != null) {
        displayName =
            credential.familyName != null
                ? '${credential.givenName} ${credential.familyName}'
                : credential.givenName;
      }

      // 이메일 처리 (익명 이메일일 수 있음)
      String? email = credential.email;

      // 애플 로그인은 최초 로그인 시에만 이메일을 제공하므로, 이후에는 null이 될 수 있음
      if (email == null && credential.userIdentifier != null) {
        debugPrint('로그인을 시도합니다.');
        if (await verifyAccessToken()) {
          // 이미 로그인된 상태라면 애플 로그인은 필요 없음
          debugPrint('이미 로그인된 사용자입니다.');
          return true;
        }

        bool success = await _appleLogin(credential.userIdentifier!);
        if (success) {
          return true;
        } else {
          return false;
        }
      }

      debugPrint('회원가입을 시도합니다.');

      // 서버에 인증 정보 전송 (ParamUser 형식에 맞춤)
      final paramUser = {
        'user_email': email,
        'user_display_name': displayName,
        'user_photo_url': null, // Apple은 사진 제공 안함
        'user_social_login_provider': 'apple',
        'user_social_provider_id': credential.userIdentifier,
        'user_identity_token': credential.identityToken, // Apple 전용 토큰
        'user_authorization_code': credential.authorizationCode, // Apple 전용 코드
      };

      bool success = await _authenticateWithServer(paramUser);

      if (success) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
      return false;
    }
  }

  // 서버로 인증 정보 전송
  Future<bool> _authenticateWithServer(Map<String, dynamic> paramUser) async {
    try {
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
          'email': paramUser['user_email'] ?? 'unknown@example.com',
          'displayName': paramUser['user_display_name'] ?? 'Unknown User',
          'photoUrl': paramUser['user_photo_url'],
          'provider': paramUser['user_social_login_provider'],
          'theme': data['theme'], // 서버에서 받은 테마 정보 저장
          'recentLogin': true, // 최근 로그인 표시 추가
        };

        // 저장 전 데이터 검증
        if (_user!['email'] == null || _user!['email'].isEmpty) {
          debugPrint('경고: 로그인은 성공했지만 사용자 이메일이 비어 있습니다.');
          _user!['email'] = 'unknown@example.com';
        }

        // 서버에서 토큰 정보 전달받음 - 토큰이 이미 유효하면 null이 올 수 있음
        _handleTokenResponse(data);

        // 로컬 저장소에 저장
        await _saveAuthData();

        // 로그인 시간 기록 (계정 전환 탐지용)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_login_time',
          DateTime.now().toIso8601String(),
        );
        await prefs.setString('last_login_email', _user!['email']);

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
      debugPrint('SharedPreferences에서 리프레시 토큰 로드: $_refreshToken');

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
        debugPrint('로드된 사용자 정보: $user');

        // 사용자 이메일 검증
        final email = _user?['email'];
        if (email == null || email.isEmpty) {
          debugPrint('경고: 사용자 정보에 이메일이 없거나 빈 값입니다!');
        }
      }

      debugPrint('저장된 인증 데이터 로드: ${_user != null ? "성공" : "데이터 없음"}');

      // 디버깅을 위해 SharedPreferences의 모든 키 출력
      final keys = prefs.getKeys();
      debugPrint('SharedPreferences에 저장된 모든 키: $keys');

      // 핵심 값들을 검증
      _validateLoadedAuthData();
    } catch (e) {
      debugPrint('인증 데이터 로드 오류: $e');
    }
  }

  void _validateLoadedAuthData() {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      debugPrint('경고: 리프레시 토큰이 없거나 빈 값입니다');
    }

    if (_user == null) {
      debugPrint('경고: 사용자 정보가 없습니다');
      return;
    }

    // 필수 필드 검증
    final requiredFields = ['email', 'displayName', 'provider'];
    for (final field in requiredFields) {
      if (!_user!.containsKey(field) ||
          _user![field] == null ||
          _user![field].isEmpty) {
        debugPrint('경고: 사용자 정보에 $field 필드가 없거나 빈 값입니다');
      }
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

  // API 요청 래퍼 메소드 - 모든 API 요청에 사용 (자동 토큰 갱신 기능 추가)
  Future<http.Response> apiRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool retrying = false, // 재시도 플래그 추가
  }) async {
    // 초기화 확인
    await ensureInitialized();

    // 요청 전 토큰 상태 확인 (retrying이 false일 때만)
    if (!retrying && (_accessToken == null || isTokenExpired())) {
      debugPrint('액세스 토큰이 없거나 만료됨, 갱신 시도');
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        debugPrint('토큰 갱신 실패, 로그인 필요');
        throw Exception('인증이 필요합니다.');
      }
    }

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

      // 401 응답을 받고 재시도하지 않은 경우 토큰 갱신 후 재시도
      if (response.statusCode == 401 && !retrying) {
        debugPrint('401 Unauthorized 응답, 토큰 갱신 시도');
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // 재귀적으로 동일한 요청을 재시도 (무한 루프 방지를 위해 retrying 플래그 사용)
          return apiRequest(method, endpoint, body: body, retrying: true);
        }
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

  // 계정 전환 여부 확인
  bool isRecentLogin() {
    // user에 recentLogin 플래그가 있으면 최근 로그인
    return _user != null && _user!['recentLogin'] == true;
  }

  // 최근 로그인 플래그 리셋
  void resetRecentLoginFlag() {
    if (_user != null) {
      _user!['recentLogin'] = false;
      _saveAuthData(); // 변경사항 저장
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
    // 이미 갱신 중이면 기다림
    if (_isRefreshing) {
      debugPrint('토큰 갱신이 이미 진행 중입니다.');
      // 5초 동안 토큰 갱신이 완료될 때까지 대기
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_isRefreshing && _accessToken != null) {
          return true;
        }
      }
      return _accessToken != null;
    }

    _isRefreshing = true;

    try {
      // 데이터가 이미 로드되어 있는지 확인하고, 아니면 로드 시도
      if (_user == null || _refreshToken == null) {
        await _loadAuthData();
      }

      // 디버깅을 위해 현재 값들 출력
      debugPrint('리프레시 토큰 값: $_refreshToken');
      debugPrint('사용자 정보: $_user');

      // 널 체크 강화
      final refreshToken = _refreshToken;
      final userEmail = _user?['email'];

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('리프레시 토큰이 없거나 빈 값입니다');
        _isRefreshing = false;
        return false;
      }

      if (userEmail == null || userEmail.isEmpty) {
        debugPrint('사용자 이메일이 없거나 빈 값입니다');
        _isRefreshing = false;
        return false;
      }

      // 리프레시 토큰 만료 체크
      if (_refreshTokenExpiresAt != null &&
          _refreshTokenExpiresAt!.isBefore(DateTime.now())) {
        debugPrint('리프레시 토큰 만료됨');
        _isRefreshing = false;
        return false;
      }

      debugPrint('리프레시 토큰 요청 - 토큰: $refreshToken, 이메일: $userEmail');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'token': refreshToken, 'email': userEmail}),
      );

      // 응답 로깅 추가
      debugPrint('리프레시 토큰 응답: ${response.statusCode}, ${response.body}');

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
          _isRefreshing = false;
          return true;
        }
      }

      debugPrint('토큰 갱신 실패: ${response.statusCode}, ${response.body}');
      _isRefreshing = false;
      return false;
    } catch (e) {
      debugPrint('토큰 갱신 중 오류 발생: $e');
      _isRefreshing = false;
      return false;
    }
  }

  // 자동 로그인 시도 - 토큰 검증 및 필요시 갱신 (개선됨)
  Future<bool> tryAutoLogin() async {
    await ensureInitialized();

    // 액세스 토큰이 없으면 리프레시 토큰으로 갱신 시도
    if (_accessToken == null && _refreshToken != null) {
      debugPrint('액세스 토큰 없음, 리프레시 토큰으로 갱신 시도');
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        debugPrint('리프레시 토큰으로 갱신 실패, 로그아웃 처리');
        await _clearAuthData();
        return false;
      }
      return true;
    } else if (_accessToken == null) {
      // 두 토큰 모두 없으면 로그인 필요
      debugPrint('저장된 토큰 없음, 자동 로그인 실패');
      return false;
    }

    // 액세스 토큰이 있지만 만료된 경우
    if (isTokenExpired()) {
      debugPrint('액세스 토큰 만료됨, 갱신 시도');
      final isValid = await refreshAccessToken();
      if (!isValid) {
        debugPrint('토큰 갱신 실패, 로그아웃 처리');
        await _clearAuthData();
        return false;
      }
    } else {
      // 토큰이 있고 만료되지 않았을 때도 유효성 확인
      final isValid = await verifyAccessToken();
      if (!isValid) {
        debugPrint('토큰 검증 실패, 로그아웃 처리');
        await _clearAuthData();
        return false;
      }
    }

    debugPrint('자동 로그인 성공: ${_user?['displayName']}');
    return true;
  }

  Future<bool> requestNotificationPermissions() async {
    //  이미 로그인된 사용자만 권한 요청
    if (!isLoggedIn) return false;

    // iOS에서 권한 요청
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        try {
          // 여러번 시도
          for (int i = 0; i < 3; i++) {
            final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (apnsToken != null) {
              String? token = await FirebaseMessaging.instance.getToken();
              debugPrint("token: ${token}");
              if (token != null) {
                return await saveUserNotificationSettings(token);
              }
              break;
            }
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          debugPrint('FCM 토큰 처리 오류: $e');
        }
      }
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    // Android는 기본적으로 권한이 있음 (Android 13+ 제외)
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint('Android FCM 토큰: $token');
      if (token != null) {
        return await saveUserNotificationSettings(token);
      }
    } catch (e) {
      debugPrint('Android FCM 토큰 가져오기 오류: $e');
    }
    return false;
  }

  // 알림 끄기
  Future<bool> disableNotifications() async {
    try {
      if (Platform.isIOS) {
        // iOS에서는 APNS 토큰 확인 후 진행
        await FirebaseMessaging.instance.getAPNSToken();
      }

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        return await saveUserNotificationSettings(token, enablePush: false);
      }
    } catch (e) {
      debugPrint('알림 끄기 오류: $e');
    }
    return false;
  }

  // 서버에 FCM 토큰 저장
  Future<bool> saveUserNotificationSettings(
    String fcmToken, {
    bool enablePush = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${apiBaseUrl}/user/notification'),
        headers: getAuthHeaders(),
        body: json.encode({
          'user_notification_push': enablePush,
          'user_fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('알림 설정 저장 성공, fcm token: $fcmToken');
        return true;
      } else {
        debugPrint('알림 설정 저장 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('알림 설정 저장 오류: $e');
      return false;
    }
  }

  Future<bool> _appleLogin(String userSocialProviderId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/apple/login'),
        headers: getAuthHeaders(),
        body: json.encode({'user_social_provider_id': userSocialProviderId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('서버 응답: $data');

        // 이메일로 사용자 정보 설정 (서버 응답에서 이메일을 가져오거나 기본값 사용)
        _user = {
          'email': data['user_email'] ?? 'apple_user@example.com',
          'displayName': data['user_display_name'] ?? 'Apple User',
          'photoUrl': data['user_photo_url'],
          'provider': 'apple',
          'social_provider_id': userSocialProviderId,
        };

        // 서버에서 토큰 정보 전달받음 - 토큰이 이미 유효하면 null이 올 수 있음
        _handleTokenResponse(data);

        // 로컬 저장소에 저장
        await _saveAuthData();

        debugPrint('서버 인증 성공: ${_user?['displayName']}');
        return true;
      } else {
        debugPrint('애플 로그인 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
      return false;
    }
  }

  // 테스트용 함수 - 앱에서 호출하여 토큰 갱신 테스트
  Future<bool> testTokenRefresh() async {
    // 액세스 토큰 강제로 무효화
    _accessToken = null;
    await _saveAuthData(); // 변경사항 저장

    debugPrint('액세스 토큰을 강제로 삭제했습니다');

    // 일반 API 요청으로 자동 갱신 테스트
    try {
      final response = await apiRequest('GET', '/user/profile');
      debugPrint('API 요청 응답: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('테스트 중 오류: $e');
      return false;
    }
  }
}

// nonce 생성 및 sha256 변환 함수 추가
String generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
