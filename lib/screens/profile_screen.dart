import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/pixel_colors.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/pixel_header.dart';
import '../widgets/pixel_text.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId; // null = current user, otherwise = other user

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  User? _user;
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      User user;
      if (widget.userId == null) {
        // Load current user
        user = await _apiService.getCurrentUser();
        _isCurrentUser = true;
      } else {
        // Load other user (TODO: implement getUserById if needed)
        user = await _apiService.getCurrentUser(); // Temporary
        _isCurrentUser = false;
      }
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(int? milliseconds) {
    if (milliseconds == null) return 'Chưa có';
    final seconds = milliseconds / 1000;
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    final ms = (milliseconds % 1000) ~/ 10;
    if (minutes > 0) {
      return '${minutes}m ${secs}s ${ms.toString().padLeft(2, '0')}';
    }
    return '${secs}s ${ms.toString().padLeft(2, '0')}';
  }

  String _formatAverageTime(double? seconds) {
    if (seconds == null) return 'Chưa có';
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    if (minutes > 0) {
      return '${minutes}m ${secs.toStringAsFixed(1)}s';
    }
    return '${secs.toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: PixelColors.background,
        body: SafeArea(
          child: Column(
            children: [
              PixelHeader(
                title: 'HỒ SƠ',
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: PixelColors.background,
        body: SafeArea(
          child: Column(
            children: [
              PixelHeader(
                title: 'HỒ SƠ',
                showBackButton: true,
                onBackPressed: () => context.pop(),
              ),
              Expanded(
                child: Center(
                  child: PixelText(
                    text: 'KHÔNG TÌM THẤY NGƯỜI DÙNG',
                    style: PixelTextStyle.title,
                    color: PixelColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PixelColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PixelHeader(
              title: 'HỒ SƠ',
              showBackButton: true,
              onBackPressed: () => context.pop(),
              actions: [
                if (_isCurrentUser)
                  PixelButton(
                    text: '✎',
                    onPressed: () => _showEditProfileDialog(context),
                    backgroundColor: PixelColors.primaryDark,
                    width: 40,
                    height: 40,
                    borderWidth: 2,
                    shadowOffset: 2,
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Avatar and basic info
                    PixelCard(
                      backgroundColor: PixelColors.primary,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isCurrentUser ? () => _showImagePicker(context) : null,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: PixelColors.background,
                                border: Border.all(color: PixelColors.border, width: 3),
                                shape: BoxShape.circle,
                              ),
                              child: _user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _apiService.getAvatarUrl(_user!.avatarUrl),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: PixelText(
                                              text: _user!.username.substring(0, 1).toUpperCase(),
                                              style: PixelTextStyle.display,
                                              color: PixelColors.primary,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: PixelText(
                                        text: _user!.username.substring(0, 1).toUpperCase(),
                                        style: PixelTextStyle.display,
                                        color: PixelColors.primary,
                                      ),
                                    ),
                            ),
                          ),
                          if (_isCurrentUser)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: PixelText(
                                text: 'CHẠM ĐỂ ĐỔI ẢNH',
                                style: PixelTextStyle.caption,
                                color: PixelColors.background.withOpacity(0.8),
                              ),
                            ),
                          const SizedBox(height: 16),
                          PixelText(
                            text: _user!.username.toUpperCase(),
                            style: PixelTextStyle.headline,
                            color: PixelColors.background,
                          ),
                          const SizedBox(height: 4),
                          PixelText(
                            text: _user!.email.toUpperCase(),
                            style: PixelTextStyle.body,
                            color: PixelColors.background.withOpacity(0.9),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _user!.isOnline ? PixelColors.success : PixelColors.textLight,
                                  border: Border.all(color: PixelColors.border, width: 1),
                                ),
                              ),
                              const SizedBox(width: 6),
                              PixelText(
                                text: _user!.isOnline ? 'ĐANG ONLINE' : 'OFFLINE',
                                style: PixelTextStyle.caption,
                                color: PixelColors.background,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PixelText(
                            text: 'THỐNG KÊ',
                            style: PixelTextStyle.title,
                            color: PixelColors.primary,
                          ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Thắng',
                          _user!.totalWins.toString(),
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Thua',
                          _user!.totalLosses.toString(),
                          Icons.close,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Hòa',
                          _user!.totalDraws.toString(),
                          Icons.handshake,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thời gian',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    theme,
                    'Thời gian tốt nhất',
                    _formatTime(_user!.bestTime),
                    Icons.timer,
                  ),
                  _buildInfoRow(
                    theme,
                    'Thời gian trung bình',
                    _formatAverageTime(_user!.averageTime),
                    Icons.access_time,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Xếp hạng',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    theme,
                    'ELO Rating',
                    _user!.eloRating.toString(),
                    Icons.star,
                    Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thông tin khác',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    theme,
                    'Ngày tham gia',
                    _user!.createdAt.toString().substring(0, 10),
                    Icons.calendar_today,
                  ),
                  if (_user!.lastSeen != null)
                    _buildInfoRow(
                      theme,
                      'Hoạt động lần cuối',
                      _user!.lastSeen!.toString().substring(0, 16),
                      Icons.schedule,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
            ),
        ],
      ),
        ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return PixelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          PixelText(
            text: value,
            style: PixelTextStyle.headline,
            color: color,
          ),
          const SizedBox(height: 4),
          PixelText(
            text: label.toUpperCase(),
            style: PixelTextStyle.caption,
            color: PixelColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value, IconData icon, [Color? iconColor]) {
    return PixelCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? PixelColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: PixelText(
              text: label.toUpperCase(),
              style: PixelTextStyle.body,
            ),
          ),
          PixelText(
            text: value.toUpperCase(),
            style: PixelTextStyle.subtitle,
            color: PixelColors.primary,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final usernameController = TextEditingController(text: _user?.username ?? '');
    final emailController = TextEditingController(text: _user?.email ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(
        usernameController: usernameController,
        emailController: emailController,
        currentUser: _user!,
        apiService: _apiService,
        onUpdated: (updatedUser) {
          setState(() {
            _user = updatedUser;
          });
        },
      ),
    );
  }

  Future<void> _showImagePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: PixelColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  PixelText(
                    text: 'CHỌN ẢNH ĐẠI DIỆN',
                    style: PixelTextStyle.title,
                    color: PixelColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImagePickerOption(
                        context,
                        Icons.photo_library,
                        'THƯ VIỆN',
                        () => _pickImage(ImageSource.gallery),
                      ),
                      _buildImagePickerOption(
                        context,
                        Icons.camera_alt,
                        'MÁY ẢNH',
                        () => _pickImage(ImageSource.camera),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PixelButton(
                    text: 'HỦY',
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: PixelColors.surface,
                    textColor: PixelColors.textPrimary,
                    width: 100,
                    height: 40,
                    borderWidth: 2,
                    shadowOffset: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: PixelCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: PixelColors.primary),
            const SizedBox(height: 8),
            PixelText(
              text: label,
              style: PixelTextStyle.body,
              color: PixelColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        
        try {
          final updatedUser = await _apiService.uploadAvatar(image.path);
          setState(() {
            _user = updatedUser;
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật ảnh đại diện thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final User currentUser;
  final ApiService apiService;
  final Function(User) onUpdated;

  const _EditProfileDialog({
    required this.usernameController,
    required this.emailController,
    required this.currentUser,
    required this.apiService,
    required this.onUpdated,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelText(
            text: 'CHỈNH SỬA HỒ SƠ',
            style: PixelTextStyle.headline,
            color: PixelColors.primary,
          ),
          const SizedBox(height: 24),
          // Avatar preview and change button
          GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: PixelColors.background,
                border: Border.all(color: PixelColors.border, width: 2),
                shape: BoxShape.circle,
              ),
              child: widget.currentUser.avatarUrl != null && widget.currentUser.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.apiService.getAvatarUrl(widget.currentUser.avatarUrl),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: PixelText(
                              text: widget.currentUser.username.substring(0, 1).toUpperCase(),
                              style: PixelTextStyle.headline,
                              color: PixelColors.primary,
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: PixelText(
                        text: widget.currentUser.username.substring(0, 1).toUpperCase(),
                        style: PixelTextStyle.headline,
                        color: PixelColors.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          PixelText(
            text: 'CHẠM ĐỂ ĐỔI ẢNH',
            style: PixelTextStyle.caption,
            color: PixelColors.textSecondary,
          ),
          const SizedBox(height: 24),
          // Form fields
          PixelCard(
            padding: EdgeInsets.zero,
            child: TextField(
              controller: widget.usernameController,
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
            ),
          ),
          const SizedBox(height: 16),
          PixelCard(
            padding: EdgeInsets.zero,
            child: TextField(
              controller: widget.emailController,
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
            ),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PixelButton(
                text: 'HỦY',
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(),
                backgroundColor: PixelColors.surface,
                textColor: PixelColors.textPrimary,
                width: 80,
                height: 40,
                borderWidth: 2,
                shadowOffset: 2,
              ),
              const SizedBox(width: 8),
              PixelButton(
                text: _isSaving ? '...' : 'LƯU',
                onPressed: _isSaving
                    ? null
                    : () async {
                      final newUsername = widget.usernameController.text.trim();
                      final newEmail = widget.emailController.text.trim();

                      // Validation
                      if (newUsername.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tên người dùng không được để trống'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newEmail.isEmpty || !newEmail.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email không hợp lệ'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => _isSaving = true);

                      try {
                        final updatedUser = await widget.apiService.updateProfile(
                          username: newUsername != widget.currentUser.username ? newUsername : null,
                          email: newEmail != widget.currentUser.email ? newEmail : null,
                        );

                        setState(() => _isSaving = false);
                        Navigator.of(context).pop();

                        // Callback to update parent
                        widget.onUpdated(updatedUser);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cập nhật hồ sơ thành công'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                backgroundColor: PixelColors.accent,
                width: 80,
                height: 40,
                borderWidth: 2,
                shadowOffset: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isSaving = true);
        
        try {
          final updatedUser = await widget.apiService.uploadAvatar(image.path);
          widget.onUpdated(updatedUser);
          
          setState(() => _isSaving = false);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật ảnh đại diện thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          setState(() => _isSaving = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
