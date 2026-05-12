import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/local_video_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_glass_card.dart';
import '../../auth/pages/auth_page.dart';
import '../../editor/widgets/preview_video.dart';

/// Màn hình danh sách dự án.
class ProjectPage extends StatelessWidget {
  /// Khởi tạo [ProjectPage].
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
          return _buildLoginRequired(context);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 98),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      Expanded(child: _buildVideoList()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Header của trang dự án.
  Widget _buildHeader() {
    return AppGlassCard(
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        colors: [
          AppTheme.surfaceSoft.withOpacity(0.78),
          AppTheme.primaryBlue.withOpacity(0.16),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.folder_copy_rounded, color: AppTheme.cyanBlue),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dự án của tôi',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý video gốc và video đã chỉnh sửa trên Firebase Storage.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị màn hình yêu cầu đăng nhập.
  Widget _buildLoginRequired(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppGlassCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, size: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đăng nhập để xem dự án',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Danh sách video được đồng bộ theo tài khoản Firebase Auth và Firestore.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Đăng nhập / Đăng ký'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Danh sách video metadata lấy từ Firestore.
  Widget _buildVideoList() {
    return StreamBuilder(
      stream: LocalVideoRepository().watchMyVideos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMessageState(
            icon: Icons.error_outline,
            title: 'Không tải được dữ liệu',
            subtitle: '${snapshot.error}',
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final title = (data['title'] ?? 'Không có tên').toString();
            final type = (data['type'] ?? 'unknown').toString();
            final downloadUrl = (data['downloadUrl'] ?? '').toString();
            final storagePath = (data['storagePath'] ?? '').toString();
            final sizeBytes = data['sizeBytes'] is int
                ? data['sizeBytes'] as int
                : 0;
            final durationMs = data['durationMs'] is int
                ? data['durationMs'] as int
                : null;

            return Dismissible(
              key: ValueKey(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 22),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.delete_outline),
              ),
              confirmDismiss: (_) => _confirmDelete(context),
              onDismissed: (_) async {
                await _deleteVideo(context, doc.id, storagePath);
              },
              child: _VideoCard(
                title: title,
                type: type,
                downloadUrl: downloadUrl,
                sizeText: _formatBytes(sizeBytes),
                durationText: durationMs == null
                    ? null
                    : '${(durationMs / 1000).toStringAsFixed(1)}s',
                onTap: () => _openVideo(context, downloadUrl),
              ),
            );
          },
        );
      },
    );
  }

  /// Màn hình rỗng khi chưa có video nào.
  Widget _buildEmptyState() {
    return _buildMessageState(
      icon: Icons.video_library_outlined,
      title: 'Chưa có dự án nào',
      subtitle: 'Vào tab Tạo video để upload video đầu tiên lên hệ thống.',
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: AppGlassCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 76, color: AppTheme.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Mở video bằng downloadUrl từ Firebase Storage.
  Future<void> _openVideo(BuildContext context, String downloadUrl) async {
    if (downloadUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video chưa có downloadUrl hợp lệ.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewVideo(
          filePath: downloadUrl,
          generationTime: Duration.zero,
          allowSave: false,
        ),
      ),
    );
  }

  /// Xác nhận trước khi xóa video.
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Xóa video?'),
          content: const Text(
            'Video trên Firebase Storage và metadata trên Firestore sẽ bị xóa khỏi hệ thống.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  /// Xóa video trên Firebase Storage và metadata.
  Future<void> _deleteVideo(
    BuildContext context,
    String videoId,
    String storagePath,
  ) async {
    try {
      await LocalVideoRepository().deleteVideo(
        videoId: videoId,
        storagePath: storagePath,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa video.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa video: $e')),
      );
    }
  }

  /// Định dạng dung lượng file.
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;

    while (value >= 1024 && index < suffixes.length - 1) {
      value /= 1024;
      index++;
    }

    return '${value.toStringAsFixed(2)} ${suffixes[index]}';
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.title,
    required this.type,
    required this.downloadUrl,
    required this.sizeText,
    required this.durationText,
    required this.onTap,
  });

  final String title;
  final String type;
  final String downloadUrl;
  final String sizeText;
  final String? durationText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEdited = type == 'edited';

    return AppGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEdited
                    ? [AppTheme.cyanBlue.withOpacity(0.95), AppTheme.primaryBlue]
                    : [AppTheme.primaryBlue, const Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isEdited ? Icons.movie_filter_outlined : Icons.video_file_outlined,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Tag(text: isEdited ? 'Edited' : 'Original'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  downloadUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(icon: Icons.storage_outlined, text: sizeText),
                    if (durationText != null)
                      _MetaChip(icon: Icons.timer_outlined, text: durationText!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.24)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.cyanBlue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
