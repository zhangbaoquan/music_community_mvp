import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../music/music_controller.dart';
import '../music/upload_music_view.dart';
import '../player/player_controller.dart';
import 'profile_controller.dart';
import 'edit_profile_dialog.dart';
import '../content/article_controller.dart';
import '../content/article_editor_view.dart';

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
                    child: IconButton(
                      onPressed: () => Get.dialog(const EditProfileDialog()),
                      icon: const Icon(Icons.edit_square, color: Colors.grey),
                      tooltip: "编辑资料",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _buildStatCard(
                      label: "日记篇数",
                      value: "${controller.diaryCount.value}",
                      icon: Icons.book,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    label: "听歌时长",
                    value: "128", // Mock data for now
                    icon: Icons.music_note,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildStatCard(
                    label: "心情指数",
                    value: "85", // Mock data
                    icon: Icons.favorite,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "我的文章",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const ArticleEditorView()),
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
        const SizedBox(height: 24),

        Obx(() {
          final articles = articleController.userArticles;
          if (articles.isEmpty) {
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
                    onPressed: () => Get.to(() => const ArticleEditorView()),
                    child: const Text("去写第一篇"),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final article = articles[index];
              return Container(
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover optional
                    if (article.coverUrl != null)
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(article.coverUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (article.summary != null &&
                              article.summary!.isNotEmpty)
                            Text(
                              article.summary!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                "发布于 ${article.createdAt.toString().split(' ').first}",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              // Actions
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.blueGrey,
                                ),
                                onPressed: () => Get.to(
                                  () => ArticleEditorView(article: article),
                                ),
                                tooltip: "编辑",
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: "确认删除",
                                    middleText: "确定要删除这篇文章吗？操作不可恢复。",
                                    textConfirm: "删除",
                                    textCancel: "取消",
                                    confirmTextColor: Colors.white,
                                    buttonColor: Colors.red,
                                    onConfirm: () async {
                                      final success = await articleController
                                          .deleteArticle(article.id);
                                      if (success) {
                                        Get.back(); // Close dialog
                                        Get.snackbar("删除成功", "文章已删除");
                                      }
                                    },
                                  );
                                },
                                tooltip: "删除",
                              ),
                            ],
                          ),
                        ],
                      ),
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
              "我的原创",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const UploadMusicView()),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text("上传歌曲"),
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
                    onPressed: () => Get.to(() => const UploadMusicView()),
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

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
