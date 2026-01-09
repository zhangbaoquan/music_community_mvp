import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'comments_controller.dart';

class StoryEditorView extends StatefulWidget {
  const StoryEditorView({super.key});

  @override
  State<StoryEditorView> createState() => _StoryEditorViewState();
}

class _StoryEditorViewState extends State<StoryEditorView> {
  final CommentsController controller = Get.find<CommentsController>();
  final TextEditingController textController = TextEditingController();

  // FocusNode to handle keyboard immediately
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePost() {
    if (textController.text.trim().isNotEmpty) {
      controller.postComment(textController.text);
      Get.back(); // Close editor
      // Get.back(); // Optional: Close sheet too? Maybe keep sheet open to see result.
      // Actually CommentSheet is likely below this in stack or if we replaced it.
      // If we opened this via Get.to(), we return to previous.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Paper-like white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black54),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "撰写故事",
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: controller.isPosting.value ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 0,
                    ),
                  ),
                  child: controller.isPosting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("发布"),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Song Context (Subtle)
            // Ideally we show "Writing for: Song Name"
            // But controller might be generic. We can access PlayerController via View,
            // but let's keep it clean.
            const Divider(),
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: _focusNode,
                maxLines: null, // Unlimited lines
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  height: 1.8, // Comfortable line height for reading/writing
                  color: const Color(0xFF2A2A2A),
                ),
                decoration: InputDecoration(
                  hintText: "这里不仅是评论区，更是你的精神角落...\n\n支持分段，尽情书写关于这首曲子的记忆与想象。",
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.grey[300],
                    fontSize: 18,
                    height: 1.8,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
