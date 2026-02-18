import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import 'admin_controller.dart';
import 'manage_music_view.dart';
import 'manage_articles_view.dart';
import 'manage_comments_view.dart';

import 'manage_diaries_view.dart';
import 'manage_users_view.dart';
import 'manage_feedbacks_view.dart';
import 'manage_reports_view.dart';

class AdminLayout extends GetResponsiveView<AdminController> {
  AdminLayout({super.key});

  @override
  Widget builder() {
    // Ensure controller is registered
    if (!Get.isRegistered<AdminController>()) {
      Get.put(AdminController());
    }

    final bool isDesktop = screen.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "亲亲后台管理",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Get.offAllNamed('/home'),
            tooltip: "返回前台",
          ),
        ],
      ),
      // Mobile Drawer
      drawer: !isDesktop
          ? Drawer(child: _buildNavigationContent(isMobile: true))
          : null,
      body: Row(
        children: [
          // Desktop Sidebar
          if (isDesktop)
            Container(
              width: 200,
              color: Colors.grey[100],
              child: _buildNavigationContent(isMobile: false),
            ),

          // Content Area
          Expanded(
            child: Obx(() {
              // Ensure we have a valid int, default to 0
              switch (controller.currentTab.value) {
                case 0:
                  return const ManageMusicView();
                case 1:
                  return const ManageArticlesView();
                case 2:
                  return const ManageCommentsView();
                case 3:
                  return const ManageDiariesView();
                case 4:
                  return const ManageUsersView();
                case 5:
                  return const ManageFeedbacksView();
                case 6:
                  return const ManageReportsView();
                default:
                  return const ManageMusicView();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationContent({required bool isMobile}) {
    // Use Obx to rebuild when counts change
    return Obx(
      () => ListView(
        padding: EdgeInsets.zero, // Important for Drawer
        children: [
          if (isMobile)
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black87),
              child: Center(
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          _buildNavItem(0, "音乐管理", Icons.music_note, isMobile),
          _buildNavItem(1, "文章管理", Icons.article, isMobile),
          _buildNavItem(2, "评论管理", Icons.comment, isMobile),
          _buildNavItem(3, "日记管理", Icons.book, isMobile),
          _buildNavItem(4, "用户管理", Icons.people, isMobile),
          _buildNavItem(5, "反馈管理", Icons.feedback, isMobile),
          _buildNavItem(6, "举报管理", Icons.report_problem, isMobile),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, bool isMobile) {
    // controller is available via GetResponsiveView
    final isSelected = controller.currentTab.value == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.black87 : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black87 : Colors.grey[600],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.grey[200], // Visible selection style
      onTap: () {
        controller.switchTab(index);
        if (isMobile) {
          Get.back(); // Close Drawer
        }
      },
      trailing:
          (index == 5) // Feedback Tab Index
          ? (controller.unresolvedCount.value > 0
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                : null)
          : (index == 6) // Report Tab
          ? (controller.unresolvedReportsCount.value > 0
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                : null)
          : null,
    );
  }
}
