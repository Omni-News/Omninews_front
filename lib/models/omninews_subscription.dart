// lib/models/omninews_subscription.dart

// 구독 계획 모델
class SubscriptionPlan {
  final String id; // 스토어 제품 ID
  final String name; // 표시 이름 (예: '월간 프리미엄')
  final String description; // 설명
  final double price; // 가격
  final int durationDays; // 기간 (일수)
  final List<String> features; // 제공 기능 목록

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.features,
  });
}

// 구독 상태 모델
class SubscriptionStatus {
  final bool isActive; // 구독 활성화 여부
  final DateTime? expiryDate; // 구독 만료일 (있는 경우)
  final String? productId; // 구독 상품 ID (있는 경우)

  SubscriptionStatus({required this.isActive, this.expiryDate, this.productId});

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'expiry_date': expiryDate?.toIso8601String(),
      'product_id': productId,
    };
  }

  // JSON에서 생성
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isActive: json['is_active'] ?? false,
      productId: json['product_id'],
      expiryDate:
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'])
              : null,
    );
  }
}

// 구독 요청 모델 (DTO 대신 통합)
class SubscriptionRequest {
  final String receiptData;
  final String platform;
  final bool isTest;

  SubscriptionRequest({
    required this.receiptData,
    required this.platform,
    required this.isTest,
  });

  Map<String, dynamic> toJson() {
    return {
      'receipt_data': receiptData,
      'platform': platform,
      'is_test': isTest,
    };
  }
}

// 영수증 검증 요청 모델 (DTO 대신 통합)
class SubscriptionReceiptRequest {
  final String receiptData;
  final String platform;
  final bool isTest;

  SubscriptionReceiptRequest({
    required this.receiptData,
    required this.platform,
    required this.isTest,
  });

  Map<String, dynamic> toJson() {
    return {
      'receipt_data': receiptData,
      'platform': platform,
      'is_test': isTest,
    };
  }
}

// 영수증 검증 결과 모델
class ReceiptValidationResult {
  final bool isValid;
  final bool isActive;
  final String? productId;
  final String? errorMessage;

  ReceiptValidationResult({
    required this.isValid,
    required this.isActive,
    this.productId,
    this.errorMessage,
  });
}
