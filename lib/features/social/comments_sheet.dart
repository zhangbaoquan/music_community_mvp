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

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "音乐故事",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 200, // Show character count (e.g. 0/200)
                  onSubmitted: (_) {
                    if (!controller.isPosting.value) {
                      controller.postComment(textController.text);
                      textController.clear();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "写下这一刻的心情...",
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    counterStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => IconButton(
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF1A1A1A),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // List
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
                      Icon(Icons.edit_note, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "还没有故事，来写第一个吧~",
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: controller.comments.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return _buildCommentItem(comment);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _getColorRaw(comment.userNickname ?? "A"),
            radius: 18,
            child: Text(
              (comment.userNickname ?? "A")[0].toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userNickname ?? "匿名用户",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${comment.createdAt.year}-${comment.createdAt.month}-${comment.createdAt.day}",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: const Color(0xFF444444),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorRaw(String name) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }
}
