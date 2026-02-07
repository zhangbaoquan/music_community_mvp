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
      // 1. Check Ban Status
      try {
        final profile = await _supabase
            .from('profiles')
            .select('status, banned_until')
            .eq('id', session.user.id)
            .maybeSingle();

        if (profile != null) {
          final status = profile['status'] as String? ?? 'active';
          final bannedUntilStr = profile['banned_until'] as String?;

          if (status == 'banned') {
            DateTime? bannedUntil;
            if (bannedUntilStr != null) {
              bannedUntil = DateTime.tryParse(bannedUntilStr);
            }

            // Check if ban is still valid (Indefinite OR Future date)
            final isBanActive =
                bannedUntil == null || bannedUntil.isAfter(DateTime.now());

            if (isBanActive) {
              await signOut();
              Get.offAllNamed('/login');

              // Show Dialog
              String msg = "您的账号已被封禁";
              if (bannedUntil != null) {
                msg += "至 ${bannedUntil.toString().split('.').first}";
              } else {
                msg += " (永久)";
              }

              Get.dialog(
                AlertDialog(
                  title: const Text(
                    "账号封禁",
                    style: TextStyle(color: Colors.red),
                  ),
                  content: Text(msg),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("确定"),
                    ),
                  ],
                ),
              );
              return; // STOP HERE
            }
          }
        }
      } catch (e) {
        print("Ban check failed: $e");
        // Proceed cautiously or block? For MVP proceed, maybe network error.
      }

      // Logged in & Not Banned

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
        // However, if we were redirected from AdminGuard or similar, this might be tricky.
        // For simple MVP, this is fine.
        Get.offAllNamed(targetRoute);
      }
    } else {
      // Logged out -> Go Login
      Get.offAllNamed('/login');
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
