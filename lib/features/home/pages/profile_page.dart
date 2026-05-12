import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_glass_card.dart';
import '../../auth/pages/auth_page.dart';

/// Màn hình thông tin cá nhân.
class ProfilePage extends StatelessWidget {
  /// Khởi tạo [ProfilePage].
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 98),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildUserInfo(user),
                    const SizedBox(height: 16),
                    _buildMenuSection(),
                    const SizedBox(height: 18),
                    _buildAuthButton(context, user),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Header của trang cá nhân.
  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài khoản',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Quản lý hồ sơ và cài đặt ứng dụng.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  /// Hiển thị thông tin user hiện tại.
  Widget _buildUserInfo(User? user) {
    final displayName = user?.displayName;
    final email = user?.email;
    final name = user == null
        ? 'Khách'
        : (displayName?.isNotEmpty == true ? displayName! : 'Người dùng');

    return AppGlassCard(
      padding: const EdgeInsets.all(24),
      gradient: LinearGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.22),
          AppTheme.surfaceSoft.withOpacity(0.76),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.cyanBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Text(
              _avatarText(name),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  user == null ? 'Chưa đăng nhập' : (email ?? ''),
                  style: const TextStyle(color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user == null ? 'Guest mode' : 'Firebase Auth active',
                    style: const TextStyle(
                      color: AppTheme.cyanBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _avatarText(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Widget _buildMenuSection() {
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.movie_creation_outlined,
            label: 'Video đã lưu',
            subtitle: 'Xem lại project và metadata',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.history_rounded,
            label: 'Lịch sử chỉnh sửa',
            subtitle: 'Các thao tác gần đây',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.storage_outlined,
            label: 'Firebase Storage',
            subtitle: 'users/{uid}/videos',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Trung tâm trợ giúp',
            subtitle: 'Hướng dẫn sử dụng demo',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// Nút đăng nhập/đăng ký hoặc đăng xuất.
  Widget _buildAuthButton(BuildContext context, User? user) {
    if (user == null) {
      return FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AuthPage()),
          );
        },
        icon: const Icon(Icons.login),
        label: const Text('Đăng nhập / Đăng ký'),
      );
    }

    return OutlinedButton.icon(
      onPressed: () async {
        await AuthService().signOut();
      },
      icon: const Icon(Icons.logout),
      label: const Text('Đăng xuất'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: Colors.white.withOpacity(0.16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  /// Item chức năng trong trang cá nhân.
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppTheme.cyanBlue),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
