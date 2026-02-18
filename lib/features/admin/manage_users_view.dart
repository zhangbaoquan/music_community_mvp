import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import '../../core/widgets/common_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'admin_user_detail_view.dart';
import 'admin_controller.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  final AdminController controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    // Only fetch if empty to avoid reloading when switching tabs back and forth too often,
    // or always fetch to ensure freshness. Let's stick to safe "always fetch" for admin panel.
    controller.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "用户管理",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: controller.fetchUsers,
                icon: const Icon(Icons.refresh),
                tooltip: "刷新列表",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingUsers.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.users.isEmpty) {
                return const Center(child: Text("暂无用户"));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Use 800 to match AdminLayout breakpoint, or lower for table data
                  if (constraints.maxWidth < 800) {
                    return _buildMobileList();
                  } else {
                    return _buildDesktopTable();
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(context).size.width > 800
              ? MediaQuery.of(context).size.width - 250
              : 800, // Min width for table
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text("头像")),
              DataColumn(label: Text("昵称")),
              DataColumn(label: Text("邮箱")),
              DataColumn(label: Text("状态")),
              DataColumn(label: Text("最近活跃")),
              DataColumn(label: Text("操作")),
            ],
            rows: controller.users.map((user) {
              return _buildDataRow(user);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: controller.users.length,
      itemBuilder: (context, index) {
        final user = controller.users[index];
        final avatarUrl = user['avatar_url'] as String?;
        final username = user['username'] ?? "Unknown";
        final email = user['email'] as String?;
        final time =
            DateTime.tryParse(user['updated_at'].toString()) ?? DateTime.now();
        final status = user['status'] ?? 'active';
        final isBanned = status == 'banned';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(isBanned),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (email != null)
                  Text(email, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  "活跃: ${timeago.format(time, locale: 'zh')}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: _buildActionMenu(user, username, isBanned),
            onTap: () {
              Get.to(
                () => AdminUserDetailView(
                  userId: user['id'],
                  username: username,
                  email: email,
                  avatarUrl: avatarUrl,
                ),
              );
            },
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> user) {
    final avatarUrl = user['avatar_url'] as String?;
    final username = user['username'] ?? "Unknown";
    final email = user['email'] as String?;
    final signature = user['signature'] ?? "-";
    final time =
        DateTime.tryParse(user['updated_at'].toString()) ?? DateTime.now();
    final status = user['status'] ?? 'active';
    final isBanned = status == 'banned';

    return DataRow(
      onSelectChanged: (_) {
        Get.to(
          () => AdminUserDetailView(
            userId: user['id'],
            username: username,
            email: email,
            avatarUrl: avatarUrl,
          ),
        );
      },
      cells: [
        DataCell(
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 20, color: Colors.grey)
                : null,
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                signature,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        DataCell(
          Text(email ?? "-", style: const TextStyle(color: Colors.grey)),
        ),
        DataCell(_buildStatusBadge(isBanned)),
        DataCell(Text(timeago.format(time, locale: 'zh'))),
        DataCell(_buildActionMenu(user, username, isBanned)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isBanned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isBanned ? Colors.red[100] : Colors.green[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isBanned ? "已封禁" : "正常",
        style: TextStyle(
          color: isBanned ? Colors.red : Colors.green,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionMenu(
    Map<String, dynamic> user,
    String username,
    bool isBanned,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'ban') {
          _showBanDialog(context, user['id'], username, controller);
        } else if (value == 'unban') {
          controller.unbanUser(user['id']);
        } else if (value == 'clear') {
          _showClearContentDialog(context, user['id'], username, controller);
        }
      },
      itemBuilder: (context) => [
        if (!isBanned)
          const PopupMenuItem(value: 'ban', child: Text('封禁用户'))
        else
          const PopupMenuItem(value: 'unban', child: Text('解封用户')),
        const PopupMenuItem(
          value: 'clear',
          child: Text('清空内容', style: TextStyle(color: Colors.red)),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  void _showBanDialog(
    BuildContext context,
    String userId,
    String username,
    AdminController controller,
  ) {
    CommonDialog.show(
      title: "封禁用户: $username",
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("1 天"),
            onTap: () => {Get.back(), controller.banUser(userId, 1)},
          ),
          ListTile(
            title: const Text("7 天"),
            onTap: () => {Get.back(), controller.banUser(userId, 7)},
          ),
          ListTile(
            title: const Text("1 个月"),
            onTap: () => {Get.back(), controller.banUser(userId, 30)},
          ),
          ListTile(
            title: const Text("永久封禁"),
            onTap: () => {Get.back(), controller.banUser(userId, 36500)},
          ),
        ],
      ),
      confirmText:
          "取消", // Only cancel button needed as actions are inside list tiles
      isDestructive: true,
      onConfirm: () => Get.back(),
    );
  }

  void _showClearContentDialog(
    BuildContext context,
    String userId,
    String username,
    AdminController controller,
  ) {
    CommonDialog.show(
      title: "⚠️ 危险操作",
      content: "确定要清空用户 [$username] 的所有内容吗？\n包括文章、评论、动态等。\n此操作不可恢复！",
      confirmText: "确认清空",
      cancelText: "取消",
      isDestructive: true,
      confirmColor: Colors.red,
      onConfirm: () {
        Get.back();
        controller.clearUserContent(userId);
      },
    );
  }
}
