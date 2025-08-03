import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:io' show Platform;
import 'package:omninews_flutter/models/omninews_subscription.dart';
import 'package:omninews_flutter/services/auth_service.dart';

/// 인앱 구매 영수증 검증을 처리하는 서비스
class ReceiptValidator {
  // 샌드박스 환경인지 여부
  final bool _isTestEnvironment = !kReleaseMode;
  final AuthService _authService = AuthService();

  /// 영수증 검증 (API 스펙 적용)
  Future<ReceiptValidationResult> validateReceipt(
    PurchaseVerificationData verificationData,
  ) async {
    try {
      // 로그인 확인
      if (!_authService.isLoggedIn) {
        return ReceiptValidationResult(
          isValid: false,
          isActive: false,
          errorMessage: '로그인이 필요합니다',
        );
      }

      // 영수증 검증 요청
      final receiptRequest = SubscriptionReceiptRequest(
        receiptData: verificationData.serverVerificationData,
        platform: Platform.isIOS ? 'ios' : 'android',
        isTest: _isTestEnvironment,
      );

      // API 요청
      final response = await _authService.apiRequest(
        'POST',
        '/subscription/receipt/validate',
        body: receiptRequest.toJson(),
      );

      if (response.statusCode == 200) {
        final isValid = json.decode(response.body);

        // 검증 성공 시 기본 만료일 설정 (실제 서비스에서는 서버에서 반환해야 함)
        if (isValid == true) {
          return ReceiptValidationResult(
            isValid: true,
            isActive: true,
            productId: 'kdh.omninews.premium',
          );
        } else {
          return ReceiptValidationResult(
            isValid: false,
            isActive: false,
            errorMessage: '유효하지 않은 영수증',
          );
        }
      }

      print('영수증 검증 서버 오류: ${response.statusCode}');
      return ReceiptValidationResult(
        isValid: false,
        isActive: false,
        errorMessage: '서버 응답 오류: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('영수증 검증 중 오류: $e');
      return ReceiptValidationResult(
        isValid: false,
        isActive: false,
        errorMessage: '영수증 검증 중 오류: $e',
      );
    }
  }
}
