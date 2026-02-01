import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/search/search_controller.dart'
    as s;
import 'package:timeago/timeago.dart' as timeago;

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView>
    with SingleTickerProviderStateMixin {
  final s.SearchController _controller = Get.put(s.SearchController());
  late TabController _tabController;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void onClose() {
    _tabController.dispose();
    _textCtrl.dispose();
    // Don't delete SearchController to keep state? Or maybe delete it.
    // Usually Get.put binds to lifecycle.
    super.dispose();
  }

  void _doSearch() {
    if (_textCtrl.text.isNotEmpty) {
      _controller.search(_textCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _textCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _doSearch(),
            decoration: InputDecoration(
              hintText: '搜索用户、日记、文章...',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _doSearch,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "综合"),
            Tab(text: "用户"),
            Tab(text: "日记"),
            Tab(text: "文章"),
          ],
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasResults =
            _controller.users.isNotEmpty ||
            _controller.diaries.isNotEmpty ||
            _controller.articles.isNotEmpty;

        if (!hasResults &&
            _textCtrl.text.isNotEmpty &&
            !_controller.isLoading.value) {
          // Only show empty state if we have searched
          // Ideally we need a flag 'hasSearched'
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildAllTab(),
            _buildUsersList(_controller.users),
            _buildDiariesList(_controller.diaries),
            _buildArticlesList(_controller.articles),
          ],
        );
      }),
    );
  }

  Widget _buildAllTab() {
    // A simple aggregated view: Top 3 users, Top 3 diaries, Top 3 articles
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_controller.users.isNotEmpty) ...[
          _buildSectionHeader("用户", 1),
          ..._controller.users.take(3).map((u) => _buildUserItem(u)),
          const Divider(),
        ],
        if (_controller.diaries.isNotEmpty) ...[
          _buildSectionHeader("日记", 2),
          ..._controller.diaries.take(3).map((d) => _buildDiaryItem(d)),
          const Divider(),
        ],
        if (_controller.articles.isNotEmpty) ...[
          _buildSectionHeader("文章", 3),
          ..._controller.articles.take(3).map((a) => _buildArticleItem(a)),
        ],
        if (_controller.users.isEmpty &&
            _controller.diaries.isEmpty &&
            _controller.articles.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 100),
              child: Text("暂无搜索结果", style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int tabIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          TextButton(
            onPressed: () => _tabController.animateTo(tabIndex),
            child: const Text("查看更多 >"),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return const Center(child: Text("无用户结果"));
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildUserItem(users[index]),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user['avatar_url'] != null && user['avatar_url'].isNotEmpty
            ? NetworkImage(user['avatar_url'])
            : null,
        child: user['avatar_url'] == null || user['avatar_url'].isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user['username'] ?? 'Unknown'),
      subtitle: Text(
        user['signature'] ?? '暂无签名',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => Get.toNamed('/profile/${user['id']}'),
    );
  }

  Widget _buildDiariesList(List<Map<String, dynamic>> diaries) {
    if (diaries.isEmpty) return const Center(child: Text("无日记结果"));
    return ListView.separated(
      itemCount: diaries.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildDiaryItem(diaries[index]),
    );
  }

  Widget _buildDiaryItem(Map<String, dynamic> diary) {
    final profile = diary['profiles'] ?? {};
    return ListTile(
      leading: const Icon(Icons.book, color: Colors.blueGrey),
      title: Text(
        diary['content'] ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "${profile['username'] ?? 'Unknown'} • ${timeago.format(DateTime.parse(diary['created_at']), locale: 'zh')}",
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () {
        // Navigate to user profile for now, or maybe a DiaryDetailView if we had one.
        // Or open a dialog showing full diary? Use Dialog closely matching MoodStation.
        Get.defaultDialog(
          title: "心情日记",
          content: Column(
            children: [
              Text(diary['content'] ?? ''),
              const SizedBox(height: 10),
              Text(
                "By ${profile['username']}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          textConfirm: "去主页",
          onConfirm: () {
            Get.back();
            Get.toNamed('/profile/${diary['user_id']}');
          },
          textCancel: "关闭",
        );
      },
    );
  }

  Widget _buildArticlesList(List<dynamic> articles) {
    if (articles.isEmpty) return const Center(child: Text("无文章结果"));
    return ListView.builder(
      itemCount: articles.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildArticleItem(articles[index]),
    );
  }

  Widget _buildArticleItem(dynamic article) {
    // article is Article object
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.toNamed('/article/${article.id}', arguments: article),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image - Larger size (100x75 approx 4:3)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: article.coverUrl != null
                    ? Image.network(
                        article.coverUrl!,
                        width: 100,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 75,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 75,
                        color: Colors.blueGrey[100],
                        child: const Icon(
                          Icons.article,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Summary
                    Text(
                      article.summary ?? '暂无摘要',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Footer: Author & Time
                    Row(
                      children: [
                        if (article.authorAvatar != null) ...[
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: NetworkImage(
                              article.authorAvatar!,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          article.authorName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "•  ${timeago.format(article.createdAt, locale: 'zh')}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
