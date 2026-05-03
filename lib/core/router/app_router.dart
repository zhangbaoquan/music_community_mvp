import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';

import '../../data/models/article.dart';
import '../../features/layout/main_layout.dart';
import '../../features/home/home_view.dart';
import '../../features/diary/diary_view.dart';
import '../../features/profile/profile_view.dart';
import '../../features/search/search_view.dart';
import '../../features/messages/message_center_view.dart';
import '../../features/about/about_view.dart';

import '../../features/auth/login_view.dart';
import '../../features/admin/admin_layout.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/profile/user_profile_view.dart';
import '../../features/content/article_detail_view.dart';
import '../../features/content/article_editor_view.dart';
import '../../features/messages/chat_detail_view.dart';
import '../../features/music/upload_music_view.dart';
import '../../features/content/user_articles_view.dart';
import '../../features/gamification/badge_detail_view.dart';
import '../../features/profile/visitor_list_view.dart';
import '../../features/profile/follow_list_view.dart';

/// 根级导航键 — go_router 与 GetX 共享此键，使 Get.dialog/snackbar 正常工作
/// 所有需要脱离 Shell 全屏展示的路由，必须指定 parentNavigatorKey 为此键
final GlobalKey<NavigatorState> _rootNavigatorKey = Get.key;

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routerNeglect: false,
  routes: [
    // ==================== Shell 路由 ====================
    // 嵌套路由：带底部/侧边导航栏的主布局
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeView(),
            ),
          ],
        ),
        // Branch 1: Diary
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/diary',
              builder: (context, state) => const DiaryView(),
            ),
          ],
        ),
        // Branch 2: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
        // Branch 3: Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchView(),
            ),
          ],
        ),
        // Branch 4: Messages
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/messages',
              builder: (context, state) => const MessageCenterView(),
            ),
          ],
        ),
        // Branch 5: About
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/about',
              builder: (context, state) => const AboutView(),
            ),
          ],
        ),
      ],
    ),

    // ==================== 根级路由 (Root Routes) ====================
    // 以下路由全部指定 parentNavigatorKey 为根导航器，
    // 确保它们在 Shell 之上全屏展示，URL 地址栏正确更新。

    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginView(),
    ),

    // Admin 路由，包含路由守卫
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AdminLayout(),
      redirect: (context, state) {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController());
        }
        final profileCtrl = Get.find<ProfileController>();
        if (profileCtrl.isAdmin.value == true) {
          return null; // 允许访问
        } else {
          return '/home'; // 拒绝访问
        }
      },
    ),

    GoRoute(
      path: '/profile/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => UserProfileView(
        userId: state.pathParameters['id']!,
      ),
    ),

    GoRoute(
      path: '/article/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final extra = state.extra;
        Article article;
        if (extra is Article) {
          article = extra;
        } else {
          article = Article.empty().copyWith(id: id);
        }

        // autoOpen 参数可以通过 queryParameters 获取
        final autoOpen = state.uri.queryParameters['autoOpen'] == 'true';

        return ArticleDetailView(
          article: article,
          autoOpenComments: autoOpen,
        );
      },
    ),

    GoRoute(
      path: '/chat/:userId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return ChatDetailView(
          partnerId: state.pathParameters['userId']!,
          partnerName: state.uri.queryParameters['name'] ?? 'Chat',
          partnerAvatar: state.uri.queryParameters['avatar'] ?? '',
        );
      },
    ),

    GoRoute(
      path: '/upload_music',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UploadMusicView(),
    ),

    GoRoute(
      path: '/editor',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final article = extra is Article ? extra : null;
        return ArticleEditorView(article: article);
      },
    ),

    GoRoute(
      path: '/user_articles',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UserArticlesView(),
    ),

    GoRoute(
      path: '/badges',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BadgeDetailView(),
    ),

    GoRoute(
      path: '/visitors',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VisitorListView(),
    ),

    GoRoute(
      path: '/follows/:userId/:type',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final type = state.pathParameters['type'] ?? 'followers';
        final title = type == 'followers' ? '粉丝列表' : '关注列表';
        return FollowListView(
          userId: state.pathParameters['userId']!,
          type: type,
          title: title,
        );
      },
    ),
  ],
);
