// 구독 계획 모델
class SubscriptionPlan {
  final String id; // 스토어 제품 ID
  final String name; // 표시 이름 (예: '월간 프리미엄')
  final String description; // 설명

  // 가격 표시/계산 관련
  // - price: 숫자 값(rawPrice, 예: 2200.0)
  // - currencyCode: 통화 코드(예: 'KRW', 'USD')
  // - priceString: 스토어가 로컬라이즈해 준 표시 문자열(예: '₩2,200', '$1.99')
  final double price; // 가격(rawPrice)
  final String? currencyCode; // 통화 코드(옵션)
  final String? priceString; // 로컬라이즈된 가격 문자열(옵션)

  final int durationDays; // 기간 (일수)
  final List<String> features; // 제공 기능 목록

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.features,
    this.currencyCode,
    this.priceString,
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
