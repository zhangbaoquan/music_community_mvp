import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import 'admin_controller.dart';
import 'manage_music_view.dart';
import 'manage_articles_view.dart';
import 'manage_comments_view.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminController());

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
      body: Row(
        children: [
          // Sidebar (Desktop only, for mobile we could use Drawer but let's keep it simple for MVP)
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Obx(
              () => ListView(
                children: [
                  _buildNavItem(0, "音乐管理", Icons.music_note, controller),
                  _buildNavItem(1, "文章管理", Icons.article, controller),
                  _buildNavItem(2, "评论管理", Icons.comment, controller),
                  // _buildNavItem(3, "用户管理", Icons.people, controller),
                ],
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: Obx(() {
              switch (controller.currentTab.value) {
                case 0:
                  return const ManageMusicView();
                case 1:
                  return const ManageArticlesView();
                case 2:
                  return const ManageCommentsView();
                default:
                  return const Center(child: Text("Select a tab"));
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String title,
    IconData icon,
    AdminController controller,
  ) {
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
      selectedTileColor: Colors.white,
      onTap: () => controller.switchTab(index),
    );
  }
}
