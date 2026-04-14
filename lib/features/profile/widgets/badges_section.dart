/// 勋章展示区域 — 个人中心"我的勋章"
///
/// 从 [ProfileView] 拆出的独立组件，
/// 水平滚动展示已获得的成就徽章。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/features/gamification/badge_service.dart';
import 'package:music_community_mvp/features/gamification/premium_badge_widget.dart';

/// 勋章展示区域
///
/// 调用 [BadgeService] 获取已获得的勋章列表，
/// 空状态时展示激励文案。
class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "我的勋章",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            InkWell(
              onTap: () => Get.toNamed('/badges'),
              child: Row(
                children: [
                  Text(
                    "查看全部",
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 勋章列表
        Obx(() {
          final badgeService = Get.put(BadgeService());
          final badges = badgeService.earnedBadges;

          if (badges.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  "继续创作，解锁你的第一枚勋章！",
                  style: GoogleFonts.outfit(color: Colors.grey[400]),
                ),
              ),
            );
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 24),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumBadgeWidget(
                        badge: badge,
                        size: 70,
                        showLabel: false,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.name,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
