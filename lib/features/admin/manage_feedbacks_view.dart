import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:music_community_mvp/features/admin/admin_controller.dart';
import 'package:music_community_mvp/data/models/feedback_model.dart';
import 'feedback_detail_view.dart';

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
      onTap: () => Get.to(() => FeedbackDetailView(feedback: feedback)),
    );
  }
}
