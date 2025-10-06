import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:omninews_flutter/services/auth_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    show
        SignInWithApple,
        SignInWithAppleButton,
        SignInWithAppleButtonStyle,
        AppleIDAuthorizationScopes;

class LoginScreen extends StatefulWidget {
  final Function() onLoginSuccess;

  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 로고 길게 누르기 또는 5회 탭 → 데모 로그인 시트
                  GestureDetector(
                    onLongPress: _showDemoLoginSheet,
                    onTap: _handleSecretTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'resources/omninews_icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  Text(
                    'OmniNews',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    '나만의 뉴스, 나만의 방식',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 48.0),

                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        _buildGoogleLoginButton(),
                        const SizedBox(height: 16.0),
                        _buildLoginButtonWithIcon(), // Apple
                        const SizedBox(height: 16.0),
                        _buildKakaoLoginButton(),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _secretTapCount = 0;
  DateTime? _tapWindowStart;
  void _handleSecretTap() {
    final now = DateTime.now();
    if (_tapWindowStart == null ||
        now.difference(_tapWindowStart!) > const Duration(seconds: 4)) {
      _tapWindowStart = now;
      _secretTapCount = 0;
    }
    _secretTapCount++;
    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _showDemoLoginSheet();
    }
  }

  Future<void> _showDemoLoginSheet() async {
    if (!mounted) return;
    final theme = Theme.of(context);
    final emailCtrl = TextEditingController(text: '');
    final pwCtrl = TextEditingController(text: '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_open),
                      const SizedBox(width: 8),
                      Text(
                        'Reviewer Demo Login',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('데모 로그인'),
                      onPressed: () async {
                        final email = emailCtrl.text.trim();
                        final pw = pwCtrl.text;
                        if (email.isEmpty || pw.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이메일/비밀번호를 입력해 주세요.')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        await _handleDemoLogin(email, pw);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleDemoLogin(String email, String password) async {
    try {
      setState(() => _isLoading = true);
      final ok = await _authService.signInWithDemoCredentials(email, password);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('데모 계정으로 로그인되었습니다.')));
        widget.onLoginSuccess();
      } else {
        _showErrorSnackbar('데모 로그인에 실패했습니다.');
      }
    } catch (e) {
      _showErrorSnackbar('데모 로그인 중 오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Google 로그인 버튼 (SVG 아이콘 포함)
  Widget _buildGoogleLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 2,
        ),
        onPressed: _handleGoogleLogin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              '''
              <svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" xmlns:xlink="http://www.w3.org/1999/xlink" style="display: block; width: 24px; height: 24px;">
                <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"></path>
                <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"></path>
                <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"></path>
                <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"></path>
                <path fill="none" d="M0 0h48v48H0z"></path>
              </svg>
              ''',
              width: 24.0,
              height: 24.0,
            ),
            const SizedBox(width: 12.0),
            const Text(
              "Google로 로그인",
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Kakao 로그인 버튼 (SVG 아이콘 포함)
  Widget _buildKakaoLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFE812), // Kakao Yellow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 2,
        ),
        onPressed: _handleKakaoLogin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              '''
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" style="display: block; width: 28px; height: 28px;">
                <path fill="#3C1E1E" d="M12 2C6.48 2 2 5.99 2 10.5c0 3.06 2.1 5.73 5.2 7.14-.23.88-.85 3.2-1.03 3.85 0 0-.02.12.06.17.08.05.18 0 .18 0 .24-.03 3.17-2 4.44-2.76.38.05.77.08 1.15.08 5.52 0 10-3.99 10-8.5S17.52 2 12 2z"></path>
              </svg>
              ''',
              width: 28.0,
              height: 28.0,
            ),
            const SizedBox(width: 12.0),
            const Text(
              "카카오로 로그인",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3C1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Google 로그인 처리
  Future<void> _handleGoogleLogin() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('Google 로그인 시작');

      final success = await _authService.signInWithGoogle();

      if (success) {
        final hasPermission =
            await _authService.requestNotificationPermissions();
        debugPrint('알림 권한 요청 결과: $hasPermission');
        widget.onLoginSuccess();
      } else {
        debugPrint('Google 로그인 취소 또는 실패');
      }
    } catch (e) {
      debugPrint('Google 로그인 오류: $e');
      _showErrorSnackbar('Google 로그인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 카카오 로그인 처리
  Future<void> _handleKakaoLogin() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('카카오 로그인 시작');

      final success = await _authService.signInWithKakao();

      if (success) {
        final hasPermission =
            await _authService.requestNotificationPermissions();
        debugPrint('알림 권한 요청 결과: $hasPermission');
        widget.onLoginSuccess();
      } else {
        debugPrint('카카오 로그인 취소 또는 실패');
      }
    } catch (e) {
      debugPrint('카카오 로그인 오류: $e');
      _showErrorSnackbar('카카오 로그인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 애플 로그인 처리
  Future<void> _handleAppleLogin() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('애플 로그인 시작');

      final success = await _authService.signInWithApple();
      if (success) {
        final hasPermission =
            await _authService.requestNotificationPermissions();
        debugPrint('알림 권한 요청 결과: $hasPermission');

        widget.onLoginSuccess();
      }
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
      _showErrorSnackbar('로그인 처리 중 오류가 발생했습니다. 나중에 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 에러 메시지 표시
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 애플 로그인 버튼 위젯
  Widget _buildLoginButtonWithIcon() {
    return SignInWithAppleButton(
      onPressed: _handleAppleLogin,
      style: SignInWithAppleButtonStyle.black,
      height: 44,
      borderRadius: BorderRadius.circular(8),
      text: 'Apple로 로그인',
    );
  }
}
