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

    // 1. Setup Listener for FUTURE changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _handleAuthRedirect(data.session);
    });

    // 2. Handle EXISTING state immediately
    // Supabase.initialize() has completed in main.dart, so currentSession is ready.
    final session = _supabase.auth.currentSession;
    _handleAuthRedirect(session);
  }

  Future<void> _handleAuthRedirect(Session? session) async {
    currentUser.value = session?.user;

    if (session != null) {
      // Logged in

      // Note: We no longer force logout here.
      // ProfileController will handle the "Restricted Mode" checkActionAllowed logic.

      // 1. Try Get.currentRoute first
      var targetRoute = Get.currentRoute;

      // 2. Fallback: Parse Uri.base if Get.currentRoute is '/' but browser has fragment
      if (targetRoute == '/' || targetRoute.isEmpty) {
        try {
          // Uri.base.fragment returns "article/xxx?..."
          final fragment = Uri.base.fragment;
          if (fragment.isNotEmpty && fragment != '/') {
            targetRoute = fragment.startsWith('/') ? fragment : '/$fragment';
          }
        } catch (_) {
          // Ignore parsing errors
        }
      }

      print('Auth Redirect: Logged In. Target: $targetRoute');

      // Prevent infinite loop if we are already on the target route?
      // GetX handles offAllNamed efficiently.

      if (targetRoute == '/' ||
          targetRoute == '/login' ||
          targetRoute.isEmpty) {
        // Default to home
        Get.offAllNamed('/home');
      } else {
        // Deep link detected (e.g. /chat/...), preserve it!
        Get.offAllNamed(targetRoute);
      }
    } else {
      // Logged out / Guest
      // Allow access to public routes. If at root, go to home.
      var targetRoute = Get.currentRoute;
      if (targetRoute == '/' || targetRoute.isEmpty) {
        Get.offAllNamed('/home');
      }
      // If on other routes (like /login, /article/...), stay there.
      // Protected routes should have their own guards or checks.
    }
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
