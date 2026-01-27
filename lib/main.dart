import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this
import 'package:flutter_quill/flutter_quill.dart'; // import for FlutterQuillLocalizations
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_controller.dart';

import 'package:timeago/timeago.dart' as timeago; // Import timeago

void main() {
  // Ensure binding, but DO NOT await async calls that Block startup
  WidgetsFlutterBinding.ensureInitialized();

  // Register Chinese messages for timeago
  timeago.setLocaleMessages('zh', timeago.ZhCnMessages());

  runApp(const MusicCommunityApp());
}

class MusicCommunityApp extends StatelessWidget {
  const MusicCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '亲亲音乐',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn, // Smooth fade transition
      transitionDuration: const Duration(milliseconds: 300), // 300ms duration
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
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
      home: const AppStartupScreen(),
    );
  }
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  String status = "正在启动引擎... (Initializing)";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => status = "正在连接云端... (Connecting)");

      // Initialize Supabase asynchronously
      await Supabase.initialize(
        url: 'http://qinqinmusic.com', // Use Port 80 (Nginx Proxy)
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
      );

      setState(() => status = "准备就绪 (Ready)");

      // Inject AuthController to handle navigation logic (Auto-login / Redirect)
      Get.put(AuthController());
    } catch (e) {
      setState(() => status = "初始化失败 (Error): $e");
    }
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
