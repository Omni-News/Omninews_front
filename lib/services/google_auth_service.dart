// services/google_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase를 통한 Google 로그인을 처리하는 서비스 클래스
class GoogleAuthService {
  // Firebase Auth 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GoogleSignIn 인스턴스
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
    clientId: dotenv.env['GOOGLE_CLIENT_ID'],
  );

  /// Google 계정으로 로그인하고 인증된 Firebase User를 반환합니다.
  ///
  /// 로그인 과정이 취소되거나 실패하면 `null`을 반환합니다.
  Future<User?> signInWithGoogle() async {
    try {
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // 사용자가 로그인을 취소한 경우
      if (googleUser == null) {
        return null;
      }

      // Google 계정에서 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Google 인증 정보로 Firebase 인증 정보 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 Google 인증 정보로 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // 인증된 사용자 반환
      return userCredential.user;
    } catch (e, stackTrace) {
      // 상세한 오류 정보 출력
      debugPrint('🔴 Google 로그인 오류: $e');
      debugPrint('🔴 스택 트레이스: $stackTrace');
      return null;
    }
  }

  /// Google과 Firebase 모두에서 로그아웃합니다.
  Future<void> signOut() async {
    // Google에서 로그아웃
    await _googleSignIn.signOut();

    // Firebase에서 로그아웃
    await _auth.signOut();
  }
}
