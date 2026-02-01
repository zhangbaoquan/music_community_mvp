import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Observable user
  final Rx<User?> currentUser = Rx<User?>(null);

  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _supabase.auth.currentUser;

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      currentUser.value = session?.user;

      if (session != null) {
        // Logged in
        // Check current route to see if it's a deep link we should preserve
        final currentRoute = Get.currentRoute;
        print('Auth State Change: Logged In. Current Route: $currentRoute');

        if (currentRoute == '/' ||
            currentRoute == '/login' ||
            currentRoute.isEmpty) {
          // Default to home
          Get.offAllNamed('/home');
        } else {
          // Deep link detected (e.g. /chat/...), preserve it!
          // We must use offAllNamed to remove the AppStartupScreen
          // Be careful with parameters, GetX usually handles them if we pass the full string
          // Note: Get.currentRoute includes query params? Yes.
          Get.offAllNamed(currentRoute);
        }
      } else {
        // Logged out -> Go Login
        Get.offAllNamed('/login');
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // Listener will handle redirection
    } on AuthException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
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
        'Error',
        e.message,
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
