import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LogService extends GetxService {
  final _supabase = Supabase.instance.client;

  /// Upload a log entry
  Future<bool> uploadLog({required String content, String? deviceInfo}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase.from('app_logs').insert({
        'user_id': user.id,
        'content': content,
        'device_info': deviceInfo,
      });
      return true;
    } catch (e) {
      print('DEBUG: LogService.uploadLog failed: $e');
      print(
        'DEBUG: Upload Params: content=$content, deviceInfo=$deviceInfo, userId=${user.id}',
      );
      // Show snackbar during debugging to help identify RLS issues
      Get.snackbar(
        'Log Error',
        'Failed to upload log: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return false;
    }
  }

  /// Fetch logs for a specific user
  Future<List<Map<String, dynamic>>> fetchUserLogs(String userId) async {
    try {
      final res = await _supabase
          .from('app_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error fetching user logs: $e');
      return [];
    }
  }

  /// Delete a log
  Future<bool> deleteLog(String logId) async {
    try {
      await _supabase.from('app_logs').delete().eq('id', logId);
      return true;
    } catch (e) {
      print('Error deleting log: $e');
      return false;
    }
  }
}
