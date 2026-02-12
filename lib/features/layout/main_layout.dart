import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/features/search/search_view.dart';
import 'package:music_community_mvp/features/messages/message_controller.dart';
import 'package:music_community_mvp/features/messages/message_center_view.dart';
import '../player/player_bar.dart';
import '../home/home_view.dart';
import '../player/player_controller.dart';
import '../diary/diary_view.dart';
import '../profile/profile_view.dart';
import '../auth/auth_controller.dart';
import '../notifications/notification_service.dart';
import '../profile/profile_controller.dart';
import '../about/about_view.dart';
import '../sponsor/sponsor_dialog.dart';

class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changePage(int index) {
    selectedIndex.value = index;
  }
}

class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController navCtrl = Get.put(NavigationController());
  // Removed explicit authCtrl to avoid Get.find error on refresh if not yet initialized
  final PlayerController playerCtrl = Get.put(PlayerController());
  final ProfileController profileCtrl = Get.put(ProfileController());
  final NotificationService notificationService = Get.put(
    NotificationService(),
  );

  final List<Widget> _pages = [
    // Tab 0: Home
    HomeView(),
    // Tab 1: Diary
    const DiaryView(),
    // Tab 2: Profile
    const ProfileView(),
    // Tab 3: Search
    const SearchView(),
    // Tab 4: Message Center (Merged)
    const MessageCenterView(),
    // Tab 5: About
    const AboutView(),
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
                      onPressed: () => navCtrl.changePage(3),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () => navCtrl.changePage(4),
                        ),
                        Obx(() {
                          final msgCtrl = Get.put(MessageController());
                          final msgCount = msgCtrl.unreadCount.value;
                          final notifCount =
                              notificationService.unreadCount.value;
                          final totalCount = msgCount + notifCount;

                          if (totalCount > 0) {
                            return Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 10,
                                  minHeight: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        }),
                      ],
                    ),
                  ],
                )
              : null,
          drawer: isMobile
              ? Drawer(child: _buildSideNav(isDrawer: true))
              : null,
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!isMobile) _buildSideNav(),
                    Expanded(
                      child: Obx(() => _pages[navCtrl.selectedIndex.value]),
                    ),
                  ],
                ),
              ),
              _buildPlayerBar(),
            ],
          ),
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
                if (isDrawer) const Spacer(),
              ],
            ),
          ),
          _navItem(icon: Icons.radio_button_checked, label: '心情驿站', index: 0),
          _navItem(icon: Icons.book, label: '心事角落', index: 1),
          _navItem(icon: Icons.search, label: '搜索发现', index: 3),
          Obx(() {
            final msgCtrl = Get.put(MessageController());
            final msgCount = msgCtrl.unreadCount.value;
            final notifCount = notificationService.unreadCount.value;
            final totalCount = msgCount + notifCount;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                _navItem(
                  icon: Icons.notifications_none,
                  label: '消息中心',
                  index: 4,
                ),
                if (totalCount > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          totalCount > 99 ? '99+' : '$totalCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          _navItem(
            icon: Icons.person,
            label: '个人中心',
            index: 2,
            onTap: () async {
              if (await profileCtrl.requireLogin()) {
                navCtrl.changePage(2);
              }
            },
          ),
          const Spacer(),
          Obx(() {
            if (profileCtrl.isAdmin.value) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _navItem(
                  icon: Icons.admin_panel_settings,
                  label: '后台管理',
                  index: 88,
                  onTap: () => Get.toNamed('/admin'),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          _navItem(
            icon: Icons.favorite_border,
            label: '赞助支持',
            index: 77,
            onTap: () => Get.dialog(const SponsorDialog()),
          ),
          _navItem(icon: Icons.info_outline, label: '关于与帮助', index: 5),
          Obx(() {
            final isGuest = !Get.find<AuthController>().isLoggedIn;
            return _navItem(
              icon: isGuest ? Icons.login : Icons.logout,
              label: isGuest ? '立即登录' : '退出登录',
              index: 99,
              onTap: () {
                if (isGuest) {
                  Get.toNamed('/login');
                } else {
                  if (Get.isRegistered<AuthController>()) {
                    Get.find<AuthController>().signOut();
                  } else {
                    Get.offAllNamed('/login');
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: navCtrl.selectedIndex.value,
        onTap: (index) async {
          // Intercept Profile (2) and Messages (3 in items list, but 3 is Messages?)
          // Items: 0:Home, 1:Diary, 2:Profile, 3:Messages
          // NavCtrl Indices: 0:Home, 1:Diary, 2:Profile, 3:Search(Hidden on mobile nav), 4:Messages
          // Wait, BottomNav items map to: 0->0, 1->1, 2->2, 3->4 (Messages)

          if (index == 2) {
            if (!await profileCtrl.requireLogin()) return;
            navCtrl.changePage(2);
          } else if (index == 3) {
            if (!await profileCtrl.requireLogin()) return;
            navCtrl.changePage(4); // Map 3(UI) to 4(Page)
          } else {
            navCtrl.changePage(index);
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A1A1A),
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_checked),
            label: '驿站',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '日记'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          BottomNavigationBarItem(
            icon: Obx(() {
              final msgCtrl = Get.put(MessageController());
              final msgCount = msgCtrl.unreadCount.value;
              final notifCount = notificationService.unreadCount.value;
              final totalCount = msgCount + notifCount;

              return Badge(
                isLabelVisible: totalCount > 0,
                label: Text('$totalCount'),
                child: const Icon(Icons.notifications_none),
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
        child: const PlayerBar(),
      );
    });
  }
}
