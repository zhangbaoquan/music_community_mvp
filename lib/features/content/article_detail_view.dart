import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'article_controller.dart';

import 'package:timeago/timeago.dart' as timeago;

class ArticleDetailView extends StatefulWidget {
  final Article article;

  const ArticleDetailView({super.key, required this.article});

  @override
  State<ArticleDetailView> createState() => _ArticleDetailViewState();
}

class _ArticleDetailViewState extends State<ArticleDetailView> {
  late QuillController _quillController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load content
    try {
      if (widget.article.content != null) {
        _quillController = QuillController(
          document: Document.fromJson(widget.article.content),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } else {
        _quillController = QuillController.basic();
      }
    } catch (e) {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sliver App Bar with Cover
          SliverAppBar(
            expandedHeight: widget.article.coverUrl != null ? 300 : 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: widget.article.coverUrl == null
                  ? Text(
                      widget.article.title,
                      style: const TextStyle(color: Colors.black),
                    )
                  : null, // If cover exists, show title in body instead for better visuals
              background: widget.article.coverUrl != null
                  ? Image.network(widget.article.coverUrl!, fit: BoxFit.cover)
                  : null,
            ),
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(
              color: widget.article.coverUrl != null
                  ? Colors.white
                  : Colors.black,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Block
                  Text(
                    widget.article.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: widget.article.authorAvatar != null
                            ? NetworkImage(widget.article.authorAvatar!)
                            : null,
                        child: widget.article.authorAvatar == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article.authorName ?? '未知作者',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '发布于 ${timeago.format(widget.article.createdAt, locale: 'zh')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Summary Quote
                  if (widget.article.summary != null &&
                      widget.article.summary!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.blueAccent, width: 4),
                        ),
                      ),
                      child: Text(
                        widget.article.summary!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  const Divider(height: 1), // Divider before content
                  // Quill Content
                  QuillEditor(
                    controller: _quillController,
                    focusNode: FocusNode(),
                    scrollController: ScrollController(),
                    config: const QuillEditorConfig(
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.only(top: 24), // Add padding here
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        child: SafeArea(
          child: Row(
            children: [
              // 1. Comment Input (Left, Expanded)
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        '写下你的想法...',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // 2. Action Buttons (Right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BottomActionBtn(
                    icon: widget.article.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: widget.article.likesCount.toString(),
                    isActive: widget.article.isLiked,
                    activeColor: Colors.red,
                    onTap: () async {
                      await Get.find<ArticleController>().toggleLike(
                        widget.article,
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 16), // Gap between buttons
                  _BottomActionBtn(
                    icon: widget.article.isCollected
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: widget.article.collectionsCount.toString(),
                    isActive: widget.article.isCollected,
                    activeColor: Colors.orange,
                    onTap: () async {
                      await Get.find<ArticleController>().toggleCollection(
                        widget.article,
                      );
                      setState(() {});
                    },
                  ),
                  // Future: Tip Button
                  // Future: Share Button
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _BottomActionBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? activeColor : Colors.grey[600],
            size: 24,
          ),
          if (label != '0') ...[
            // const SizedBox(height: 2), // Optional
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
