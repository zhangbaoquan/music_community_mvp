import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import '../player/player_view.dart';
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
            ), // Reduced max width for centered content
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: const ContentTabView(),
          ),
        ),
      );
    }

    // Mobile Layout
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: ContentTabView(),
        ),
      ),
    );
  }
}

class ContentTabView extends StatelessWidget {
  const ContentTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "心情广场 (Moods)"),
                Tab(text: "专栏文章 (Articles)"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: TabBarView(
              children: [
                MoodStationView(), // Restored Mood Cards + Diary
                ArticleListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
