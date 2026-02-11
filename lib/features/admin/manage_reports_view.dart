import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/admin/admin_controller.dart';
import 'package:timeago/timeago.dart' as timeago;

class ManageReportsView extends StatelessWidget {
  const ManageReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "举报管理",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingReports.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.reports.isEmpty) {
                  return const Center(child: Text("暂无举报记录"));
                }

                return ListView.separated(
                  itemCount: controller.reports.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final report = controller.reports[index];
                    final reporter = report['reporter'];
                    final status = report['status'] ?? 'pending';
                    final targetType = report['target_type'] ?? 'unknown';

                    Color statusColor = Colors.orange;
                    String statusText = "待处理";
                    if (status == 'resolved') {
                      statusColor = Colors.green;
                      statusText = "已处理";
                    }
                    if (status == 'dismissed') {
                      statusColor = Colors.grey;
                      statusText = "已忽略";
                    }

                    // Translate Reason
                    final reasonMap = {
                      'spam': '垃圾广告',
                      'abuse': '辱骂攻击',
                      'prohibited': '违禁内容',
                      'other': '其他原因',
                    };
                    final reasonText =
                        reasonMap[report['reason']] ?? report['reason'];

                    // Translate Type
                    final typeMap = {
                      'article': '文章',
                      'comment': '评论',
                      'user': '用户',
                      'music': '音乐',
                      'diary': '日记',
                    };
                    final typeText = typeMap[targetType] ?? targetType;

                    return Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    statusText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                  backgroundColor: statusColor,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "类型: $typeText",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeago.format(
                                    DateTime.parse(report['created_at']),
                                    locale: 'zh',
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "原因: $reasonText",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (report['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("描述: ${report['description']}"),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "举报人: ${reporter != null ? reporter['username'] : '未知'}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SelectableText(
                                    "目标ID: ${report['target_id']}",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (status == 'pending')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        controller.updateReportStatus(
                                          report['id'],
                                          'dismissed',
                                        ),
                                    child: const Text("忽略"),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () => _showProcessDialog(
                                      context,
                                      controller,
                                      report,
                                    ),
                                    child: const Text("处理"),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showProcessDialog(
    BuildContext context,
    AdminController controller,
    Map<String, dynamic> report,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text("处理举报"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("请选择处理方式："),
            const SizedBox(height: 16),
            if (report['target_type'] == 'article') ...[
              ListTile(
                leading: const Icon(Icons.visibility_off, color: Colors.orange),
                title: const Text('下架文章'),
                subtitle: const Text('仅作者可见，通知作者修改'),
                onTap: () {
                  Get.back(); // Close option dialog
                  _confirmAction(
                    controller,
                    report,
                    'hide',
                    '文章存在违规，需要重新修正',
                    '确认下架该文章吗？',
                  );
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('直接删除'),
              subtitle: const Text('删除内容，通知作者'),
              onTap: () {
                Get.back();
                _confirmAction(
                  controller,
                  report,
                  'delete',
                  '该${report['target_type'] == 'article' ? '文章' : '内容'}存在严重违规行为，系统直接删除，请知悉',
                  '确认删除该内容吗？此操作不可恢复。',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("取消")),
        ],
      ),
    );
  }

  void _confirmAction(
    AdminController controller,
    Map<String, dynamic> report,
    String action,
    String message,
    String confirmTitle,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text("确认操作"),
        content: Text(confirmTitle),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("取消")),
          TextButton(
            onPressed: () {
              Get.back(); // Close Confirm Dialog immediately
              controller.resolveReport(
                reportId: report['id'],
                action: action,
                targetType: report['target_type'],
                targetId: report['target_id'],
                message: message,
              );
            },
            child: const Text("确认", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
