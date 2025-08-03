import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/subscription_provider.dart';

enum FeatureType {
  basic, // 모든 사용자 이용 가능
  premium, // 프리미엄 구독자만 이용 가능
}

class SubscriptionChecker {
  // 기능 접근 가능 여부 확인
  static bool canAccessFeature(BuildContext context, FeatureType featureType) {
    if (featureType == FeatureType.basic) {
      return true;
    }

    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final status = subscriptionProvider.status;

    return status.isActive;
  }

  // 프리미엄 기능 접근 위젯
  static Widget premiumFeatureWrapper({
    required BuildContext context,
    required Widget child,
    required Widget fallbackWidget,
    required FeatureType featureType,
  }) {
    if (canAccessFeature(context, featureType)) {
      return child;
    } else {
      return fallbackWidget;
    }
  }

  // 프리미엄 기능에 대한 알림 표시
  static Future<bool> showPremiumFeatureDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('프리미엄 기능'),
            content: Text('이 기능은 프리미엄 구독자만 이용할 수 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('구독 정보 보기'),
              ),
            ],
          ),
    );

    return result ?? false;
  }
}
