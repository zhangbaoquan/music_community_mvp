import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:music_community_mvp/features/auth/update_password_dialog.dart';

class AuthController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Observable user
  final Rx<User?> currentUser = Rx<User?>(null);

  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();

    // 1. Setup Listener for FUTURE changes
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        // Show update password dialog
        // Must delay slightly or ensure context is ready? Get.dialog works globally.
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.dialog(const UpdatePasswordDialog());
        });
      } else {
        _handleAuthRedirect(data.session);
      }
    });

    // 2. Handle EXISTING state immediately
    // Supabase.initialize() has completed in main.dart, so currentSession is ready.
    final session = _supabase.auth.currentSession;
    _handleAuthRedirect(session);
  }

  Future<void> _handleAuthRedirect(Session? session) async {
    currentUser.value = session?.user;

    // Use microtask to ensure GetX is ready for navigation
    Future.microtask(() {
      try {
        if (session != null) {
          // Logged in
          var targetRoute = Get.currentRoute;

          // Handle deep links logic
          if (targetRoute == '/' ||
              targetRoute.isEmpty ||
              targetRoute == '/login') {
            final fragment = Uri.base.fragment;
            if (fragment.isNotEmpty && fragment != '/') {
              targetRoute = fragment.startsWith('/') ? fragment : '/$fragment';
            }
          }

          if (targetRoute == '/' ||
              targetRoute == '/login' ||
              targetRoute.isEmpty) {
            if (Get.currentRoute != '/home') {
              Get.offAllNamed('/home');
            }
          } else {
            // Ensure route starts with /
            if (!targetRoute.startsWith('/')) {
              targetRoute = '/$targetRoute';
            }
            if (Get.currentRoute != targetRoute) {
              Get.offAllNamed(targetRoute);
            }
          }
        } else {
          // Logged out
          final current = Get.currentRoute;
          if (current == '/' || current == '/login' || current.isEmpty) {
            if (Get.currentRoute != '/home') {
              Get.offAllNamed('/home');
            }
          }
        }
      } catch (e) {
        print(
          'Navigation Redirect Error (Safe to ignore if app is usable): $e',
        );
      }
    });
  }

  // -------------------------
  // Password Reset Logic
  // -------------------------

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Default redirect to site URL or app deep link
      // For web, usually just the site root. Supabase appends #access_token=...&type=recovery
      await _supabase.auth.resetPasswordForEmail(
        email,
        // redirectTo: 'https://qinqinmusic.com/',
      );
      Get.snackbar(
        '邮件已发送',
        '请检查您的邮箱（含垃圾箱），点击链接重置密码',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } on AuthException catch (e) {
      Get.snackbar(
        '发送失败',
        e.message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '发生未知错误，请稍后重试',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Update User Password (after clicking the recovery link)
  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      Get.snackbar(
        '密码已更新',
        '您的密码已重置成功，请重新登录',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Determine what to do next? usually stay logged in or logout.
      // Supabase keeps you logged in after update.
      Get.offAllNamed('/home');
    } on AuthException catch (e) {
      Get.snackbar(
        '更新失败',
        e.message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Update password error: $e');
      Get.snackbar('错误', '更新失败: $e');
    }
  }

  // -------------------------
  // Auth Actions
  // -------------------------

  Future<void> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // Listener will handle redirection
    } on AuthException catch (e) {
      Get.snackbar(
        '登录失败',
        e.message.contains('Invalid login credentials') ? '账号或密码错误' : e.message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username}, // metadata for profiles table trigger
      );
      Get.snackbar(
        '成功',
        '账号已经创建! 请登录.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on AuthException catch (e) {
      Get.snackbar(
        '登录失败',
        e.message.contains('Invalid login credentials') ? '账号或密码错误' : e.message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
