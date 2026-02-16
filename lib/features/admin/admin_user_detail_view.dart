import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/shim_google_fonts.dart';
import 'package:music_community_mvp/core/widgets/common_dialog.dart';
import 'admin_controller.dart'; // Import AdminController

class AdminUserDetailView extends StatefulWidget {
  final String userId;
  final String username;
  final String? email; // Add email
  final String? avatarUrl; // Add avatarUrl for header

  const AdminUserDetailView({
    super.key,
    required this.userId,
    required this.username,
    this.email,
    this.avatarUrl,
  });

  @override
  State<AdminUserDetailView> createState() => _AdminUserDetailViewState();
}

class _AdminUserDetailViewState extends State<AdminUserDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  final AdminController controller =
      Get.find<AdminController>(); // Get Controller

  // Data Lists
  final RxList<Map<String, dynamic>> articles = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> songs = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> diaries = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> comments = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    fetchData(0); // Fetch initial tab data
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      fetchData(_tabController.index);
    }
  }

  Future<void> fetchData(int tabIndex) async {
    isLoading.value = true;
    try {
      if (tabIndex == 0) {
        // Articles
        final res = await _supabase
            .from('articles')
            .select()
            .eq('user_id', widget.userId)
            .order('created_at', ascending: false);
        articles.value = List<Map<String, dynamic>>.from(res);
      } else if (tabIndex == 1) {
        // Music
        final res = await _supabase
            .from('songs')
            .select()
            .eq('uploader_id', widget.userId)
            .order('created_at', ascending: false);
        songs.value = List<Map<String, dynamic>>.from(res);
      } else if (tabIndex == 2) {
        // Diaries
        final res = await _supabase
            .from('mood_diaries')
            .select()
            .eq('user_id', widget.userId)
            .order('created_at', ascending: false);
        diaries.value = List<Map<String, dynamic>>.from(res);
      } else if (tabIndex == 3) {
        // Comments
        final res = await _supabase
            .from('article_comments')
            .select('*, articles(title)')
            .eq('user_id', widget.userId)
            .order('created_at', ascending: false);
        comments.value = List<Map<String, dynamic>>.from(res);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Generic delete helper
  Future<void> deleteItem(String table, String id, RxList list) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
      list.removeWhere((item) => item['id'] == id);
      Get.snackbar('Success', 'Item deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e');
    }
  }

  void _showResetPasswordDialog() {
    final passwordController = TextEditingController();
    CommonDialog.show(
      title: "重置用户密码",
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "⚠️ 您正在强制修改该用户的密码。\n修改成功后，请务必通知用户新密码，否则用户将无法登录。",
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: "输入新密码",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_reset),
            ),
          ),
        ],
      ),
      confirmText: "确认重置",
      cancelText: "取消",
      isDestructive: true,
      confirmColor: Colors.orange,
      onConfirm: () async {
        if (passwordController.text.trim().length < 6) {
          Get.snackbar('提示', '密码长度至少6位');
          return;
        }
        Get.back(); // Close dialog first
        await controller.resetUserPassword(
          widget.userId,
          passwordController.text.trim(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "用户详情",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User Profile Header
          _buildUserProfileHeader(),
          const Divider(height: 1),

          // 2. Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: "文章", icon: Icon(Icons.article)),
                Tab(text: "音乐", icon: Icon(Icons.music_note)),
                Tab(text: "日记", icon: Icon(Icons.book)),
                Tab(text: "评论", icon: Icon(Icons.comment)),
              ],
            ),
          ),

          // 3. Tab Views
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildArticleList(),
                  _buildMusicList(),
                  _buildDiaryList(),
                  _buildCommentList(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: widget.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 24),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.email != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        widget.email!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                SelectableText(
                  "ID: ${widget.userId}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              OutlinedButton.icon(
                onPressed: _showResetPasswordDialog,
                icon: const Icon(Icons.lock_reset, color: Colors.orange),
                label: const Text(
                  "重置密码",
                  style: TextStyle(color: Colors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
              const SizedBox(height: 8),
              // We could add Ban/Unban here too, but they are already in the list view.
              // For now, Reset Password is the key request.
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList() {
    if (articles.isEmpty) return const Center(child: Text("暂无文章"));
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final item = articles[index];
        return ListTile(
          title: Text(item['title'] ?? "No Title"),
          subtitle: Text(item['created_at']?.substring(0, 10) ?? "-"),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteItem('articles', item['id'], articles),
          ),
        );
      },
    );
  }

  Widget _buildMusicList() {
    if (songs.isEmpty) return const Center(child: Text("暂无音乐"));
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final item = songs[index];
        return ListTile(
          leading: item['cover_url'] != null
              ? Image.network(
                  item['cover_url'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.music_note),
          title: Text(item['title'] ?? "No Title"),
          subtitle: Text(item['artist'] ?? "Unknown Artist"),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteItem('songs', item['id'], songs),
          ),
        );
      },
    );
  }

  Widget _buildDiaryList() {
    if (diaries.isEmpty) return const Center(child: Text("暂无日记"));
    return ListView.builder(
      itemCount: diaries.length,
      itemBuilder: (context, index) {
        final item = diaries[index];
        return ListTile(
          title: Text(item['mood'] ?? "No Mood"),
          subtitle: Text(
            item['content'] ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteItem('mood_diaries', item['id'], diaries),
          ),
        );
      },
    );
  }

  Widget _buildCommentList() {
    if (comments.isEmpty) return const Center(child: Text("暂无评论"));
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final item = comments[index];
        final articleTitle = item['articles']?['title'] ?? "Unknown Article";
        return ListTile(
          title: Text(item['content'] ?? ""),
          subtitle: Text("评论于: $articleTitle"),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () =>
                deleteItem('article_comments', item['id'], comments),
          ),
        );
      },
    );
  }
}
