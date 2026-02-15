import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class UpdatePasswordDialog extends StatefulWidget {
  const UpdatePasswordDialog({super.key});

  @override
  State<UpdatePasswordDialog> createState() => _UpdatePasswordDialogState();
}

class _UpdatePasswordDialogState extends State<UpdatePasswordDialog> {
  final _passwordCtrl = TextEditingController();
  final _authCtrl = Get.find<AuthController>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设置新密码',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '请输入您的新密码以完成重置。',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '新密码',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      final password = _passwordCtrl.text.trim();
                      if (password.length < 6) {
                        Get.snackbar('提示', '密码长度至少需6位');
                        return;
                      }

                      setState(() => _isLoading = true);
                      await _authCtrl.updateUserPassword(password);
                      // Dialog is closed by AuthController navigation usually,
                      // but let's ensure we don't double pop or get stuck.
                      // AuthController redirects to /home which clears dialogs.
                      if (mounted) setState(() => _isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('更新密码'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
