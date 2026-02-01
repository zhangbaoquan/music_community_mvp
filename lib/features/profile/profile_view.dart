import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../music/music_controller.dart';
import '../player/player_controller.dart';
import 'profile_controller.dart';
import 'edit_profile_dialog.dart';
import '../content/article_controller.dart';
import '../gamification/premium_badge_widget.dart';
import '../gamification/badge_service.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(40),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "个人信息",
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 40),

            // User Card
            // User Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Avatar Placeholder
                      Obx(
                        () => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            image: controller.avatarUrl.value.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      controller.avatarUrl.value,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: controller.avatarUrl.value.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => Text(
                                controller.username.value.isNotEmpty
                                    ? controller.username.value
                                    : '未设置昵称',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => Text(
                                controller.signature.value.isNotEmpty
                                    ? controller.signature.value
                                    : "还没有个性签名...",
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontStyle:
                                      controller.signature.value.isNotEmpty
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Edit Button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton.icon(
                        onPressed: () => Get.dialog(const EditProfileDialog()),
                        icon: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.black54,
                        ),
                        label: const Text(
                          "编辑资料",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Social & Stats Row (Clean Design)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                // borderRadius: BorderRadius.circular(16),
                // border: Border.all(color: Colors.grey[100]!),
              ),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () => Get.toNamed(
                        '/follows/${Supabase.instance.client.auth.currentUser!.id}/following',
                      ),
                      child: _buildStatItem(
                        "关注",
                        "${controller.followingCount.value}",
                      ),
                    ),
                    InkWell(
                      onTap: () => Get.toNamed(
                        '/follows/${Supabase.instance.client.auth.currentUser!.id}/followers',
                      ),
                      child: _buildStatItem(
                        "粉丝",
                        "${controller.followersCount.value}",
                      ),
                    ),
                    InkWell(
                      onTap: () => Get.toNamed('/visitors'),
                      child: _buildStatItem(
                        "访客",
                        "${controller.visitorsCount.value}",
                        isHighlight: true,
                      ),
                    ),
                    _buildVerticalDivider(),
                    _buildStatItem("日记", "${controller.diaryCount.value}"),
                    _buildStatItem("心情", "${controller.moodIndex.value}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Phase 14: My Badges (Gamification)
            _buildMyBadgesSection(controller),

            const SizedBox(height: 48),

            // Phase 4: My Original Music
            _buildMyMusicSection(),

            const SizedBox(height: 48),

            // Phase 5: My Articles
            _buildMyArticlesSection(),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMyArticlesSection() {
    final articleController = Get.put(ArticleController());
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      articleController.fetchUserArticles(currentUser.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final allArticles = articleController.userArticles;
          // Sort by likes descending
          final sortedArticles = List<Article>.from(allArticles)
            ..sort((a, b) => b.likesCount.compareTo(a.likesCount));

          // Take top 5
          final displayArticles = sortedArticles.take(5).toList();
          final totalCount = allArticles.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "我的文章 ($totalCount)",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Row(
                    children: [
                      if (totalCount > 5)
                        InkWell(
                          onTap: () => Get.toNamed('/user_articles'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "查看全部",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => Get.toNamed('/editor'),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text("写文章"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (displayArticles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "还没有发布过文章",
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Get.toNamed('/editor'),
                        child: const Text("去写第一篇"),
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent:
                            140, // Slightly taller for interaction stats
                      ),
                      itemCount: displayArticles.length,
                      itemBuilder: (context, index) {
                        final article = displayArticles[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Get.toNamed(
                                '/article/${article.id}',
                                arguments: article,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Cover Image
                                    Container(
                                      width: 90,
                                      height: 90,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                        image: article.coverUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  article.coverUrl!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: article.coverUrl == null
                                          ? Icon(
                                              Icons.article,
                                              color: Colors.grey[300],
                                              size: 32,
                                            )
                                          : null,
                                    ),

                                    // Content Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            article.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          if (article.summary != null &&
                                              article.summary!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              article.summary!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],

                                          const Spacer(),

                                          // Bottom Row: Likes/Comments + Date + Actions
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Interaction Stats
                                              Icon(
                                                Icons.thumb_up_alt_outlined,
                                                size: 14,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${article.likesCount}",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.comment_outlined,
                                                size: 14,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${article.commentsCount}",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),

                                              const Spacer(),

                                              // Date
                                              Text(
                                                article.createdAt
                                                    .toString()
                                                    .split(' ')
                                                    .first,
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Actions
                                              _CompactActionButton(
                                                icon: Icons.edit,
                                                tooltip: "编辑",
                                                onTap: () => Get.toNamed(
                                                  '/editor',
                                                  arguments: article,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              _CompactActionButton(
                                                icon: Icons.delete_outline,
                                                tooltip: "删除",
                                                color: Colors.red[300],
                                                onTap: () {
                                                  Get.defaultDialog(
                                                    title: "确认删除",
                                                    titlePadding:
                                                        const EdgeInsets.only(
                                                          top: 24,
                                                        ),
                                                    contentPadding:
                                                        const EdgeInsets.all(
                                                          24,
                                                        ),
                                                    middleText:
                                                        "确定要删除这篇文章吗？操作不可恢复。",
                                                    textConfirm: "删除",
                                                    textCancel: "取消",
                                                    confirmTextColor:
                                                        Colors.white,
                                                    buttonColor: Colors.red,
                                                    onConfirm: () async {
                                                      final success =
                                                          await articleController
                                                              .deleteArticle(
                                                                article.id,
                                                              );
                                                      if (success) {
                                                        Get.back();
                                                        Get.snackbar(
                                                          "删除成功",
                                                          "文章已删除",
                                                          maxWidth: 400,
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildMyMusicSection() {
    // Ensure MusicController is available
    final musicController = Get.put(MusicController());
    // Trigger fetch for current user
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      musicController.fetchUserSongs(currentUser.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "我的音乐",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/upload_music'),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text("上传乐曲"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Obx(() {
          if (musicController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = musicController.rxUserSongs;
          if (songs.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[200]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "还没有上传过原创歌曲",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Get.toNamed('/upload_music'),
                    child: const Text("去发布第一首"),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Adjust for responsiveness?
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 2.5, // Wide card for song
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cover
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: song.coverUrl != null
                            ? DecorationImage(
                                image: NetworkImage(song.coverUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: song.coverUrl == null
                          ? const Icon(Icons.music_note, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist ?? "Unknown",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Mini Chips
                          if (song.moodTags != null &&
                              song.moodTags!.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: song.moodTags!
                                  .take(2)
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50], // Theme color
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.blue,
                        size: 36,
                      ),
                      onPressed: () {
                        Get.find<PlayerController>().playSong(song);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 24, width: 1, color: Colors.grey[200]);
  }

  Widget _buildMyBadgesSection(ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Obx(() {
          // Use BadgeService directly as ProfileController might not update real-time
          // Use Get.put to ensure it's initialized (fixes crash if controller hasn't loaded it yet)
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
              height: 110, // Adjusted height for badge card
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
                        size: 70, // Slightly smaller to fit in card
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

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _CompactActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6), // Dense padding
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 18, color: color ?? Colors.blueGrey[300]),
          ),
        ),
      ),
    );
  }
}
