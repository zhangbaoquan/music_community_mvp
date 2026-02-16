import 'package:flutter/material.dart';
import 'admin_user_log_view.dart';

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
  final RxList<Map<String, dynamic>> logs =
      <Map<String, dynamic>>[].obs; // NEW: Logs

  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Length 5
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
      } else if (tabIndex == 4) {
        // Logs
        final res = await _supabase
            .from('app_logs')
            .select()
            .eq('user_id', widget.userId)
            .order('created_at', ascending: false);
        logs.value = List<Map<String, dynamic>>.from(res);
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

  // Delete all logs for a specific date
  Future<void> deleteLogsByDate(String date) async {
    try {
      // Filter logs locally to get IDs (or use date query if precise)
      // Since we store as timestamptz, querying by date string needs casting.
      // Easier to delete one by one or using 'in' filter with IDs we know match the date.
      final logsToDelete = logs.where((log) {
        final logDate = log['created_at']?.toString().split('T')[0];
        return logDate == date;
      }).toList();

      if (logsToDelete.isEmpty) return;

      final ids = logsToDelete.map((e) => e['id']).toList();

      await _supabase.from('app_logs').delete().filter('id', 'in', ids);

      logs.removeWhere((log) {
        final logDate = log['created_at']?.toString().split('T')[0];
        return logDate == date;
      });

      Get.snackbar('Success', 'Logs for $date deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete logs: $e');
    }
  }

  void _showResetPasswordDialog() {
    // ... existing implementation ...
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
                Tab(text: "日志", icon: Icon(Icons.bug_report)), // NEW Tab
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
                  _buildLogList(), // NEW View
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ... existing headers ...
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

  Widget _buildLogList() {
    if (logs.isEmpty) return const Center(child: Text("暂无日志"));

    // Group logs by Date (YYYY-MM-DD)
    final Map<String, List<Map<String, dynamic>>> groupedLogs = {};
    for (var log in logs) {
      final date = log['created_at']?.substring(0, 10) ?? "Unknown Date";
      if (!groupedLogs.containsKey(date)) {
        groupedLogs[date] = [];
      }
      groupedLogs[date]!.add(log);
    }

    final sortedDates = groupedLogs.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending dates

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dailyLogs = groupedLogs[date]!;

        return ListTile(
          title: Text(
            date,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text("${dailyLogs.length} 条日志记录"),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "删除该日所有日志",
            onPressed: () {
              CommonDialog.show(
                title: "确认删除",
                content: "确定要删除 $date 的所有日志吗？",
                isDestructive: true,
                onConfirm: () => deleteLogsByDate(date),
              );
            },
          ),
          onTap: () => _openDayLogs(date, dailyLogs),
        );
      },
    );
  }

  void _openDayLogs(String date, List<Map<String, dynamic>> dailyLogs) {
    Get.to(
      () => AdminUserLogView(
        date: date,
        userId: widget.userId,
        username: widget.username,
        initialLogs: dailyLogs, // Pass reference
        onDelete: (logId) {
          deleteItem('app_logs', logId, logs);
          // logs RxList update will trigger UI rebuild in parent
          // The child view maintains its own 'logs' list state for immediate UI feedback.
        },
      ),
    );
  }
}
