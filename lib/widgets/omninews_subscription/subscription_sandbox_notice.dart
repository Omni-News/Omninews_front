import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class SubscriptionSandboxNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 디버그 모드 & iOS에서만 표시
    if (kDebugMode && Platform.isIOS) {
      return Card(
        color: Colors.amber.shade50,
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700]),
                  SizedBox(width: 8),
                  Text(
                    '샌드박스 테스트 정보',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '결제가 진행되지 않거나 오류가 발생하는 경우:\n'
                '1. 설정 앱으로 이동\n'
                '2. 앱스토어 항목 찾기\n'
                '3. 샌드박스 테스트 계정으로 로그인 확인\n'
                '4. 앱 완전히 종료 후 재시작',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox.shrink(); // 프로덕션 환경에서는 표시하지 않음
  }
}
