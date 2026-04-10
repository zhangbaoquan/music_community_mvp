import 'package:flutter/material.dart';
import 'package:universal_html/js.dart' as js;
import 'package:universal_html/html.dart' as html;
import 'package:music_community_mvp/features/layout/main_layout.dart';

import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this
import 'package:flutter_quill/flutter_quill.dart'; // import for FlutterQuillLocalizations
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/core/app_scroll_behavior.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
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
import 'core/app_binding.dart'; // Add this import
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  // Ensure binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase BEFORE runApp to ensure services are ready
  await Supabase.initialize(
    url: 'https://qinqinmusic.com',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
    headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    },
  );

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

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://example@o0.ingest.sentry.io/0'; // Placeholder DSN: USER MUST REPLACE
      options.tracesSampleRate = 1.0; // Capture 100% of the transactions for performance monitoring
    },
    appRunner: () => runApp(const MusicCommunityApp()),
  );
}

class MusicCommunityApp extends StatelessWidget {
  const MusicCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '亲亲心情笔记',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(), // Set global binding
      defaultTransition: Transition.fadeIn, // Smooth fade transition
      transitionDuration: const Duration(milliseconds: 300), // 300ms duration
      navigatorObservers: [
        SentryNavigatorObserver(), // Track routing telemetry
        UrlSyncObserver(), // Sync URL when returning to MainLayout
      ],
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (js.context.hasProperty('removeLoading')) {
               js.context.callMethod('removeLoading');
            }
          } catch (e) {
            // Ignore error on non-web platforms
          }
        });
        return child ?? const SizedBox.shrink();
      },
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(
            Colors.grey[400]!.withValues(alpha: 0.6),
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
        GetPage(name: '/diary', page: () => MainLayout()),
        GetPage(name: '/profile', page: () => MainLayout()),
        GetPage(name: '/search', page: () => MainLayout()),
        GetPage(name: '/messages', page: () => MainLayout()),
        GetPage(name: '/about', page: () => MainLayout()),
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Start initialization immediately
    _initServices();
  }

  Future<void> _initServices() async {
    // Services are now initialized in main() via AppBinding (synchronous Get.put).
    // No artificial delay needed — controllers are ready immediately.
    _checkAuthAndRedirect();
  }

  void _checkAuthAndRedirect() {
    // 尊重用户输入的 URL，如果是已注册的 Tab 路由则直接跳转
    final hash = html.window.location.hash.replaceFirst('#', '');
    final basePath = hash.split('?').first;
    // 检查是否是已注册的主 Tab 路由
    const validTabRoutes = ['/home', '/diary', '/profile', '/search', '/messages', '/about'];
    final targetRoute = validTabRoutes.contains(basePath) ? basePath : '/home';
    Get.offAllNamed(targetRoute);
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
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                size: 64,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            if (!_hasError) const CircularProgressIndicator(strokeWidth: 3),
            if (_hasError)
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 24),
            Text(
              status,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: _hasError ? Colors.red : Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_hasError) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    status = "正在重试...";
                  });
                  _initServices();
                },
                child: const Text("重试"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 路由观察器 — 当页面被 pop 时自动同步地址栏 URL
///
/// 解决的问题：从 admin/article 等页面返回 MainLayout 时，
/// GetX 恢复的 URL 是它内部记录的路由（如 /home），
/// 但 NavigationController 的 selectedIndex 可能在其他 Tab 上。
/// 此观察器在 pop 发生后的下一帧调用 syncUrlToCurrentTab() 修正。
class UrlSyncObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().syncUrlToCurrentTab();
      }
    });
  }
}
