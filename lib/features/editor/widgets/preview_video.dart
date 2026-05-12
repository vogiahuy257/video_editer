import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import '/features/editor/widgets/pixel_transparent_painter.dart';
import '../../../core/services/local_video_repository.dart';
import '../../../core/theme/app_theme.dart';

/// A widget that previews a video from raw bytes.
///
/// Displays the video and optionally shows when it was generated.
class PreviewVideo extends StatefulWidget {
  /// Creates a [PreviewVideo] widget.
  const PreviewVideo({
    super.key,
    required this.filePath,
    required this.generationTime,
    this.allowSave = true,
  });

  /// File path, network URL, data URL hoặc blob URL của video preview.
  final String filePath;

  /// The time it took to generate the video preview.
  final Duration generationTime;

  /// Có hiển thị nút lưu video edited hay không.
  final bool allowSave;

  @override
  State<PreviewVideo> createState() => _PreviewVideoState();
}

class _PreviewVideoState extends State<PreviewVideo> {
  final _valueStyle = const TextStyle(fontStyle: FontStyle.italic);

  late Future<VideoMetadata> _videoMetadata;
  late final int _generationTime = widget.generationTime.inMilliseconds;
  final _player = Player();
  late final _controller = VideoController(_player);

  final _numberFormatter = NumberFormat();

  bool _isSavingToCloud = false;

  @override
  void initState() {
    super.initState();

    _videoMetadata = ProVideoEditor.instance.getMetadata(
      _buildEditorVideoForPreview(),
    );
    _initializePlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    final source = _isRemoteSource(widget.filePath)
        ? widget.filePath
        : 'file://${widget.filePath}';
    final media = Media(source);
    await _player.open(media, play: false);
  }

  /// Chọn đúng nguồn video cho ProVideoEditor metadata.
  EditorVideo _buildEditorVideoForPreview() {
    if (_isHttpSource(widget.filePath)) {
      return EditorVideo.network(widget.filePath);
    }

    return EditorVideo.file(widget.filePath);
  }

  /// Kiểm tra nguồn video có phải URL trình duyệt/network hay không.
  bool _isRemoteSource(String value) {
    return _isHttpSource(value) ||
        value.startsWith('blob:') ||
        value.startsWith('data:');
  }

  /// Kiểm tra nguồn video có phải HTTP/HTTPS URL hay không.
  bool _isHttpSource(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }


  /// Upload video đã chỉnh sửa lên Firebase Storage và ghi metadata lên Firestore.
  ///
  /// Windows/Android: video render thường là file path local nên upload trực tiếp.
  /// Web: nếu plugin trả về blob URL thì app vẫn preview được, nhưng upload edited
  /// cần pipeline bytes riêng của trình duyệt.
  Future<void> _saveEditedVideoToCloud() async {
    try {
      setState(() => _isSavingToCloud = true);

      if (_isRemoteSource(widget.filePath)) {
        throw Exception(
          'Nguồn video hiện tại là URL/blob. Bản Web đã hỗ trợ upload video gốc; '
          'upload video đã render cần lấy bytes đầu ra từ plugin trước khi lưu Storage.',
        );
      }

      final metadata = await _videoMetadata;

      await LocalVideoRepository().saveVideo(
        sourcePath: widget.filePath,
        originalFileName: 'edited_video.mp4',
        type: 'edited',
        title: 'edited_video',
        durationMs: metadata.duration.inMilliseconds,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã upload video đã chỉnh sửa lên hệ thống.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu video: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingToCloud = false);
      }
    }
  }

  String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    var size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Theme(
          data: Theme.of(context),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Video đã xuất'),
              backgroundColor: AppTheme.background,
              actions: widget.allowSave
                  ? [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilledButton.icon(
                          onPressed:
                              _isSavingToCloud ? null : _saveEditedVideoToCloud,
                          icon: _isSavingToCloud
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload_rounded),
                          label: Text(
                            _isSavingToCloud ? 'Đang upload' : 'Upload',
                          ),
                        ),
                      ),
                    ]
                  : null,
            ),
            body: CustomPaint(
              painter: const PixelTransparentPainter(
                primary: AppTheme.background,
                secondary: AppTheme.surfaceSoft,
              ),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  _buildVideoPlayer(constraints),
                  _buildGenerationInfos(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer(BoxConstraints constraints) {
    return FutureBuilder<VideoMetadata>(
      future: _videoMetadata,
      builder: (context, snapshot) {
        final aspectRatio = snapshot.data?.resolution.aspectRatio ?? 1;
        final rotation = snapshot.data?.rotation ?? 0;

        int convertedRotation = rotation % 360;

        final is90DegRotated =
            convertedRotation == 90 || convertedRotation == 270;

        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        double width = maxWidth;
        double height = is90DegRotated
            ? width * aspectRatio
            : width / aspectRatio;

        if (height > maxHeight) {
          height = maxHeight;
          width = height * aspectRatio;
        }
        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Hero(
              tag: const ProImageEditorConfigs().heroTag,
              child: Video(
                key: const ValueKey('Preview-Video-Player'),
                controller: _controller,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerationInfos() {
    TableRow tableSpace = const TableRow(
      children: [SizedBox(height: 3), SizedBox()],
    );
    return Positioned(
      top: 10,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: FutureBuilder<VideoMetadata>(
              future: _videoMetadata,
              builder: (context, snapshot) {
                var data = snapshot.data;

                if (data == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator.adaptive();
                }

                final resolution = data.resolution;
                final dimension =
                    '${_numberFormatter.format(resolution.width.round())}'
                    ' x '
                    '${_numberFormatter.format(resolution.height.round())}';

                return Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    TableRow(
                      children: [
                        const Text('Generation-Time'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '${_numberFormatter.format(_generationTime)} ms',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    tableSpace,
                    TableRow(
                      children: [
                        const Text('Video-Size'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            formatBytes(data.fileSize),
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    tableSpace,
                    TableRow(
                      children: [
                        const Text('Content-Type'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'video/${data.extension}',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    tableSpace,
                    TableRow(
                      children: [
                        const Text('Dimension'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            dimension,
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    tableSpace,
                    TableRow(
                      children: [
                        const Text('Video-Duration'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            '${data.duration.inSeconds} s',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
