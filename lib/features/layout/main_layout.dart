import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/features/search/search_view.dart';
import '../player/player_bar.dart';
import '../home/home_view.dart';
import '../player/player_controller.dart';
import '../diary/diary_view.dart';
import '../profile/profile_view.dart';
import '../auth/auth_controller.dart';

import '../notifications/notification_service.dart';
import '../notifications/notification_view.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changePage(int index) {
    selectedIndex.value = index;
  }
}

class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController navCtrl = Get.put(NavigationController());
  final AuthController authCtrl = Get.find();
  final PlayerController playerCtrl = Get.put(PlayerController());
  final NotificationService notificationService = Get.put(
    NotificationService(),
  );

  final List<Widget> _pages = [
    // Tab 0: Home (Moods + Articles)
    HomeView(),

    // Tab 1: Mental Corner (Diary)
    const DiaryView(),

    // Tab 2: Profile
    const ProfileView(),

    // Tab 3: Notifications
    const NotificationView(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Scaffold(
          appBar: isMobile
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.black),
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '亲亲音乐',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => Get.to(() => const SearchView()),
                    ),
                  ],
                )
              : null,
          drawer: isMobile
              ? Drawer(child: _buildSideNav(isDrawer: true))
              : null, // Optional drawer for mobile
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Side Navigation (Desktop only)
                    if (!isMobile) _buildSideNav(),

                    // Page Content
                    Expanded(
                      child: Obx(() => _pages[navCtrl.selectedIndex.value]),
                    ),
                  ],
                ),
              ),

              // Persistent Player Bar
              _buildPlayerBar(),
            ],
          ),
          // Bottom Navigation (Mobile only)
          bottomNavigationBar: isMobile ? _buildBottomNav() : null,
        );
      },
    );
  }

  Widget _buildSideNav({bool isDrawer = false}) {
    return Container(
      width: 240,
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 40),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '亲亲音乐',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if (isDrawer) const Spacer(), // Close button for drawer?
              ],
            ),
          ),

          // Navigation Items
          _navItem(icon: Icons.radio_button_checked, label: '心情电台', index: 0),
          _navItem(icon: Icons.book, label: '心事角落', index: 1),
          // Search Entry
          _navItem(
            icon: Icons.search,
            label: '搜索发现',
            index: 90, // Special index
            onTap: () => Get.to(() => const SearchView()),
          ),
          _navItem(icon: Icons.person, label: '个人中心', index: 2),

          // Notification Item with Badge
          Obx(() {
            final unread = notificationService.unreadCount.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _navItem(icon: Icons.notifications, label: '通知消息', index: 3),
                if (unread > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            );
          }),

          const Spacer(),

          // Sign Out
          _navItem(
            icon: Icons.logout,
            label: '退出登录',
            index: 99,
            onTap: () => authCtrl.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: navCtrl.selectedIndex.value,
        onTap: (index) => navCtrl.changePage(index),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A1A1A),
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_checked),
            label: '电台',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.book), label: '日记'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          BottomNavigationBarItem(
            icon: Obx(() {
              final unread = notificationService.unreadCount.value;
              return Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications),
              );
            }),
            label: '消息',
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    return Obx(() {
      final isSelected = navCtrl.selectedIndex.value == index;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => navCtrl.changePage(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPlayerBar() {
    return Obx(() {
      if (playerCtrl.currentTitle.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        // Using the new compact PlayerBar widget here
        child: const PlayerBar(),
      );
    });
  }
}
