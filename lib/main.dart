import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this
import 'package:flutter_quill/flutter_quill.dart'; // import for FlutterQuillLocalizations
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/core/app_scroll_behavior.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_controller.dart';

import 'package:timeago/timeago.dart' as timeago; // Import timeago

import 'features/layout/main_layout.dart';
import 'features/auth/login_view.dart';
import 'features/admin/admin_layout.dart';
import 'features/admin/admin_guard.dart';
import 'features/content/article_detail_view.dart';
import 'features/profile/user_profile_view.dart';
import 'features/messages/chat_detail_view.dart';
import 'features/music/upload_music_view.dart';
import 'features/content/user_articles_view.dart';
import 'features/content/article_editor_view.dart';
import 'features/gamification/badge_detail_view.dart';
import 'features/profile/visitor_list_view.dart';
import 'features/profile/follow_list_view.dart';
import 'data/models/article.dart'; // For Article model
import 'features/about/about_view.dart'; // About and Feedback Data
import 'features/safety/safety_service.dart';
import 'features/player/player_controller.dart'; // Import PlayerController

void main() async {
  // Ensure binding, but DO NOT await async calls that Block startup
  WidgetsFlutterBinding.ensureInitialized();

  // Register Chinese messages for timeago
  timeago.setLocaleMessages('zh', timeago.ZhCnMessages());

  // Global Error Widget for Release Mode debugging
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Text(
                'UI ERROR:\n${details.exception}\n\nSTACK:\n${details.stack}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  };

  // V14 Fix: Initialize Core Services BEFORE runApp
  // This prevents race conditions where Routes (like /home) load before Controllers are ready.
  try {
    // Initialize Supabase synchronously (well, awaited)
    await Supabase.initialize(
      url: 'http://qinqinmusic.com', // Use Port 80 (Nginx Proxy)
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
    );

    // Inject Core Controllers permanently
    Get.put(AuthController(), permanent: true);
    Get.put(SafetyService());
    Get.put(PlayerController(), permanent: true);
  } catch (e) {
    print("Critical Init Error: $e");
    // We can't do much here if Supabase fails, but the App will launch and probably show error UI later
  }

  runApp(const MusicCommunityApp());
}

class MusicCommunityApp extends StatelessWidget {
  const MusicCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '亲亲心情笔记',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn, // Smooth fade transition
      transitionDuration: const Duration(milliseconds: 300), // 300ms duration
      builder: (context, child) {
        return SelectionArea(child: child!);
      },
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(
            Colors.grey[400]!.withOpacity(0.6),
          ),
          radius: const Radius.circular(4),
          thickness: WidgetStateProperty.all(6),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
      ),
      scrollBehavior: AppScrollBehavior(),
      locale: const Locale('zh', 'CN'), // Enforce Chinese locale
      // Localizations are REQUIRED for flutter_quill to work in Release mode
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
      // Start with a dedicated Splash/Loading logic
      home: AppStartupScreen(),
      getPages: [
        GetPage(name: '/home', page: () => MainLayout()),
        GetPage(name: '/about', page: () => const AboutView()),
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(
          name: '/admin',
          page: () => AdminLayout(),
          middlewares: [AdminGuard()],
        ),
        // Named Routes for Core Pages
        GetPage(
          name: '/profile/:id',
          page: () => UserProfileView(userId: Get.parameters['id']!),
        ),
        GetPage(
          name: '/article/:id',
          page: () {
            final article = Get.arguments is Article
                ? Get.arguments as Article
                : Article.empty().copyWith(id: Get.parameters['id']);
            final autoOpen = Get.parameters['autoOpen'] == 'true';
            return ArticleDetailView(
              article: article,
              autoOpenComments: autoOpen,
            );
          },
        ),
        GetPage(
          name: '/chat/:userId',
          page: () => ChatDetailView(
            partnerId: Get.parameters['userId']!,
            partnerName: Get.parameters['name'] ?? 'Chat',
            partnerAvatar: Get.parameters['avatar'] ?? '',
          ),
        ),
        GetPage(name: '/upload_music', page: () => const UploadMusicView()),
        GetPage(
          name: '/editor',
          page: () => ArticleEditorView(article: Get.arguments as Article?),
        ),
        GetPage(name: '/user_articles', page: () => const UserArticlesView()),
        GetPage(name: '/badges', page: () => const BadgeDetailView()),
        GetPage(name: '/visitors', page: () => const VisitorListView()),
        GetPage(
          name: '/follows/:userId/:type',
          page: () {
            final type = Get.parameters['type'] ?? 'followers';
            final title = type == 'followers' ? '粉丝列表' : '关注列表';
            return FollowListView(
              userId: Get.parameters['userId']!,
              type: type,
              title: title,
            );
          },
        ),
      ],
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  String status = "正在连接云端... (Connecting)";

  @override
  void initState() {
    super.initState();
    // Use a slight delay to let the UI render once before routing
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAuthAndRedirect();
    });
  }

  void _checkAuthAndRedirect() {
    // Because we initialized AuthController in main(), it's safe to use here
    // final authCtrl = Get.find<AuthController>(); // Unused
    // Logic: If logged in? Or just go to home?
    // Current logic seems to imply we always go to /home or /login depending on requirement.
    // The previous implementation didn't strictly redirect, it just sat there?
    // Wait, the routing table has "/home".
    // Let's just forward to /home. MainLayout handles guest/user state.
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 64,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              status,
              style: GoogleFonts.outfit(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
