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
  bool _obscurePassword = true;

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

                          if (_isLogin)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 0,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '忘记密码?',
                                    style: TextStyle(
                                      color: Color(
                                        0xFF6B4EFF,
                                      ), // Using brand color
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
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

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '找回密码',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '请输入您的注册邮箱，我们将向您发送重置密码的链接。',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: resetEmailCtrl,
                label: '邮箱地址',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final email = resetEmailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        Get.snackbar('提示', '请输入有效的邮箱地址');
                        return;
                      }
                      Get.back(); // Close dialog
                      _authCtrl.sendPasswordResetEmail(email);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('发送'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF0F2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        decoration:
            InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
                  suffixIcon: isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                )
                .applyDefaults(Theme.of(context).inputDecorationTheme)
                .copyWith(
                  contentPadding: const EdgeInsets.only(
                    top: 14,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                ),
        textAlignVertical: TextAlignVertical.center,
      ),
    );
  }
}
