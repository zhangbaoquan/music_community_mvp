import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'comments_controller.dart';
import 'comment_model.dart';

class CommentsSheet extends StatelessWidget {
  const CommentsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommentsController());
    final textController = TextEditingController();

    // Check if we are in side panel mode (desktop)
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Container(
      height: isDesktop
          ? double.infinity
          : MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? null
            : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "音乐故事", // Music Stories
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          // List (Main Content)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.comments.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, size: 64, color: Colors.grey[200]),
                      const SizedBox(height: 16),
                      Text(
                        "还没有故事，来写第一个吧~",
                        style: GoogleFonts.outfit(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: controller.comments.length,
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return _buildCommentItem(comment, controller);
                },
              );
            }),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: textController,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 1000,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: const Color(0xFF1A1A1A),
                          ),
                          decoration: InputDecoration(
                            hintText: "写下这一刻的心情...",
                            hintStyle: GoogleFonts.outfit(
                              color: Colors.grey[500],
                            ),
                            border: InputBorder.none,
                            counterText: "",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Post Button
                    Obx(
                      () => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: CircleAvatar(
                          backgroundColor: controller.isPosting.value
                              ? Colors.grey[100]
                              : const Color(0xFF1A1A1A),
                          radius: 22,
                          child: IconButton(
                            onPressed: controller.isPosting.value
                                ? null
                                : () {
                                    controller.postComment(textController.text);
                                    textController.clear();
                                  },
                            icon: controller.isPosting.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.white,
                                  ),
                            iconSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // "Write Long Story" Trigger
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to Long Form Editor
                        Get.snackbar("敬请期待", "长篇故事编辑器正在装修中...");
                      },
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      label: Text(
                        "写长篇故事",
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, CommentsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: _getColorRaw(comment.userNickname ?? "A"),
            radius: 18,
            child: Text(
              (comment.userNickname ?? "A")[0].toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userNickname ?? "匿名用户",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Text
                Text(
                  comment.content,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: const Color(0xFF2A2A2A),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 12),

                // Interactions (Like / Collect)
                Row(
                  children: [
                    _buildInteractionBtn(
                      icon: comment.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: comment.likeCount > 0
                          ? "${comment.likeCount}"
                          : "赞",
                      color: comment.isLiked ? Colors.red : Colors.grey[400]!,
                      onTap: () => controller.toggleLike(comment.id),
                    ),
                    const SizedBox(width: 24),
                    _buildInteractionBtn(
                      icon: comment.isCollected
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label:
                          "收藏", // We don't show collection count usually, or we can. Let's just say "收藏" or "已收藏"
                      color: comment.isCollected
                          ? Colors.orange
                          : Colors.grey[400]!,
                      onTap: () => controller.toggleCollect(comment.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: color == Colors.red || color == Colors.orange
                  ? color
                  : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple logic: if today, show time; else show date
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "${date.month}月${date.day}日";
  }

  Color _getColorRaw(String name) {
    final colors = [
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFFEF5350), // Red
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF26A69A), // Teal
    ];
    return colors[name.hashCode % colors.length];
  }
}
