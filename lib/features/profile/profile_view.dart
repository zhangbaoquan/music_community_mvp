/// 个人中心页面 — 展示当前用户的信息、统计、勋章、音乐和文章
///
/// 使用 [ProfileController] 管理所有业务状态。
/// 子组件已拆分到 widgets/ 目录：
/// - [BadgesSection]：勋章展示区域
/// - [MusicGrid] / [MusicEmptyState]：音乐列表
/// - [ArticleListSection]：文章列表（含编辑/删除操作）
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../music/music_controller.dart';

import 'profile_controller.dart';
import 'edit_profile_dialog.dart';
import '../content/article_controller.dart';
import 'package:music_community_mvp/core/widgets/common_dialog.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';
import 'widgets/badges_section.dart';
import 'widgets/music_grid.dart';
import 'widgets/article_list_section.dart';
import '../../core/router/app_router.dart';

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
            // 页面标题
            Text(
              "个人信息",
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 40),

            // 用户卡片（头像 + 用户名 + 签名 + 编辑按钮）
            _buildUserCard(controller),
            const SizedBox(height: 24),

            // 统计面板
            _buildStatsPanel(controller),
            const SizedBox(height: 48),

            // 勋章区域（独立组件）
            const BadgesSection(),
            const SizedBox(height: 48),

            // 我的音乐
            _buildMyMusicSection(controller),
            const SizedBox(height: 48),

            // 我的文章
            _buildMyArticlesSection(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  /// 用户卡片（响应式布局 — 移动端纵向，桌面端横向）
  Widget _buildUserCard(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(controller),
                    const SizedBox(width: 16),
                    Expanded(child: _buildUserInfo(controller)),
                  ],
                ),
                const SizedBox(height: 24),
                // 移动端编辑按钮全宽
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (await controller.checkActionAllowed('编辑资料')) {
                        Get.dialog(const EditProfileDialog());
                      }
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("编辑资料"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(controller),
                const SizedBox(width: 24),
                Expanded(child: _buildUserInfo(controller)),
                const SizedBox(width: 16),
                _buildEditButton(controller),
              ],
            );
          }
        },
      ),
    );
  }

  /// 统计面板（关注/粉丝/访客 + 获赞/评论/收藏 + 日记/心情指数）
  Widget _buildStatsPanel(ProfileController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              // 社交数据
              InkWell(
                onTap: () => appRouter.push(
                  '/follows/${Supabase.instance.client.auth.currentUser!.id}/following',
                ),
                child: _buildStatItem("关注",
                    "${controller.followingCount.value}",
                    icon: Icons.person_add_alt_1_outlined),
              ),
              const SizedBox(width: 32),
              InkWell(
                onTap: () => appRouter.push(
                  '/follows/${Supabase.instance.client.auth.currentUser!.id}/followers',
                ),
                child: _buildStatItem("粉丝",
                    "${controller.followersCount.value}",
                    icon: Icons.group_outlined),
              ),
              const SizedBox(width: 32),
              InkWell(
                onTap: () => appRouter.push('/visitors'),
                child: _buildStatItem("访客",
                    "${controller.visitorsCount.value}",
                    isHighlight: true, icon: Icons.visibility_outlined),
              ),

              const SizedBox(width: 32),
              _buildVerticalDivider(),
              const SizedBox(width: 32),

              // 互动数据
              _buildStatItem("获赞",
                  "${controller.receivedLikesCount.value}",
                  icon: Icons.thumb_up_alt_outlined),
              const SizedBox(width: 32),
              _buildStatItem("评论",
                  "${controller.receivedCommentsCount.value}",
                  icon: Icons.comment_outlined),
              const SizedBox(width: 32),
              _buildStatItem("收藏",
                  "${controller.receivedCollectionsCount.value}",
                  icon: Icons.bookmark_border),

              const SizedBox(width: 32),
              _buildVerticalDivider(),
              const SizedBox(width: 32),

              // 个人数据
              _buildStatItem("日记", "${controller.diaryCount.value}",
                  icon: Icons.edit_note),
              const SizedBox(width: 32),
              _buildStatItem("心情", "${controller.moodIndex.value}",
                  icon: Icons.mood),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 我的音乐区域（使用共享 MusicGrid 组件）
  Widget _buildMyMusicSection(ProfileController controller) {
    final musicController = Get.put(MusicController());
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      musicController.fetchUserSongs(currentUser.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行（含上传按钮）
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
                  appRouter.push('/upload_music');
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
                    horizontal: 20, vertical: 12),
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
            return MusicEmptyState(
              message: "还没有上传过原创歌曲",
              actionLabel: "去发布第一首",
              onAction: () async {
                if (await controller.checkActionAllowed('上传音乐')) {
                  appRouter.push('/upload_music');
                }
              },
            );
          }
          return MusicGrid(
            songs: songs,
            showDeleteButton: true,
            onDelete: (song) async {
              if (!await controller.checkActionAllowed('删除音乐')) return;
              CommonDialog.show(
                title: "确认删除",
                content: "确定要删除这首歌曲吗？操作不可恢复。",
                confirmText: "删除",
                cancelText: "取消",
                isDestructive: true,
                onConfirm: () async {
                  appRouter.pop();
                  await musicController.deleteSong(song.id);
                },
                onCancel: () => appRouter.pop(),
              );
            },
          );
        }),
      ],
    );
  }

  /// 我的文章区域（使用共享 ArticleListSection 组件）
  Widget _buildMyArticlesSection() {
    final articleController = Get.put(ArticleController());
    final controller = Get.find<ProfileController>();
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      articleController.fetchUserArticles(currentUser.id);
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
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Tab 栏
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
                        color: Colors.black.withValues(alpha: 0.05),
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
                      child: Obx(() => Text(
                          "我发布的 (${articleController.userArticles.length})")),
                    ),
                    Tab(
                      child: Obx(() => Text(
                          "我收藏的 (${controller.collectedArticles.length})")),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Tab 内容
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    ArticleListSection(
                      articles: articleController.userArticles,
                      isMine: true,
                    ),
                    ArticleListSection(
                      articles: controller.collectedArticles,
                      isMine: false,
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

  // ============================================================
  // 私有辅助方法
  // ============================================================

  Widget _buildStatItem(String label, String value,
      {bool isHighlight = false, IconData? icon}) {
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

  Widget _buildAvatar(ProfileController controller) {
    return Obx(
      () => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          image: controller.avatarUrl.value.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(
                      controller.avatarUrl.value.toSecureUrl()),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: controller.avatarUrl.value.isEmpty
            ? const Icon(Icons.person, color: Colors.white, size: 40)
            : null,
      ),
    );
  }

  Widget _buildUserInfo(ProfileController controller) {
    return Column(
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
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: const Text("违规封禁中",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildEditButton(ProfileController controller) {
    return Container(
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
        icon: const Icon(Icons.edit, size: 14, color: Colors.black54),
        label: const Text("编辑资料",
            style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
