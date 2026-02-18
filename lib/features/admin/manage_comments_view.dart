import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import '../../core/widgets/common_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ManageCommentsView extends StatefulWidget {
  const ManageCommentsView({super.key});

  @override
  State<ManageCommentsView> createState() => _ManageCommentsViewState();
}

class _ManageCommentsViewState extends State<ManageCommentsView> {
  final _supabase = Supabase.instance.client;
  final RxList<Map<String, dynamic>> comments = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      isLoading.value = true;
      // Fetch latest 100 comments with author and article title
      final response = await _supabase
          .from('article_comments')
          .select('*, profiles(username, avatar_url), articles(title)')
          .order('created_at', ascending: false)
          .limit(100);

      comments.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load comments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase.from('article_comments').delete().eq('id', commentId);
      comments.removeWhere((c) => c['id'] == commentId);
      Get.snackbar('Success', 'Comment deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "评论管理 (最新100条)",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: fetchComments,
                icon: const Icon(Icons.refresh),
                tooltip: "刷新列表",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (comments.isEmpty) {
                return const Center(child: Text("暂无评论"));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return _buildMobileList();
                  } else {
                    return _buildDesktopTable();
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(Get.context!).size.width > 800
              ? MediaQuery.of(Get.context!).size.width - 250
              : 800,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text("用户")),
              DataColumn(label: Text("所属文章")),
              DataColumn(label: Text("内容")),
              DataColumn(label: Text("时间")),
              DataColumn(label: Text("操作")),
            ],
            rows: comments.map((comment) => _buildDataRow(comment)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final profile = comment['profiles'] as Map<String, dynamic>?;
        final article = comment['articles'] as Map<String, dynamic>?;
        final username = profile?['username'] ?? "Unknown";
        final avatarUrl = profile?['avatar_url'];
        final articleTitle = article?['title'] ?? "Unknown";
        final content = comment['content'] as String? ?? "";
        final time =
            DateTime.tryParse(comment['created_at'].toString()) ??
            DateTime.now();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "回复: $articleTitle",
                  style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                ),
                const SizedBox(height: 4),
                Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  timeago.format(time, locale: 'zh'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete(comment);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> comment) {
    final profile = comment['profiles'] as Map<String, dynamic>?;
    final article = comment['articles'] as Map<String, dynamic>?;
    final username = profile?['username'] ?? "Unknown";
    final articleTitle = article?['title'] ?? "Unknown";
    final content = comment['content'] as String? ?? "";
    final time =
        DateTime.tryParse(comment['created_at'].toString()) ?? DateTime.now();

    return DataRow(
      cells: [
        DataCell(
          Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(articleTitle, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          SizedBox(
            width: 300,
            child: Text(content, overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        ),
        DataCell(Text(timeago.format(time, locale: 'zh'))),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            tooltip: "删除",
            onPressed: () => _confirmDelete(comment),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(Map<String, dynamic> comment) {
    CommonDialog.show(
      title: "确认删除",
      content: "确定要删除这条评论吗？",
      confirmText: "删除",
      cancelText: "取消",
      isDestructive: true,
      onConfirm: () async {
        Get.back(); // close dialog
        await deleteComment(comment['id']);
      },
    );
  }
}
