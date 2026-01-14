import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import '../player/player_view.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart'; // import fonts
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
            height: 56, // Slightly taller
            padding: const EdgeInsets.all(4), // Add padding for "pill" effect
            decoration: BoxDecoration(
              color:
                  Colors.grey[200], // Slightly darker background for contrast
              borderRadius: BorderRadius.circular(28),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Use black for active pill
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
              splashBorderRadius: BorderRadius.circular(
                24,
              ), // Fix sharp corners on ripple
              labelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
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
