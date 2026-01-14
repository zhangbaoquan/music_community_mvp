import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:music_community_mvp/data/models/article.dart';

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
                          height: 1.5,
                        ),
                      ),
                    ),

                  if (widget.article.summary != null &&
                      widget.article.summary!.isNotEmpty)
                    const SizedBox(height: 32),

                  // Quill Content
                  QuillEditor(
                    controller: _quillController,
                    focusNode: FocusNode(),
                    scrollController: ScrollController(),
                    config: const QuillEditorConfig(
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
