import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../player/player_view.dart';
import '../diary/diary_view.dart';

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
                const Expanded(flex: 6, child: DiaryView()),
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
