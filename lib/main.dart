import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'http://qinqinmusic.com:8000',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
  );

  runApp(const MusicCommunityApp());
}

class MusicCommunityApp extends StatelessWidget {
  const MusicCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject AuthController to listen to auth state and redirect
    Get.put(AuthController());

    return GetMaterialApp(
      title: '亲亲音乐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      // AuthController will redirect to Home or Login
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
