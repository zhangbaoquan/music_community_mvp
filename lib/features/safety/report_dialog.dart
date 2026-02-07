import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'safety_service.dart';

class ReportDialog extends StatefulWidget {
  final String targetType; // 'article', 'comment', 'user', 'music', 'diary'
  final String targetId;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _selectedReason = 'spam';
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;

  final Map<String, String> _reasons = {
    'spam': '垃圾广告 (Spam)',
    'abuse': '辱骂攻击 (Abusive)',
    'prohibited': '违禁内容 (Prohibited)',
    'other': '其他原因 (Other)',
  };

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    final success = await Get.find<SafetyService>().reportContent(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _selectedReason,
      description: _descController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(); // Force close dialog using context
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '举报内容',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '请选择举报原因：',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  items: _reasons.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedReason = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '详细描述（选填）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('取消', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('提交举报'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
