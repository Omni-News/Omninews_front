import 'package:flutter/material.dart';
import 'package:omninews_flutter/models/omninews_subscription.dart';

class SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onSubscribe;
  final bool isSelected;

  const SubscriptionCard({
    Key? key,
    required this.plan,
    required this.onSubscribe,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 구독 플랜 이름
                Text(
                  plan.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 베스트 값어치 배지 (연간 구독인 경우)
                if (plan.id.contains('yearly'))
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '베스트 값어치',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 8),

            // 가격 정보
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '₩${plan.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  TextSpan(
                    text: _getPricePeriod(plan.id),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            // 설명
            Text(
              plan.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),

            SizedBox(height: 16),

            // 포함된 기능 목록
            ...plan.features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                )
                .toList(),

            SizedBox(height: 16),

            // 구독 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubscribe,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: theme.primaryColor,
                ),
                child: Text(
                  '구독하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 8),

            // 무료 체험 관련 텍스트 제거됨

            // 구독 취소 안내
            Center(
              child: Text(
                '언제든지 취소 가능',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 가격 기간 텍스트 반환
  String _getPricePeriod(String productId) {
    if (productId.contains('monthly')) {
      return ' / 월';
    } else if (productId.contains('yearly')) {
      return ' / 년';
    }
    return '';
  }

  // _hasTrial 메서드 제거됨
}
