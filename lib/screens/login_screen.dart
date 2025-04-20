import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:omninews_flutter/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function() onLoginSuccess;

  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 통합된 Auth 서비스 인스턴스
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
                  // App Logo
                  Icon(
                    Icons.article_rounded,
                    size: 80.0,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 24.0),

                  // App Name
                  Text(
                    'Omni News',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // Subtitle
                  Text(
                    'Your News, Your Way',
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
                        // Google 로그인 버튼
                        GestureDetector(
                          onTap: _handleGoogleLogin,
                          child: SvgPicture.asset(
                            'resources/google_signin_button.svg',
                            height: 50.0,
                            width: double.infinity,
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // Apple Login Button
                        _buildLoginButtonWithIcon(
                          context: context,
                          icon: Icons.apple,
                          text: "Sign in with Apple",
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          onPressed: _handleAppleLogin,
                        ),

                        const SizedBox(height: 16.0),

                        // Kakao Login Button
                        GestureDetector(
                          onTap: _handleKakaoLogin,
                          child: Image.asset(
                            'resources/kakao_login.png',
                            height: 50.0,
                          ),
                        ),

                        const SizedBox(height: 24.0),

                        // Skip for now option
                        TextButton(
                          onPressed: widget.onLoginSuccess,
                          child: Text(
                            "Skip for now",
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
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

  // Google 로그인 처리
  Future<void> _handleGoogleLogin() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('Google 로그인 시작');

      final success = await _authService.signInWithGoogle();

      if (success) {
        debugPrint('Google 로그인 성공: ${_authService.user?['displayName']}');
        debugPrint('이메일: ${_authService.user?['email']}');
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
        debugPrint('카카오 로그인 성공: ${_authService.user?['displayName']}');
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

  // 애플 로그인 처리 (틀만 구현)
  Future<void> _handleAppleLogin() async {
    try {
      setState(() => _isLoading = true);
      debugPrint('애플 로그인 시작');

      // 현재는 구현되지 않았으므로 안내 메시지 표시
      _showErrorSnackbar('애플 로그인은 아직 준비 중입니다.');

      // 추후 구현 시 아래 코드 활성화
      // final success = await _authService.signInWithApple();
      // if (success) {
      //   widget.onLoginSuccess();
      // }
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
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

  // 로그인 버튼 위젯
  Widget _buildLoginButtonWithIcon({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 12.0),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
