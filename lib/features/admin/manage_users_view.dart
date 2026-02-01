import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'admin_user_detail_view.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  final _supabase = Supabase.instance.client;
  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      // Fetch all profiles
      final response = await _supabase
          .from('profiles')
          .select()
          .order(
            'updated_at',
            ascending: false,
          ); // Use updated_at as proxy for activity

      users.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load users: $e');
    } finally {
      isLoading.value = false;
    }
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
                onPressed: fetchUsers,
                icon: const Icon(Icons.refresh),
                tooltip: "刷新列表",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (users.isEmpty) {
                return const Center(child: Text("暂无用户"));
              }

              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    showCheckboxColumn:
                        false, // Make row clickable without checkbox
                    columns: const [
                      DataColumn(label: Text("头像")),
                      DataColumn(label: Text("昵称")),
                      DataColumn(label: Text("签名")),
                      DataColumn(label: Text("最近活跃")),
                      DataColumn(label: Text("操作")),
                    ],
                    rows: users.map((user) {
                      final avatarUrl = user['avatar_url'] as String?;
                      final username = user['username'] ?? "Unknown";
                      final signature = user['signature'] ?? "-";
                      // updated_at is auto-managed by Supabase usually
                      final time =
                          DateTime.tryParse(user['updated_at'].toString()) ??
                          DateTime.now();

                      return DataRow(
                        onSelectChanged: (_) {
                          // Navigate to detail view
                          Get.to(
                            () => AdminUserDetailView(
                              userId: user['id'],
                              username: username,
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
                                  ? const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          DataCell(
                            Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                signature,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(timeago.format(time, locale: 'zh'))),
                          DataCell(
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
