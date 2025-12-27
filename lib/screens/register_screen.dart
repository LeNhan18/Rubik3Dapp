import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          ),
        );
        context.go('/login');
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
        child: Column(
          children: [
            PixelHeader(
              title: 'ĐĂNG KÝ',
              showBackButton: true,
              onBackPressed: () => context.go('/login'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PixelCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            PixelText(
                              text: 'TẠO TÀI KHOẢN MỚI',
                              style: PixelTextStyle.title,
                              color: PixelColors.primary,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Username field
                      PixelCard(
                        padding: EdgeInsets.zero,
                        child: TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(
                            fontFamily: 'VT323',
                            fontSize: 20,
                            color: PixelColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'TÊN NGƯỜI DÙNG',
                            labelStyle: const TextStyle(
                              fontFamily: 'VT323',
                              fontSize: 18,
                              color: PixelColors.textSecondary,
                            ),
                            prefixIcon: const Icon(Icons.person, color: PixelColors.primary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập tên người dùng';
                            }
                            if (value.length < 3) {
                              return 'Tên người dùng phải có ít nhất 3 ký tự';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Confirm password field
                      PixelCard(
                        padding: EdgeInsets.zero,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(
                            fontFamily: 'VT323',
                            fontSize: 20,
                            color: PixelColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'XÁC NHẬN MẬT KHẨU',
                            labelStyle: const TextStyle(
                              fontFamily: 'VT323',
                              fontSize: 18,
                              color: PixelColors.textSecondary,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline, color: PixelColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: PixelColors.primary,
                              ),
                              onPressed: () {
                                setState(() =>
                                    _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu không khớp';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register button
                      PixelButton(
                        text: _isLoading ? 'ĐANG XỬ LÝ...' : 'ĐĂNG KÝ',
                        onPressed: _isLoading ? null : _register,
                        backgroundColor: PixelColors.primary,
                        isLarge: true,
                      ),
                      const SizedBox(height: 16),

                      // Login link
                      PixelButton(
                        text: 'ĐÃ CÓ TÀI KHOẢN? ĐĂNG NHẬP',
                        onPressed: () => context.go('/login'),
                        backgroundColor: PixelColors.surface,
                        textColor: PixelColors.primary,
                        borderColor: PixelColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

