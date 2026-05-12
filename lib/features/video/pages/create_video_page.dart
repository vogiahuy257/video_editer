import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/local_video_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_glass_card.dart';
import '../../auth/pages/auth_page.dart';
import '../../editor/pages/video_editor_basic_example_page.dart';

/// Màn hình tạo video mới.
class CreateVideoPage extends StatefulWidget {
  /// Khởi tạo [CreateVideoPage].
  const CreateVideoPage({super.key});

  @override
  State<CreateVideoPage> createState() => _CreateVideoPageState();
}

class _CreateVideoPageState extends State<CreateVideoPage> {
  bool _isPickingVideo = false;

  /// Chọn video từ máy, upload video gốc và mở editor.
  Future<void> _pickVideoAndOpenEditor() async {
    try {
      setState(() => _isPickingVideo = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;
      final bytes = file.bytes;

      if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
        _showMessage('Không lấy được dữ liệu video.');
        return;
      }

      final fileName = file.name;
      final title = _removeExtension(fileName);
      final editorVideo = bytes != null && bytes.isNotEmpty
          ? EditorVideo.memory(bytes)
          : EditorVideo.file(path!);
      final metadata = await ProVideoEditor.instance.getMetadata(editorVideo);

      await LocalVideoRepository().savePlatformFileVideo(
        file: file,
        type: 'original',
        title: title,
        durationMs: metadata.duration.inMilliseconds,
      );

      if (!mounted) return;

      _showMessage('Đã upload video gốc lên hệ thống.');

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditorBasicExamplePage(
            initialVideoPath: path,
            initialVideoBytes: bytes,
            initialVideoTitle: title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không thể tạo video: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingVideo = false);
      }
    }
  }

  /// Hiển thị thông báo nhanh trên màn hình.
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Bỏ phần mở rộng file để lấy tiêu đề video.
  String _removeExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex <= 0) {
      return fileName;
    }

    return fileName.substring(0, dotIndex);
  }

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
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 98),
                  child: user == null
                      ? _buildLoginRequired(context)
                      : _buildCreateVideoContent(user),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateVideoContent(User user) {
    return ListView(
      children: [
        _buildHero(user),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildUploadCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfoCard()),
                ],
              );
            }

            return Column(
              children: [
                _buildUploadCard(),
                const SizedBox(height: 16),
                _buildInfoCard(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHero(User user) {
    final name = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : user.email ?? 'Creator';

    return AppGlassCard(
      padding: const EdgeInsets.all(28),
      gradient: LinearGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.28),
          AppTheme.surfaceSoft.withOpacity(0.72),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.cyanBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.cyanBlue.withOpacity(0.24)),
                  ),
                  child: const Text(
                    'VIDEO EDITOR STUDIO',
                    style: TextStyle(
                      color: AppTheme.cyanBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Xin chào, $name',
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Upload video lên Firebase Storage và mở trình chỉnh sửa hiện đại.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Icon(Icons.play_circle_fill_rounded, size: 54),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
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
            const SizedBox(height: 18),
            const Text(
              'Đăng nhập để bắt đầu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn cần tài khoản để upload video gốc, video đã chỉnh sửa và metadata dự án.',
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
    );
  }

  Widget _buildUploadCard() {
    return AppGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.cloud_upload_outlined,
            title: 'Upload video',
            subtitle: 'Chọn một video từ máy để lưu và chỉnh sửa.',
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.42),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.cyanBlue],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.video_file_outlined, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MP4, MOV, AVI...',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Video sẽ được upload lên Firebase Storage và metadata lưu trong Firestore.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isPickingVideo ? null : _pickVideoAndOpenEditor,
                    icon: _isPickingVideo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      _isPickingVideo ? 'Đang xử lý...' : 'Chọn video mới',
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

  Widget _buildInfoCard() {
    return AppGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.account_tree_outlined,
            title: 'Luồng hệ thống',
            subtitle: 'Thiết kế đa nền tảng cho Web, Windows và Android.',
          ),
          const SizedBox(height: 18),
          const _InfoRow(
            step: '01',
            title: 'Upload Storage',
            text: 'Video thật được lưu trong Firebase Storage theo users/{uid}/videos.',
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            step: '02',
            title: 'Lưu metadata',
            text: 'Firestore NoSQL lưu title, type, downloadUrl, storagePath, sizeBytes, createdAt.',
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            step: '03',
            title: 'Tùy chỉnh video',
            text: 'Mở editor để cắt, chỉnh sửa, render và lưu bản edited.',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppTheme.cyanBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.step,
    required this.title,
    required this.text,
  });

  final String step;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: AppTheme.cyanBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
