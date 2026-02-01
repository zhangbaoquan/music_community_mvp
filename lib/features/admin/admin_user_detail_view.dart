import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/shim_google_fonts.dart';

class AdminUserDetailView extends StatefulWidget {
  final String userId;
  final String username;

  const AdminUserDetailView({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AdminUserDetailView> createState() => _AdminUserDetailViewState();
}

class _AdminUserDetailViewState extends State<AdminUserDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.username} 的主页",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
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
      body: Obx(() {
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
