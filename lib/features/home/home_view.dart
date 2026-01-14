import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../player/player_view.dart';
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
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Player
                const Expanded(
                  flex: 4,
                  child: SingleChildScrollView(child: PlayerView()),
                ),
                const SizedBox(width: 40),
                // Right Panel: Content Area (Tabs)
                const Expanded(flex: 6, child: ContentTabView()),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile Layout
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              PlayerView(),
              SizedBox(height: 32),
              SizedBox(
                height: 600, // Increased height for tabs
                child: ContentTabView(),
              ),
            ],
          ),
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
