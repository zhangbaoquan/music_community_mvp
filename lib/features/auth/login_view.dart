import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _usernameCtrl = TextEditingController(); // Only for sign up

  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'QinQin Music',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Welcome back' : 'Create an account',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              if (!_isLogin) ...[
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'No account? Create one'
                      : 'Already have an account? Sign in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
