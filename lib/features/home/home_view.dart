import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_html/html.dart' as html;
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'mood_station_view.dart';
import '../content/article_list_view.dart';

class HomeView extends GetResponsiveView {
  HomeView({super.key});

  @override
  Widget builder() {
    // Desktop / Tablet Landscape Layout
    if (screen.width > 800) {
      return Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 800,
            ),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: const ContentTabView(),
          ),
        ),
      );
    }

    // Mobile Layout
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: ContentTabView(),
        ),
      ),
    );
  }
}

/// 首页内容 Tab（心情广场 / 专栏文章）
///
/// 使用手动 TabController 实现 Tab 切换与浏览器 URL 双向同步：
/// - 心情广场 → /#/home
/// - 专栏文章 → /#/home?tab=articles
class ContentTabView extends StatefulWidget {
  const ContentTabView({super.key});

  @override
  State<ContentTabView> createState() => _ContentTabViewState();
}

class _ContentTabViewState extends State<ContentTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 根据 URL query 参数设置初始 Tab
    final initialIndex = _getTabIndexFromUrl();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );

    // 监听 Tab 切换 → 同步 URL
    _tabController.addListener(_onTabChanged);
  }

  /// 从 URL 中读取 tab 参数，确定初始 Tab 索引
  int _getTabIndexFromUrl() {
    final hash = html.window.location.hash; // e.g. "#/home?tab=articles"
    if (hash.contains('tab=articles')) return 1;
    return 0;
  }

  /// Tab 切换时同步 URL 到浏览器历史栈
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      html.window.history.replaceState(null, '', '/#/home?tab=articles');
    } else {
      html.window.history.replaceState(null, '', '/#/home');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(28),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(24),
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "心情广场"),
              Tab(text: "专栏文章"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MoodStationView(),
              ArticleListView(),
            ],
          ),
        ),
      ],
    );
  }
}
