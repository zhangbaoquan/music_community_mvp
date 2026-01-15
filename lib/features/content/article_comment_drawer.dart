import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:music_community_mvp/data/models/article_comment.dart';
import 'article_controller.dart';

class ArticleCommentDrawer extends StatefulWidget {
  final String articleId;

  const ArticleCommentDrawer({super.key, required this.articleId});

  @override
  State<ArticleCommentDrawer> createState() => _ArticleCommentDrawerState();
}

class _ArticleCommentDrawerState extends State<ArticleCommentDrawer> {
  final TextEditingController _textController = TextEditingController();
  // We use the controller's selectedThread to determine view mode.
  // We also track a local reply target within the thread.
  ArticleComment? _replyTo;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ArticleController>();

    return Container(
      width: MediaQuery.of(context).size.width > 600
          ? 400
          : MediaQuery.of(context).size.width * 0.85,
      color: Colors.white,
      child: Obx(() {
        final threadRoot = controller.selectedThread.value;
        final isInThread = threadRoot != null;

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  if (isInThread)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () {
                        controller.selectedThread.value =
                            null; // Go back to list
                        setState(() => _replyTo = null);
                      },
                    ),
                  Text(
                    isInThread
                        ? "详情"
                        : "评论 (${controller.totalCommentsCount.value})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: isInThread
                  ? _buildThreadView(threadRoot)
                  : _buildFullListView(controller),
            ),

            // Input Area
            _buildInputArea(controller, threadRoot),
          ],
        );
      }),
    );
  }

  Widget _buildFullListView(ArticleController controller) {
    if (controller.isCommentsLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.currentComments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text("暂无评论，来坐沙发~", style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.currentComments.length,
      itemBuilder: (context, index) {
        final comment = controller.currentComments[index];
        // In Full List, we only show Root, and clicking it enters Thread Mode
        return _buildCommentItem(
          comment,
          onTap: () {
            controller.selectedThread.value = comment;
          },
        );
      },
    );
  }

  Widget _buildThreadView(ArticleComment root) {
    // Thread view shows Root + Replies
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Root Comment (highlighted?)
        Container(
          color: const Color(0xFFFAFAFA),
          child: _buildCommentItem(root, isRoot: true),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '回复列表',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        // Replies
        if (root.replies.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text('暂无回复', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ...root.replies.map(
          (reply) => _buildCommentItem(
            reply,
            onTap: () {
              // Reply to this reply
              setState(() {
                _replyTo = reply;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(
    ArticleController controller,
    ArticleComment? threadRoot,
  ) {
    return Container(
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
          // Reply Context
          if (_replyTo != null || (threadRoot != null && _replyTo == null))
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    _replyTo != null
                        ? '回复 @${_replyTo!.userName ?? "未知用户"}'
                        : '回复 @${threadRoot!.userName ?? "楼主"}', // Default to thread root if in thread mode
                    style: TextStyle(color: Colors.blue[600], fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // If in thread mode, cancelling reply just means clearing _replyTo,
                      // but we still implicitly reply to the thread (root).
                      // Actually, if _replyTo is null, parentId should match the threadRoot id?
                      // No, existing logic for replies is: parent_id = root.id.
                      // Wait, database schema allows arbitrary nesting, but UI is 2-level.
                      // Let's assume replies in a thread have parent_id = threadRoot.id
                      setState(() {
                        _replyTo = null;
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Input Row
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
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: "写下你的想法...",
                      border: InputBorder.none,
                      counterText: "",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final content = _textController.text.trim();
                  if (content.isNotEmpty) {
                    // Determine parentId
                    String? finalParentId;
                    if (_replyTo != null) {
                      finalParentId = _replyTo!.id;
                      // If checking nesting limit, we might want to ensure we don't nest too deep.
                      // For now, let's just allow nesting or map to root?
                      // User wanted "Sub-comments".
                      // If I rely on existing build logic `parentMap`, it works for any nesting.
                      // But visual layout was 2 levels.
                      // Let's use the explicit parent.
                    } else if (threadRoot != null) {
                      finalParentId = threadRoot.id;
                    }

                    final success = await controller.addComment(
                      widget.articleId,
                      content,
                      parentId: finalParentId,
                    );
                    if (success) {
                      _textController.clear();
                      setState(() {
                        _replyTo = null;
                        // Focus is kept on thread? Yes.
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    ArticleComment comment, {
    VoidCallback? onTap,
    bool isRoot = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: comment.userAvatar != null
                  ? NetworkImage(comment.userAvatar!)
                  : null,
              child: comment.userAvatar == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName ?? '未知用户',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(comment.createdAt, locale: 'zh'),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2A2A2A),
                      height: 1.4,
                    ),
                  ),
                  if (!isRoot && comment.replies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${comment.replies.length} 条回复',
                        style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                      ),
                    ),

                  if (onTap != null && !isRoot)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '点击查看详情',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
