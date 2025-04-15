import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

class LoginScreen extends StatelessWidget {
  final Function() onLoginSuccess;

  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  // TODO Apple 로그인 이후 기능 추가
  static Future<bool> checkExistingToken() async {
    try {
      if (await AuthApi.instance.hasToken()) {
        try {
          AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
          debugPrint('토큰 유효성 체크 성공 ${tokenInfo.id} ${tokenInfo.expiresIn}');
        } catch (error) {
          if (error is KakaoException && error.isInvalidTokenError()) {
            debugPrint('토큰 만료 $error');
          } else {
            debugPrint('토큰 정보 조회 실패 $error');
          }
          return false;
        }
      } else {
        debugPrint('발급된 토큰 없음');
        return false;
      }

      return true;
    } catch (error) {
      debugPrint('로그인 실패 $error');
      return false;
    }
  }

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

                  // Apple Login Button
                  _buildLoginButtonWithIcon(
                    context: context,
                    icon: Icons.apple,
                    text: "Sign in with Apple",
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    onPressed: () {
                      // Implement Apple login logic here
                      onLoginSuccess();
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // Kakao Login - 이미지만 사용
                  GestureDetector(
                    onTap: () {
                      _handleKakaoLogin();
                    },
                    child: Image.asset(
                      'resources/kakao_login.png',
                      height: 50.0,
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Skip for now option
                  TextButton(
                    onPressed: () {
                      onLoginSuccess();
                    },
                    child: Text(
                      "Skip for now",
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 카카오 로그인 처리를 위한 별도 메서드
  Future<void> _handleKakaoLogin() async {
    // 카카오톡 설치 여부 확인
    // 카카오톡이 설치되어 있으면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인

    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();

        User user = await UserApi.instance.me();
        debugPrint('카카오계정으로 로그인 성공 ${user.kakaoAccount?.profile?.nickname}');

        onLoginSuccess();
      } catch (error) {
        debugPrint('카카오톡으로 로그인 실패 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount();

          User user = await UserApi.instance.me();
          debugPrint('카카오계정으로 로그인 성공 ${user.kakaoAccount?.profile?.nickname}');
          onLoginSuccess();
        } catch (error) {
          debugPrint('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      try {
        debugPrint('카카오톡 미설치');
        await UserApi.instance.loginWithKakaoAccount();

        User user = await UserApi.instance.me();
        debugPrint('카카오계정으로 로그인 성공 ${user.kakaoAccount?.profile?.nickname}');

        onLoginSuccess();
      } catch (error) {
        debugPrint('카카오계정으로 로그인 실패 $error');
      }
    }
  }

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
