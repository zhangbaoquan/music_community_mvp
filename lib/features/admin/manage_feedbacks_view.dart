import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:music_community_mvp/features/admin/admin_controller.dart';
import 'package:music_community_mvp/data/models/feedback_model.dart';

class ManageFeedbacksView extends StatelessWidget {
  const ManageFeedbacksView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoadingFeedbacks.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.feedbacks.isEmpty) {
          return const Center(
            child: Text(
              "暂无反馈",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.feedbacks.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final feedback = controller.feedbacks[index];
            return _FeedbackItem(feedback: feedback);
          },
        );
      }),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  final FeedbackModel feedback;
  const _FeedbackItem({required this.feedback});

  @override
  Widget build(BuildContext context) {
    // Styling
    final isResolved = feedback.status == 'resolved';

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          if (feedback.userId != null) {
            // Ideally navigate to some profile view or dialog
            // Keeping it simple for admin dash
          }
        },
        child: CircleAvatar(
          backgroundImage:
              (feedback.avatarUrl != null && feedback.avatarUrl!.isNotEmpty)
              ? NetworkImage(feedback.avatarUrl!)
              : null,
          child: (feedback.avatarUrl == null || feedback.avatarUrl!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              feedback.username ?? '匿名用户',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isResolved ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isResolved ? '已回复' : '待处理',
              style: TextStyle(
                fontSize: 10,
                color: isResolved ? Colors.green[800] : Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            feedback.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87),
          ),
          if (feedback.contact != null && feedback.contact!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              "联系: ${feedback.contact}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            timeago.format(feedback.createdAt, locale: 'zh'),
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
      onTap: () => _openDetailDialog(context, feedback),
    );
  }

  void _openDetailDialog(BuildContext context, FeedbackModel feedback) {
    final replyController = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("反馈详情", style: Get.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              // User Info
              Row(
                children: [
                  Text(
                    "用户: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(feedback.username ?? 'Unknown'),
                  const SizedBox(width: 16),
                  if (feedback.userId != null) ...[
                    SelectableText(
                      feedback.userId!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (feedback.contact != null)
                SelectableText("联系方式: ${feedback.contact}"),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  feedback.content,
                  style: const TextStyle(fontSize: 15),
                ),
              ),

              const SizedBox(height: 16),
              // Images
              if (feedback.images.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: feedback.images
                        .map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => _showImagePreview(context, url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 16),
              const Text(
                "管理员回复:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (feedback.status == 'resolved') ...[
                const Text(
                  "✅ 已标记为已处理/已回复",
                  style: TextStyle(color: Colors.green),
                ),
                // Ideally we store the reply content too, but for MVP we might not have it in model
              ] else ...[
                TextField(
                  controller: replyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "输入回复内容 (用户将收到系统通知)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (replyController.text.trim().isNotEmpty &&
                          feedback.userId != null) {
                        Get.find<AdminController>().replyToFeedback(
                          feedback.id,
                          feedback.userId!,
                          replyController.text.trim(),
                        );
                      } else if (feedback.userId == null) {
                        Get.snackbar("Error", "Cannot reply to anonymous user");
                      } else {
                        Get.snackbar("Tip", "Please enter reply content");
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("发送回复并标记为已解决"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: Center(child: Image.network(url)),
        ),
      ),
    );
  }
}
