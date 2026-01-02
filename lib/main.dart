import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/player/player_view.dart';
import 'features/diary/diary_view.dart';

void main() {
  runApp(const MusicCommunityApp());
}

class MusicCommunityApp extends StatelessWidget {
  const MusicCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mental Corner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: HomeView(),
    );
  }
}

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
                // Right Panel: Diary
                const Expanded(
                  flex: 6,
                  child: DiaryView(),
                ),
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
                height: 500, // Fixed height for diary on mobile
                child: DiaryView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
