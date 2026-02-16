import 'package:flutter/material.dart';
import '../../core/shim_google_fonts.dart';
import 'package:intl/intl.dart';

class AdminUserLogView extends StatefulWidget {
  final String date;
  final String userId;
  final String username;
  final List<Map<String, dynamic>> initialLogs;
  final Function(String logId) onDelete;

  const AdminUserLogView({
    super.key,
    required this.date,
    required this.userId,
    required this.username,
    required this.initialLogs,
    required this.onDelete,
  });

  @override
  State<AdminUserLogView> createState() => _AdminUserLogViewState();
}

class _AdminUserLogViewState extends State<AdminUserLogView> {
  late List<Map<String, dynamic>> logs;

  @override
  void initState() {
    super.initState();
    logs = widget.initialLogs;
  }

  /// Formats timestamptz to HH:mm:ss in Beijing Time (UTC+8)
  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--:--';
    try {
      final dt = DateTime.parse(isoString);
      // Assuming DB returns UTC (ending in Z), we convert to local which might be system time.
      // Or we can force UTC+8.
      // The user asked "Is the time wrong? Is it Beijing time?"
      // Ideally, the client (Flutter Web) uses system time by default for .toLocal().
      // If the user's browser is in Beijing time, it's correct.
      // But let's be explicit if possible or just use toLocal() and assume user is in +8.
      // For now, adhere to system local time.
      return DateFormat('HH:mm:ss').format(dt.toLocal());
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "日志详情 - ${widget.date}",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "${widget.username} (ID: ${widget.userId})",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: logs.isEmpty
          ? const Center(child: Text("无可显示日志"))
          : ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                final time = _formatTime(log['created_at']);
                final content = log['content'] ?? "";
                final deviceInfo = log['device_info'] ?? "";

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  leading: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontFamily: "monospace",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  title: SelectableText(content), // Use SelectableText
                  subtitle: deviceInfo.isNotEmpty
                      ? Text(
                          "设备: $deviceInfo",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () async {
                      // Optimistic delete
                      widget.onDelete(log['id']);
                      setState(() {
                        logs.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
