import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';

import '../player/player_bar.dart';
import '../player/player_controller.dart';
import '../auth/auth_controller.dart';
import '../notifications/notification_service.dart';
import '../profile/profile_controller.dart';
import '../sponsor/sponsor_dialog.dart';
import 'package:music_community_mvp/core/widgets/common_dialog.dart';
import '../messages/message_controller.dart';
import '../../core/router/app_router.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  MainLayout({super.key, required this.navigationShell});

  final PlayerController playerCtrl = Get.find<PlayerController>();
  final ProfileController profileCtrl = Get.put(ProfileController());
  final NotificationService notificationService = Get.put(
    NotificationService(),
  );

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // 如果已经在该 branch 上，再次点击时退回它的初始路由
      initialLocation: index == navigationShell.currentIndex,
    );
  }

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
                      onPressed: () => _goBranch(3),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () => _goBranch(4),
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
              ? Drawer(child: _buildSideNav(isDrawer: true, context: context))
              : null,
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (!isMobile) _buildSideNav(context: context),
                    Expanded(
                      child: navigationShell,
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

  Widget _buildSideNav({bool isDrawer = false, required BuildContext context}) {
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
                _goBranch(2);
              }
            },
          ),
          const Spacer(),
          Obx(() {
            if (profileCtrl.isAdmin.value) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _customNavItem(
                  icon: Icons.admin_panel_settings,
                  label: '后台管理',
                  isSelected: false,
                  onTap: () => context.push('/admin'),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          _customNavItem(
            icon: Icons.favorite_border,
            label: '赞助支持',
            isSelected: false,
            onTap: () => Get.dialog(const SponsorDialog()),
          ),
          _navItem(icon: Icons.info_outline, label: '关于与帮助', index: 5),
          Obx(() {
            final isGuest = !Get.find<AuthController>().isLoggedIn;
            return _customNavItem(
              icon: isGuest ? Icons.login : Icons.logout,
              label: isGuest ? '立即登录' : '退出登录',
              isSelected: false,
              onTap: () {
                if (isGuest) {
                  context.push('/login');
                } else {
                  CommonDialog.show(
                    title: "退出登录",
                    content: "确定要退出当前账号吗？",
                    confirmText: "确认退出",
                    cancelText: "取消",
                    isDestructive: true,
                    onConfirm: () {
                      appRouter.pop(); // Close dialog
                      if (Get.isRegistered<AuthController>()) {
                        Get.find<AuthController>().signOut();
                      }
                      context.go('/login');
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
    int currentIndex = 0;
    final pageIndex = navigationShell.currentIndex;

    if (pageIndex == 0) {
      currentIndex = 0;
    } else if (pageIndex == 1) {
      currentIndex = 1;
    } else if (pageIndex == 2) {
      currentIndex = 2;
    } else if (pageIndex == 4) {
      currentIndex = 3; 
    } else {
      currentIndex = 0;
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) async {
        if (index == 0) {
          _goBranch(0);
        } else if (index == 1) {
          _goBranch(1);
        } else if (index == 2) {
          if (!await profileCtrl.requireLogin()) return;
          _goBranch(2);
        } else if (index == 3) {
          if (!await profileCtrl.requireLogin()) return;
          _goBranch(4); 
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
        const BottomNavigationBarItem(icon: Icon(Icons.book), label: '日记'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
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
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    return _customNavItem(
      icon: icon,
      label: label,
      isSelected: isSelected,
      onTap: onTap ?? () => _goBranch(index),
    );
  }

  Widget _customNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
