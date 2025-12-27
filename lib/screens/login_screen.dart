import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title
                  PixelCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: 64,
                          color: PixelColors.primary,
                        ),
                        const SizedBox(height: 16),
                        PixelText(
                          text: 'RUBIK MASTER',
                          style: PixelTextStyle.headline,
                          color: PixelColors.primary,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        PixelText(
                          text: 'ĐĂNG NHẬP ĐỂ THI ĐẤU',
                          style: PixelTextStyle.body,
                          color: PixelColors.textSecondary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email field
                  PixelCard(
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontFamily: 'VT323',
                        fontSize: 20,
                        color: PixelColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'EMAIL',
                        labelStyle: const TextStyle(
                          fontFamily: 'VT323',
                          fontSize: 18,
                          color: PixelColors.textSecondary,
                        ),
                        prefixIcon: const Icon(Icons.email, color: PixelColors.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  PixelCard(
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontFamily: 'VT323',
                        fontSize: 20,
                        color: PixelColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'MẬT KHẨU',
                        labelStyle: const TextStyle(
                          fontFamily: 'VT323',
                          fontSize: 18,
                          color: PixelColors.textSecondary,
                        ),
                        prefixIcon: const Icon(Icons.lock, color: PixelColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: PixelColors.primary,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  PixelButton(
                    text: _isLoading ? 'ĐANG XỬ LÝ...' : 'ĐĂNG NHẬP',
                    onPressed: _isLoading ? null : _login,
                    backgroundColor: PixelColors.primary,
                    isLarge: true,
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  PixelButton(
                    text: 'CHƯA CÓ TÀI KHOẢN? ĐĂNG KÝ',
                    onPressed: () => context.go('/register'),
                    backgroundColor: PixelColors.surface,
                    textColor: PixelColors.primary,
                    borderColor: PixelColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

