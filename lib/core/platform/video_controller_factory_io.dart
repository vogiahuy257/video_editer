import 'dart:io';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

/// Tạo [VideoPlayerController] từ đường dẫn file local trên Windows/Android.
VideoPlayerController createVideoControllerFromPath(String path) {
  final uri = Uri.tryParse(path);

  if (uri != null && uri.hasScheme && uri.scheme.startsWith('http')) {
    return VideoPlayerController.networkUrl(uri);
  }

  return VideoPlayerController.file(File(path));
}

/// Tạo [VideoPlayerController] từ bytes cho trường hợp Web hoặc fallback.
VideoPlayerController createVideoControllerFromBytes(
  Uint8List bytes, {
  String mimeType = 'video/mp4',
}) {
  return VideoPlayerController.networkUrl(
    Uri.dataFromBytes(bytes, mimeType: mimeType),
  );
}
