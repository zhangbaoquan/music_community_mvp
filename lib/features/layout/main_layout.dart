import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/features/search/search_view.dart';
import 'package:music_community_mvp/features/messages/message_controller.dart';
import 'package:music_community_mvp/features/messages/message_center_view.dart';
import 'package:universal_html/html.dart' as html;
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
import 'package:music_community_mvp/core/widgets/common_dialog.dart';

/// 导航控制器 — 管理侧栏/底栏 Tab 切换，并双向同步浏览器 URL
///
/// Tab 索引与 URL 路径映射：
/// 0:心情驿站→/home, 1:心事角落→/diary, 2:个人中心→/profile,
/// 3:搜索发现→/search, 4:消息中心→/messages, 5:关于→/about
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  /// Tab 索引 → URL 路径映射
  static const Map<int, String> tabRoutes = {
    0: '/home',
    1: '/diary',
    2: '/profile',
    3: '/search',
    4: '/messages',
    5: '/about',
  };

  /// URL 路径 → Tab 索引反向映射
  static final Map<String, int> routeToTab = {
    for (var e in tabRoutes.entries) e.value: e.key,
  };

  @override
  void onInit() {
    super.onInit();
    // 根据当前 URL 设置初始 Tab（支持地址栏直达）
    _syncTabFromUrl();
  }

  /// 切换页面并同步 URL 到浏览器地址栏
  void changePage(int index) {
    if (selectedIndex.value == index) return;
    selectedIndex.value = index;
    _replaceUrlForTab(index);
  }

  /// 使用 replaceState 更新地址栏 URL（不创建浏览器历史条目）
  ///
  /// 为什么不用 pushState：Flutter Web 的 GetX 路由引擎会监听 popstate
  /// 事件做页面导航，与我们的手动 URL 管理冲突。使用 replaceState
  /// 只更新地址栏显示，不触发导航事件，避免双系统冲突。
  void _replaceUrlForTab(int index) {
    final path = tabRoutes[index] ?? '/home';
    html.window.history.replaceState(null, '', '/#$path');
  }

  /// 根据当前浏览器 URL 同步 Tab 索引（仅用于初始加载）
  void _syncTabFromUrl() {
    final hash = html.window.location.hash; // e.g. "#/diary"
    final path = hash.replaceFirst('#', '').split('?').first;
    final tab = routeToTab[path];
    if (tab != null) {
      selectedIndex.value = tab;
    }
  }

  /// 确保地址栏 URL 与当前 Tab 一致
  ///
  /// 场景：从 admin/article 等页面返回时，GetX 会恢复它内部记录的路由
  /// （如 /home），但 selectedIndex 可能在其他 Tab 上。调用此方法可以修正不一致。
  void syncUrlToCurrentTab() {
    _replaceUrlForTab(selectedIndex.value);
  }
}

class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final NavigationController navCtrl = Get.put(NavigationController());
  // Removed explicit authCtrl to avoid Get.find error on refresh if not yet initialized
  final PlayerController playerCtrl = Get.find<PlayerController>();
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
                        '亲亲心情笔记',
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
      width: 270,
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 40),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: isDrawer ? 48 : 52,
                    height: isDrawer ? 48 : 52,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '亲亲心情笔记',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                    overflow: TextOverflow.ellipsis,
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
                  CommonDialog.show(
                    title: "退出登录",
                    content: "确定要退出当前账号吗？",
                    confirmText: "确认退出",
                    cancelText: "取消",
                    isDestructive: true,
                    onConfirm: () {
                      Get.back(); // Close dialog
                      if (Get.isRegistered<AuthController>()) {
                        Get.find<AuthController>().signOut();
                      } else {
                        Get.offAllNamed('/login');
                      }
                      Get.snackbar('已退出', '您已安全退出登录');
                    },
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Obx(() {
      // Fix: Map global page index to BottomNav index to avoid OutOfBounds and mismatch
      // Pages: 0:Home, 1:Diary, 2:Profile, 3:Search, 4:Messages, 5:About
      // NavItems: 0:Home, 1:Diary, 2:Profile, 3:Messages
      int currentIndex = 0;
      final pageIndex = navCtrl.selectedIndex.value;

      if (pageIndex == 0) {
        currentIndex = 0;
      } else if (pageIndex == 1) {
        currentIndex = 1;
      } else if (pageIndex == 2) {
        currentIndex = 2;
      } else if (pageIndex == 4) {
        currentIndex = 3; // Map Page 4 to Item 3
      } else {
        // For Search (3) or About(5), they don't have a bottom tab.
        // We can default to 0 (Home) or keep the previous valid selection?
        // Defaulting to 0 is safest to avoid crash.
        currentIndex = 0;
      }

      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) async {
          if (index == 0) {
            navCtrl.changePage(0);
          } else if (index == 1) {
            navCtrl.changePage(1);
          } else if (index == 2) {
            if (!await profileCtrl.requireLogin()) return;
            navCtrl.changePage(2);
          } else if (index == 3) {
            if (!await profileCtrl.requireLogin()) return;
            navCtrl.changePage(4); // Map Item 3 to Page 4
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
      );
    });
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
              color: Colors.black.withValues(alpha: 0.05),
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
