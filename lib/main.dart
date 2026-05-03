import 'package:flutter/material.dart';
import 'package:universal_html/js.dart' as js;
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_quill/flutter_quill.dart'; 
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/core/app_scroll_behavior.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:go_router/go_router.dart';

import 'core/app_binding.dart'; 
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔑 关键：开启 go_router 命令式 API 的 URL 同步
  // 使 appRouter.push() 能正确更新浏览器地址栏
  GoRouter.optionURLReflectsImperativeAPIs = true;

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
    return GetMaterialApp.router(
      title: '亲亲心情笔记',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(), // Set global binding
      routeInformationProvider: appRouter.routeInformationProvider,
      routeInformationParser: appRouter.routeInformationParser,
      routerDelegate: appRouter.routerDelegate,
      backButtonDispatcher: appRouter.backButtonDispatcher,
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
    );
  }
}
