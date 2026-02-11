import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController _authCtrl = Get.put(AuthController());
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 80, // Slightly smaller or same
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B4EFF).withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32), // Reduced spacing
                    // Main Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 32, // Reduced vertical padding
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '亲亲心情笔记',
                            style: GoogleFonts.outfit(
                              fontSize: 26, // Slightly smaller font
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isLogin ? '欢迎回来' : '开启音乐之旅',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 24), // Reduced spacing

                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _usernameCtrl,
                              label: '用户名称',
                              icon: Icons.person_rounded,
                            ),
                            const SizedBox(height: 16),
                          ],

                          _buildTextField(
                            controller: _emailCtrl,
                            label: '邮箱地址',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _passwordCtrl,
                            label: '密码',
                            icon: Icons.lock_rounded,
                            isPassword: true,
                          ),
                          const SizedBox(height: 24), // Reduced spacing

                          SizedBox(
                            width: double.infinity,
                            height: 48, // Slightly shorter button
                            child: ElevatedButton(
                              onPressed: () {
                                final email = _emailCtrl.text.trim();
                                final password = _passwordCtrl.text.trim();

                                if (_isLogin) {
                                  _authCtrl.signIn(email, password);
                                } else {
                                  final username = _usernameCtrl.text.trim();
                                  _authCtrl.signUp(email, password, username);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A1A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                shadowColor: Colors.transparent,
                              ),
                              child: Text(
                                _isLogin ? '登录' : '立即注册',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Switch Mode
                          GestureDetector(
                            onTap: () => setState(() => _isLogin = !_isLogin),
                            child: Text.rich(
                              TextSpan(
                                text: _isLogin ? '没有账号? ' : '已有账号? ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isLogin ? '创建一个' : '直接登录',
                                    style: const TextStyle(
                                      color: Color(0xFF6B4EFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          // Guest Text
                          GestureDetector(
                            onTap: () => Get.offAllNamed('/home'),
                            child: Text(
                              '先逛逛 (游客模式)',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 48, // Fixed height for input fields
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        decoration:
            InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  // Center vertically
                  isDense: true,
                  // alignLabelWithHint: true, // Not needed for single line
                )
                .applyDefaults(Theme.of(context).inputDecorationTheme)
                .copyWith(
                  // Override problematic default padding if any
                  contentPadding: const EdgeInsets.only(
                    top: 14,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                ),
        textAlignVertical:
            TextAlignVertical.center, // Crucial for centering icon and text
      ),
    );
  }
}
