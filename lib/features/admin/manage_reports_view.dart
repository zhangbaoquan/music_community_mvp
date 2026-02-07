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

                    Color statusColor = Colors.orange;
                    if (status == 'resolved') statusColor = Colors.green;
                    if (status == 'dismissed') statusColor = Colors.grey;

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
                                    status.toUpperCase(),
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
                                  "Type: ${report['target_type'] ?? 'Unknown'}",
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
                              "Reason: ${report['reason']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (report['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("Desc: ${report['description']}"),
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
                                  "Reporter: ${reporter != null ? reporter['username'] : 'Unknown'}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                SelectableText(
                                  "Target ID: ${report['target_id']}",
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 12,
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
                                    child: const Text("忽略 (Dismiss)"),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () =>
                                        controller.updateReportStatus(
                                          report['id'],
                                          'resolved',
                                        ),
                                    child: const Text("已处理 (Resolve)"),
                                  ),
                                ],
                              ),
                            // Optional: Add buttons to View Content or Ban User
                            // For MVP, could just show ID or simple actions
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
}
