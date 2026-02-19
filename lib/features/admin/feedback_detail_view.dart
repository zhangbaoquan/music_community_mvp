import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/feedback_model.dart';
import 'package:music_community_mvp/features/admin/admin_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';

class FeedbackDetailView extends StatelessWidget {
  final FeedbackModel feedback;

  const FeedbackDetailView({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final replyController = TextEditingController();
    final adminController = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("反馈详情"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                Text(
                  "用户: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                Text(
                  feedback.username ?? 'Unknown',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                if (feedback.userId != null) ...[
                  Expanded(
                    child: SelectableText(
                      "(${feedback.userId!})",
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (feedback.contact != null && feedback.contact!.isNotEmpty) ...[
              SelectableText(
                "联系方式: ${feedback.contact}",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              "反馈内容:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SelectableText(
                feedback.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),

            const SizedBox(height: 24),
            // Images
            if (feedback.images.isNotEmpty) ...[
              const Text(
                "相关图片:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: feedback.images
                      .map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () => _showImagePreview(context, url),
                            child: Hero(
                              tag: url,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url.toSecureUrl(),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Divider(),
            const SizedBox(height: 24),

            // Reply Section
            const Text(
              "管理员回复:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            if (feedback.status == 'resolved') ...[
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "已处理/已回复",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (feedback.replyContent != null &&
                        feedback.replyContent!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        feedback.replyContent!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: replyController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "输入回复内容 (用户将收到系统通知)",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (replyController.text.trim().isNotEmpty &&
                        feedback.userId != null) {
                      adminController.replyToFeedback(
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Hero(
            tag: url,
            child: InteractiveViewer(child: Image.network(url.toSecureUrl())),
          ),
        ),
      ),
      fullscreenDialog: true,
    );
  }
}
