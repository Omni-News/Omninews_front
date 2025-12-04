import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  // 싱글톤
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 초기화 상태
  bool _isInitialized = false;
  Future<void>? _initializeFuture;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    serverClientId:
        Platform.isAndroid ? dotenv.env['GOOGLE_SERVER_CLIENT_ID'] : null,
    clientId: Platform.isIOS ? dotenv.env['GOOGLE_CLIENT_ID'] : null,
  );

  static String apiBaseUrl = 'https://api.kang1027.com/v1/api';
  //static String apiBaseUrl = 'http://61.253.113.42:1028/v1/api';

  // 토큰/유저
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiresAt;
  DateTime? _refreshTokenExpiresAt;
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _accessToken != null;
  String? get accessToken => _accessToken;

  bool _isRefreshing = false;

  // 초기화
  Future<void> initialize() async {
    if (_initializeFuture != null) return _initializeFuture!;
    _initializeFuture = _initializeInternal();
    return _initializeFuture!;
  }

  Future<void> _initializeInternal() async {
    if (_isInitialized) return;
    debugPrint('AuthService 초기화 시작');
    await _loadAuthData();

    if (_accessToken != null && isTokenExpired()) {
      debugPrint('초기화 중 만료된 액세스 토큰 감지, 갱신 시도');
      await refreshAccessToken();
    }

    _isInitialized = true;
    debugPrint('AuthService 초기화 완료: accessToken=${_accessToken != null}');
  }

  bool isTokenExpired() {
    if (_accessTokenExpiresAt == null) return true;
    final expiryWithBuffer = _accessTokenExpiresAt!.subtract(
      const Duration(minutes: 1),
    );
    return expiryWithBuffer.isBefore(DateTime.now());
  }

  // 로그아웃
  Future<bool> signOut() async {
    try {
      final provider = getAuthProvider();

      if (provider == 'google') {
        await _googleSignIn.signOut();
      }
      if (provider == 'kakao') {
        try {
          await kakao.UserApi.instance.logout();
        } catch (e) {
          debugPrint('카카오 로그아웃 실패: $e');
        }
      }

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

      await _clearAuthData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_subscription');

      return true;
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      return false;
    }
  }

  // 회원 탈퇴
  Future<bool> deleteAccount() async {
    try {
      await ensureInitialized();

      final resp = await apiRequest('DELETE', '/user/delete');
      debugPrint('회원 탈퇴 응답: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          await disableNotifications();
          await FirebaseMessaging.instance.deleteToken();
        } catch (e) {
          debugPrint('알림 비활성화/토큰 삭제 중 오류: $e');
        }

        await _clearAuthData();

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

  // 데모 로그인: /user/demo_login
  Future<bool> signInWithDemoCredentials(String email, String password) async {
    try {
      final resp = await http.post(
        Uri.parse('$apiBaseUrl/user/demo_login'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          // 서버 계약에 맞게 필드명 고정
          'user_email': email,
          'user_password': password,
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final raw = json.decode(resp.body);
        final Map<String, dynamic> data =
            raw is Map<String, dynamic>
                ? (raw['data'] is Map<String, dynamic>
                    ? raw['data'] as Map<String, dynamic>
                    : raw)
                : <String, dynamic>{};

        await _applyAuthFromResponse(
          data,
          defaultEmail: (data['user_email'] as String?) ?? email,
          defaultDisplayName:
              (data['user_display_name'] as String?) ?? email.split('@').first,
          defaultPhotoUrl: data['user_photo_url'] as String?,
          defaultProvider: 'demo',
        );

        // 공통: 계정 전환 탐지용 기록
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_login_time',
          DateTime.now().toIso8601String(),
        );
        await prefs.setString('last_login_email', _user!['email']);

        return true;
      }

      debugPrint('데모 로그인 실패: ${resp.statusCode} ${resp.body}');
      return false;
    } catch (e) {
      debugPrint('데모 로그인 오류: $e');
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

      await googleUser.authentication; // 필요 시 사용

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

  // Kakao 로그인
  Future<bool> signInWithKakao() async {
    try {
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          debugPrint('카카오톡 로그인 실패: $error');
          if (error.toString().contains('CANCELED')) {
            return false;
          }
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final kakao.User kakaoUser = await kakao.UserApi.instance.me();

      final paramUser = {
        'user_email': kakaoUser.kakaoAccount?.email,
        'user_display_name': kakaoUser.kakaoAccount?.profile?.nickname,
        'user_photo_url': kakaoUser.kakaoAccount?.profile?.profileImageUrl,
        'user_social_login_provider': 'kakao',
        'user_social_provider_id': kakaoUser.id.toString(),
        'user_notification_push': true,
      };

      debugPrint('카카오 로그인 시작');
      return await _authenticateWithServer(paramUser);
    } catch (e) {
      debugPrint('카카오 로그인 오류: $e');
      return false;
    }
  }

  // Apple 로그인
  Future<bool> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('Apple ID 정보 받음');
      debugPrint('이메일: ${credential.email}');
      debugPrint('이름: ${credential.givenName}');
      debugPrint('성: ${credential.familyName}');
      debugPrint('ID: ${credential.userIdentifier}');

      String? displayName;
      if (credential.givenName != null) {
        displayName =
            credential.familyName != null
                ? '${credential.givenName} ${credential.familyName}'
                : credential.givenName;
      }

      String? email = credential.email;

      if (email == null && credential.userIdentifier != null) {
        debugPrint('로그인을 시도합니다.');
        if (await verifyAccessToken()) {
          debugPrint('이미 로그인된 사용자입니다.');
          return true;
        }
        final success = await _appleLogin(credential.userIdentifier!);
        return success;
      }

      debugPrint('회원가입을 시도합니다.');

      final paramUser = {
        'user_email': email,
        'user_display_name': displayName,
        'user_photo_url': null,
        'user_social_login_provider': 'apple',
        'user_social_provider_id': credential.userIdentifier,
        'user_identity_token': credential.identityToken,
        'user_authorization_code': credential.authorizationCode,
      };

      final success = await _authenticateWithServer(paramUser);
      return success;
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
      return false;
    }
  }

  // 공용 서버 로그인
  Future<bool> _authenticateWithServer(Map<String, dynamic> paramUser) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/login'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(paramUser),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final raw = json.decode(response.body);
        final Map<String, dynamic> data =
            raw is Map<String, dynamic>
                ? (raw['data'] is Map<String, dynamic>
                    ? raw['data'] as Map<String, dynamic>
                    : raw)
                : <String, dynamic>{};

        await _applyAuthFromResponse(
          data,
          defaultEmail:
              (paramUser['user_email'] as String?) ?? 'unknown@example.com',
          defaultDisplayName:
              (paramUser['user_display_name'] as String?) ?? 'Unknown User',
          defaultPhotoUrl: paramUser['user_photo_url'] as String?,
          defaultProvider:
              (paramUser['user_social_login_provider'] as String?) ?? 'unknown',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_login_time',
          DateTime.now().toIso8601String(),
        );
        await prefs.setString('last_login_email', _user!['email']);

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

  // 공통 적용(토큰/유저 저장)
  Future<void> _applyAuthFromResponse(
    Map<String, dynamic> data, {
    required String defaultEmail,
    required String defaultDisplayName,
    required String? defaultPhotoUrl,
    required String defaultProvider,
  }) async {
    if (data['access_token'] != null) {
      _accessToken = data['access_token'] as String;
    }
    if (data['refresh_token'] != null) {
      _refreshToken = data['refresh_token'] as String;
    }
    if (data['access_token_expires_at'] != null) {
      _accessTokenExpiresAt = DateTime.tryParse(
        data['access_token_expires_at'].toString(),
      );
    }
    if (data['refresh_token_expires_at'] != null) {
      _refreshTokenExpiresAt = DateTime.tryParse(
        data['refresh_token_expires_at'].toString(),
      );
    }

    final email = (data['user_email'] as String?) ?? defaultEmail;
    final displayName =
        (data['user_display_name'] as String?) ?? defaultDisplayName;
    final photoUrl = (data['user_photo_url'] as String?) ?? defaultPhotoUrl;
    final theme = data['theme'];

    _user = {
      'email': (email.isEmpty) ? 'unknown@example.com' : email,
      'displayName': (displayName.isEmpty) ? 'Unknown User' : displayName,
      'photoUrl': photoUrl,
      'provider': defaultProvider,
      'theme': theme,
      'recentLogin': true,
    };

    await _saveAuthData();
  }

  // Apple 전용 보조 로그인
  Future<bool> _appleLogin(String userSocialProviderId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/apple/login'),
        headers: getAuthHeaders(),
        body: json.encode({'user_social_provider_id': userSocialProviderId}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final raw = json.decode(response.body);
        final Map<String, dynamic> data =
            raw is Map<String, dynamic>
                ? (raw['data'] is Map<String, dynamic>
                    ? raw['data'] as Map<String, dynamic>
                    : raw)
                : <String, dynamic>{};

        _user = {
          'email': data['user_email'] ?? 'apple_user@example.com',
          'displayName': data['user_display_name'] ?? 'Apple User',
          'photoUrl': data['user_photo_url'],
          'provider': 'apple',
          'social_provider_id': userSocialProviderId,
          'recentLogin': true,
        };

        _handleTokenResponse(data);
        await _saveAuthData();

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

  // 토큰 응답 처리
  void _handleTokenResponse(Map<String, dynamic> data) {
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

  // 로컬 저장
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

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

      if (_user != null) {
        await prefs.setString('user_data', json.encode(_user));
      }
    } catch (e) {
      debugPrint('인증 데이터 저장 오류: $e');
    }
  }

  // 로컬 로드
  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

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

      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = json.decode(userData);
        debugPrint('로드된 사용자 정보: $user');

        final email = _user?['email'];
        if (email == null || (email is String && email.isEmpty)) {
          debugPrint('경고: 사용자 정보에 이메일이 없거나 빈 값입니다!');
        }
      }

      debugPrint('저장된 인증 데이터 로드: ${_user != null ? "성공" : "데이터 없음"}');

      final keys = prefs.getKeys();
      debugPrint('SharedPreferences에 저장된 모든 키: $keys');

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

    final requiredFields = ['email', 'displayName', 'provider'];
    for (final field in requiredFields) {
      if (!_user!.containsKey(field) ||
          _user![field] == null ||
          (_user![field] is String && _user![field].isEmpty)) {
        debugPrint('경고: 사용자 정보에 $field 필드가 없거나 빈 값입니다');
      }
    }
  }

  // 로컬 삭제
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

  Map<String, String> getAuthHeaders() {
    if (!_isInitialized) {
      debugPrint('경고: AuthService가 초기화되기 전에 getAuthHeaders() 호출됨');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // 공통 API 요청(토큰 자동 갱신)
  Future<http.Response> apiRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool retrying = false,
  }) async {
    await ensureInitialized();

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
            body: body != null ? json.encode(body) : null,
          );
          break;
        default:
          throw Exception('지원하지 않는 HTTP 메소드: $method');
      }

      if (response.statusCode == 401 && !retrying) {
        debugPrint('401 Unauthorized 응답, 토큰 갱신 시도');
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return apiRequest(method, endpoint, body: body, retrying: true);
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('access_token')) {
            _handleTokenResponse(responseData);
            await _saveAuthData();
          }
        } catch (_) {}
      }

      return response;
    } catch (e) {
      debugPrint('API 요청 오류: $e');
      rethrow;
    }
  }

  // 최근 로그인 플래그
  bool isRecentLogin() {
    return _user != null && _user!['recentLogin'] == true;
  }

  void resetRecentLoginFlag() {
    if (_user != null) {
      _user!['recentLogin'] = false;
      _saveAuthData();
    }
  }

  String? getAuthProvider() {
    return _user?['provider'];
  }

  // 토큰 검증
  Future<bool> verifyAccessToken() async {
    if (_accessToken == null) {
      debugPrint('액세스 토큰이 없음');
      return false;
    }

    if (_accessTokenExpiresAt != null &&
        _accessTokenExpiresAt!.isBefore(DateTime.now())) {
      debugPrint('액세스 토큰 만료됨: ${_accessTokenExpiresAt?.toIso8601String()}');
      return await refreshAccessToken();
    }

    try {
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
        return await refreshAccessToken();
      }
    } catch (e) {
      debugPrint('토큰 검증 중 오류 발생: $e');
      return false;
    }
  }

  // 토큰 갱신
  Future<bool> refreshAccessToken() async {
    if (_isRefreshing) {
      debugPrint('토큰 갱신이 이미 진행 중입니다.');
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
      if (_user == null || _refreshToken == null) {
        await _loadAuthData();
      }

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

      if (_refreshTokenExpiresAt != null &&
          _refreshTokenExpiresAt!.isBefore(DateTime.now())) {
        debugPrint('리프레시 토큰 만료됨');
        _isRefreshing = false;
        return false;
      }

      debugPrint('리프레시 토큰 요청 - 토큰: $refreshToken, 이메일: $userEmail');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/refresh-token'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'token': refreshToken, 'email': userEmail}),
      );

      debugPrint('리프레시 토큰 응답: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

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

  // 자동 로그인
  Future<bool> tryAutoLogin() async {
    await ensureInitialized();

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
      debugPrint('저장된 토큰 없음, 자동 로그인 실패');
      return false;
    }

    if (isTokenExpired()) {
      debugPrint('액세스 토큰 만료됨, 갱신 시도');
      final isValid = await refreshAccessToken();
      if (!isValid) {
        debugPrint('토큰 갱신 실패, 로그아웃 처리');
        await _clearAuthData();
        return false;
      }
    } else {
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

  // 알림 권한 및 토큰 저장
  Future<bool> requestNotificationPermissions() async {
    if (!isLoggedIn) return false;

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        try {
          for (int i = 0; i < 3; i++) {
            final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (apnsToken != null) {
              final token = await FirebaseMessaging.instance.getToken();
              debugPrint("token: $token");
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

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('Android FCM 토큰: $token');
      if (token != null) {
        return await saveUserNotificationSettings(token);
      }
    } catch (e) {
      debugPrint('Android FCM 토큰 가져오기 오류: $e');
    }
    return false;
  }

  Future<bool> disableNotifications() async {
    try {
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.getAPNSToken();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        return await saveUserNotificationSettings(token, enablePush: false);
      }
    } catch (e) {
      debugPrint('알림 끄기 오류: $e');
    }
    return false;
  }

  Future<bool> saveUserNotificationSettings(
    String fcmToken, {
    bool enablePush = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/user/notification'),
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

  // 테스트용
  Future<bool> testTokenRefresh() async {
    _accessToken = null;
    await _saveAuthData();
    debugPrint('액세스 토큰을 강제로 삭제했습니다');

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

// nonce/sha256
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
