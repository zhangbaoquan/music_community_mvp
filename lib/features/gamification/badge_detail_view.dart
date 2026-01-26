import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/gamification/badge_service.dart';
import 'package:music_community_mvp/features/gamification/premium_badge_widget.dart';

import '../../core/shim_google_fonts.dart';

class BadgeDetailView extends GetView<BadgeService> {
  const BadgeDetailView({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Better background
      appBar: AppBar(
        title: Text(
          '我的勋章墙',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Obx(() {
        final all = controller.allBadges;
        final earned = controller.earnedBadges;

        if (all.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final earnedCount = earned.length;
        final totalCount = all.length;
        final progress = totalCount > 0 ? earnedCount / totalCount : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Responsive logic:
            // < 600: 2 cols
            // 600 - 900: 3 cols
            // 900 - 1200: 4 cols
            // > 1200: 5 cols
            int crossAxisCount = 2;
            if (width > 600) crossAxisCount = 3;
            if (width > 900) crossAxisCount = 4;
            if (width > 1200) crossAxisCount = 5;

            // Center content max width
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      // 1. Stats Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2C3E50),
                              Color(0xFF4CA1AF),
                            ], // Elegant Gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CA1AF).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "已解锁勋章",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$earnedCount / $totalCount",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "继续创作，点亮更多荣誉！",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 2. Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8, // Adjusted ratio
                        ),
                        itemCount: all.length,
                        itemBuilder: (context, index) {
                          final badge = all[index];
                          final isOwned = earned.any((b) => b.id == badge.id);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: isOwned
                                  ? Border.all(
                                      color: Colors.amber.withOpacity(0.2),
                                      width: 1.5,
                                    )
                                  : Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Badge Icon (Visual)
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: PremiumBadgeWidget(
                                      badge: badge,
                                      size: 90,
                                      showLabel: false,
                                      isLocked: !isOwned,
                                    ),
                                  ),
                                ),

                                // Text Info
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          badge.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isOwned
                                                ? const Color(0xFF1A1A1A)
                                                : Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          badge.description,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: isOwned
                                                ? Colors.grey[600]
                                                : Colors.grey[400],
                                            height: 1.2,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (!isOwned)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.lock_outline,
                                                  size: 10,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "待解锁",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[500],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
