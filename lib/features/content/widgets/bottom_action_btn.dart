/// 底部操作按钮 — 文章详情页底栏中的单个操作按钮
///
/// 用于点赞、收藏等操作，支持激活/未激活两种状态。
import 'package:flutter/material.dart';

/// 底部操作按钮组件
///
/// 包含图标和可选的数字标签，支持激活态颜色变化。
/// 当 [label] 为 '0' 时不显示数字标签。
class BottomActionBtn extends StatelessWidget {
  /// 按钮图标
  final IconData icon;

  /// 数字标签（如点赞数、收藏数）
  final String label;

  /// 是否处于激活状态（如已点赞、已收藏）
  final bool isActive;

  /// 激活状态的颜色
  final Color activeColor;

  /// 点击回调
  final VoidCallback onTap;

  const BottomActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? activeColor : Colors.grey[600],
            size: 24,
          ),
          // 数字为 0 时不显示标签
          if (label != '0') ...[
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
