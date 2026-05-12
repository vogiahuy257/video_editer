import 'dart:typed_data';

import 'package:video_player/video_player.dart';

/// Tạo [VideoPlayerController] từ URL trên Web.
///
/// Web không có dart:io File, nên mọi nguồn phát cần là network/data/blob URL.
VideoPlayerController createVideoControllerFromPath(String path) {
  return VideoPlayerController.networkUrl(Uri.parse(path));
}

/// Tạo [VideoPlayerController] từ bytes bằng data URI.
VideoPlayerController createVideoControllerFromBytes(
  Uint8List bytes, {
  String mimeType = 'video/mp4',
}) {
  return VideoPlayerController.networkUrl(
    Uri.dataFromBytes(bytes, mimeType: mimeType),
  );
}
