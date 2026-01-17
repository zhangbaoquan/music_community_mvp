import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:music_community_mvp/data/models/article_comment.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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
  bool _isThreadExpanded = false;
  bool _showEmojiPicker = false;

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
    // Thread view shows Root + Flattened Replies
    // 1. Flatten all descendants
    final List<ArticleComment> allReplies = [];
    void flatten(List<ArticleComment> list) {
      for (var c in list) {
        allReplies.add(c);
        flatten(c.replies);
      }
    }

    flatten(root.replies);

    // 2. Sort by CreatedAt (Ascending usually for comments? or Descending?
    // Usually chronological for chat-like view. Let's do Ascending so users follow conversation.)
    allReplies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 3. Handle Pagination (Collapse if > 5)
    final totalReplies = allReplies.length;
    final List<ArticleComment> displayedReplies;
    if (totalReplies > 5 && !_isThreadExpanded) {
      displayedReplies = allReplies.take(5).toList();
    } else {
      displayedReplies = allReplies;
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Root Comment
        _buildCommentItem(
          root,
          isRoot: true, // Treat as root for styling
          isThreadRoot: true,
          backgroundColor: const Color(0xFFFAFAFA),
          // In thread view, we don't need to show "X replies" tag on the root either
          // providing we see them below. But let's keep it for root as summary.
          // Actually user said "tab is unnecessary", possibly meaning the count on sub-items.
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
        // Empty State
        if (allReplies.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(
              child: Text('暂无回复', style: TextStyle(color: Colors.grey)),
            ),
          ),

        // Render Displayed Replies
        ...displayedReplies.map(
          (reply) => _buildCommentItem(
            reply,
            onTap: () {
              setState(() {
                _replyTo = reply;
              });
            },
            showReplies: false, // Flattened, so we don't recurse here
            isThreadRoot: false,
            // We can indent slightly to show it's a sub-comment, but not deeply
            indent: 20.0,
            hideReplyCountCallback:
                true, // Hide "X replies" tag in flattened list
          ),
        ),

        // "Show More" Button
        if (totalReplies > 5 && !_isThreadExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isThreadExpanded = true;
                  });
                },
                child: Text(
                  '展开更多回复 (${totalReplies - 5})',
                  style: TextStyle(color: Colors.blue[600], fontSize: 13),
                ),
              ),
            ),
          ),

        // "Collapse" Button (Optional, but good UX)
        if (totalReplies > 5 && _isThreadExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isThreadExpanded = false;
                  });
                },
                child: Text(
                  '收起回复',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputArea(
    ArticleController controller,
    ArticleComment? threadRoot,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + (_showEmojiPicker ? 0 : MediaQuery.of(context).padding.bottom),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                            : '回复 @${threadRoot!.userName ?? "楼主"}',
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
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
                        onTap: () {
                          // Hide emoji picker when typing
                          if (_showEmojiPicker) {
                            setState(() {
                              _showEmojiPicker = false;
                            });
                          }
                        },
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
                  const SizedBox(width: 8),

                  // Emoji Button
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus(); // Close keyboard
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Send Button
                  GestureDetector(
                    onTap: () async {
                      final content = _textController.text.trim();
                      if (content.isNotEmpty) {
                        // Determine parentId
                        String? finalParentId;
                        if (_replyTo != null) {
                          finalParentId = _replyTo!.id;
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
                            _showEmojiPicker = false; // Hide after send
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
        ),

        // Emoji Picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _textController.text = _textController.text + emoji.emoji;
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
              },
              config: const Config(),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentItem(
    ArticleComment comment, {
    VoidCallback? onTap,
    bool isRoot = false, // True if top-level in Full List
    bool isThreadRoot = false, // True if it is the main subject of Thread View
    bool showReplies =
        false, // If true, render children recursively (Deprecated in ThreadView, used in List?)
    Color? backgroundColor,
    double indent = 0.0,
    bool hideReplyCountCallback = false,
  }) {
    // Highlight check: if this comment is the one we are replying to
    final isReplyingToThis = _replyTo?.id == comment.id && _replyTo != null;
    final effectiveBgColor = isReplyingToThis
        ? Colors.blue.withValues(alpha: 0.05)
        : (backgroundColor ?? Colors.white);

    // Determine content widget
    Widget contentWidget;

    if (comment.replyToUserName != null && !isThreadRoot && !isRoot) {
      contentWidget = RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2A2A2A),
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: "回复 ${comment.replyToUserName}: ",
              style: TextStyle(color: Colors.blue[600]), // or Grey
            ),
            TextSpan(text: comment.content),
          ],
        ),
      );
    } else {
      contentWidget = Text(
        comment.content,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF2A2A2A),
          height: 1.4,
        ),
      );
    }

    return Column(
      key: ValueKey('${comment.id}_${comment.likesCount}_${comment.isLiked}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ).add(EdgeInsets.only(left: indent)), // Apply indent
            decoration: BoxDecoration(
              color: effectiveBgColor,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF8F8F8)),
              ),
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
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Like Button
                          GestureDetector(
                            onTap: () => Get.find<ArticleController>()
                                .toggleCommentLike(comment),
                            behavior:
                                HitTestBehavior.opaque, // Improve tap area
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                8,
                                0,
                                0,
                                4,
                              ), // Add some slop
                              child: Row(
                                children: [
                                  Icon(
                                    comment.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 14,
                                    color: comment.isLiked
                                        ? Colors.red
                                        : Colors.grey[400],
                                  ),
                                  if (comment.likesCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '${comment.likesCount}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: comment.isLiked
                                            ? Colors.red
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      contentWidget,

                      // "Replying to this..." Text REMOVED as per user feedback (arrow pointing to it was "incorrect")

                      // In Full List mode (isRoot=true), we show reply count summary
                      if (!isThreadRoot &&
                          !showReplies &&
                          !hideReplyCountCallback && // Hide if requested (e.g. in flattened view)
                          comment.totalRepliesCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${comment.totalRepliesCount} 条回复',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[600],
                            ),
                          ),
                        ),

                      if (onTap != null &&
                          !isRoot &&
                          !isThreadRoot &&
                          !showReplies)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '点击回复', // Changed text to be clearer
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recursive Replies Rendering (Only if showReplies is true, mostly for debugging or special views)
        if (showReplies && comment.replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 44.0 + indent),
            child: Column(
              children: comment.replies
                  .map(
                    (reply) => _buildCommentItem(
                      reply,
                      onTap: () {
                        setState(() {
                          _replyTo = reply;
                        });
                      },
                      showReplies: true,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
