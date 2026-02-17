import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
import 'package:music_community_mvp/core/widgets/common_dialog.dart';

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                image: NetworkImage(controller.avatarUrl.value),
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
                          () => Row(
                            children: [
                              Expanded(
                                child: AutoSizeText(
                                  controller.username.value.isNotEmpty
                                      ? controller.username.value
                                      : '未设置昵称',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  minFontSize: 16,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (controller.isBanned) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: const Text(
                                    "违规封禁中",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                              fontStyle: controller.signature.value.isNotEmpty
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit Button (Now in flow, no overlap)
                  const SizedBox(width: 16),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextButton.icon(
                      onPressed: () async {
                        if (await controller.checkActionAllowed('编辑资料')) {
                          Get.dialog(const EditProfileDialog());
                        }
                      },
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Social & Stats Row (Clean Design - Single Line)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Social Graph
                      InkWell(
                        onTap: () => Get.toNamed(
                          '/follows/${Supabase.instance.client.auth.currentUser!.id}/following',
                        ),
                        child: _buildStatItem(
                          "关注",
                          "${controller.followingCount.value}",
                          icon: Icons.person_add_alt_1_outlined,
                        ),
                      ),
                      const SizedBox(width: 32),
                      InkWell(
                        onTap: () => Get.toNamed(
                          '/follows/${Supabase.instance.client.auth.currentUser!.id}/followers',
                        ),
                        child: _buildStatItem(
                          "粉丝",
                          "${controller.followersCount.value}",
                          icon: Icons.group_outlined,
                        ),
                      ),
                      const SizedBox(width: 32),
                      InkWell(
                        onTap: () => Get.toNamed('/visitors'),
                        child: _buildStatItem(
                          "访客",
                          "${controller.visitorsCount.value}",
                          isHighlight: true,
                          icon: Icons.visibility_outlined,
                        ),
                      ),

                      const SizedBox(width: 32),
                      _buildVerticalDivider(),
                      const SizedBox(width: 32),

                      // Received Stats
                      _buildStatItem(
                        "获赞",
                        "${controller.receivedLikesCount.value}",
                        icon: Icons.thumb_up_alt_outlined,
                      ),
                      const SizedBox(width: 32),
                      _buildStatItem(
                        "评论",
                        "${controller.receivedCommentsCount.value}",
                        icon: Icons.comment_outlined,
                      ),
                      const SizedBox(width: 32),
                      _buildStatItem(
                        "收藏",
                        "${controller.receivedCollectionsCount.value}",
                        icon: Icons.bookmark_border,
                      ),

                      const SizedBox(width: 32),
                      _buildVerticalDivider(),
                      const SizedBox(width: 32),

                      // Personal Stats
                      _buildStatItem(
                        "日记",
                        "${controller.diaryCount.value}",
                        icon: Icons.edit_note,
                      ),
                      const SizedBox(width: 32),
                      _buildStatItem(
                        "心情",
                        "${controller.moodIndex.value}",
                        icon: Icons.mood,
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
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
    final controller = Get.find<ProfileController>();
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      articleController.fetchUserArticles(currentUser.id);
      // collectedArticles are fetched in ProfileController.loadProfile
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "我的文章",
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 24),

        // DefaultTabController for Published / Collected
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF1A1A1A),
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Obx(
                        () => Text(
                          "我发布的 (${articleController.userArticles.length})",
                        ),
                      ),
                    ),
                    Tab(
                      child: Obx(
                        () => Text(
                          "我收藏的 (${controller.collectedArticles.length})",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 400, // Fixed height for tab view area
                child: TabBarView(
                  children: [
                    _buildArticleList(
                      articleController.userArticles,
                      isMine: true,
                      controller: controller,
                      articleController: articleController,
                    ),
                    _buildArticleList(
                      controller.collectedArticles,
                      isMine: false,
                      controller: controller,
                      articleController: articleController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArticleList(
    List<Article> articles, {
    required bool isMine,
    required ProfileController controller,
    required ArticleController articleController,
  }) {
    return Obx(() {
      if (articles.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMine ? Icons.article_outlined : Icons.bookmark_border,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                isMine ? "还没有发布过文章" : "还没有收藏文章",
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              if (isMine) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (await controller.checkActionAllowed('发布文章')) {
                      Get.toNamed('/editor');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("去写第一篇"),
                ),
              ],
            ],
          ),
        );
      }

      return ListView.separated(
        itemCount: articles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final article = articles[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    Get.toNamed('/article/${article.id}', arguments: article),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Cover Image
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                          image: article.coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(article.coverUrl!),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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

                            const SizedBox(height: 8),

                            // Bottom Row: Stats + Actions
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_border,
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
                                if (isMine) ...[
                                  _CompactActionButton(
                                    icon: Icons.edit,
                                    tooltip: "编辑",
                                    onTap: () async {
                                      if (await controller.checkActionAllowed(
                                        '编辑文章',
                                      )) {
                                        Get.toNamed(
                                          '/editor',
                                          arguments: article,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _CompactActionButton(
                                    icon: Icons.delete_outline,
                                    tooltip: "删除",
                                    color: Colors.red[300],
                                    onTap: () async {
                                      if (!await controller.checkActionAllowed(
                                        '删除文章',
                                      ))
                                        return;

                                      // Using Get.dialog or CommonDialog wrapper
                                      Get.dialog(
                                        AlertDialog(
                                          title: const Text("确认删除"),
                                          content: const Text(
                                            "确定要删除这篇文章吗？操作不可恢复。",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: const Text("取消"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final success =
                                                    await articleController
                                                        .deleteArticle(
                                                          article.id,
                                                        );
                                                if (success) {
                                                  Get.back();
                                                  Get.snackbar("删除成功", "文章已删除");
                                                }
                                              },
                                              child: const Text(
                                                "删除",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ] else ...[
                                  // For collected articles, show Author
                                  if (article.authorName != null)
                                    Text(
                                      "@${article.authorName}",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
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
    });
  }

  Widget _buildMyMusicSection() {
    // Ensure MusicController is available
    final musicController = Get.put(MusicController());
    final controller = Get.find<ProfileController>();
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
              onPressed: () async {
                if (await controller.checkActionAllowed('上传音乐')) {
                  Get.toNamed('/upload_music');
                }
              },
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
                    onPressed: () async {
                      if (await controller.checkActionAllowed('上传音乐')) {
                        Get.toNamed('/upload_music');
                      }
                    },
                    child: const Text("去发布第一首"),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 800) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 2;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio:
                      3.0, // Keeping it wide but slightly taller if needed
                ),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return Container(
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
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          // Play the song (existing functionality if any, otherwise maybe just show details?)
                          // Assuming we want to play it if tapped? Or maybe separate play button?
                          // The original code didn't have an onTap action on the container.
                          // Let's keep it simple or invoke play.
                          // Given the context "My Music", playing seems reasonable.
                          // checking if there was original onTap... looking at history...
                          // The previous snippet didn't show onTap logic for the container itself.
                          // I'll add a play button to be explicit.
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(
                            12,
                          ), // Reduced padding slightly
                          child: Row(
                            children: [
                              // Cover
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  image: song.coverUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(song.coverUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: song.coverUrl == null
                                    ? const Icon(
                                        Icons.music_note,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Info
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
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
                                  ],
                                ),
                              ),

                              // Play Button
                              IconButton(
                                onPressed: () {
                                  Get.find<PlayerController>().playSong(song);
                                },
                                icon: const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.blue,
                                ),
                                tooltip: "播放",
                              ),

                              // Delete Button
                              IconButton(
                                onPressed: () async {
                                  if (!await controller.checkActionAllowed(
                                    '删除音乐',
                                  ))
                                    return;

                                  CommonDialog.show(
                                    title: "确认删除",
                                    content: "确定要删除这首歌曲吗？操作不可恢复。",
                                    confirmText: "删除",
                                    cancelText: "取消",
                                    isDestructive: true,
                                    onConfirm: () async {
                                      Get.back(); // Close dialog
                                      await musicController.deleteSong(song.id);
                                    },
                                    onCancel: () => Get.back(),
                                  );
                                },
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red[300],
                                  size: 20,
                                ),
                                tooltip: "删除",
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
          );
        }),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    bool isHighlight = false,
    IconData? icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(height: 4),
        ],
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? const Color(0xFFFF9800)
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
