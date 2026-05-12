import 'dart:typed_data';

import 'package:video_player/video_player.dart';

VideoPlayerController createVideoControllerFromPath(String path) {
  return VideoPlayerController.networkUrl(Uri.parse(path));
}

VideoPlayerController createVideoControllerFromBytes(
  Uint8List bytes, {
  String mimeType = 'video/mp4',
}) {
  return VideoPlayerController.networkUrl(
    Uri.dataFromBytes(bytes, mimeType: mimeType),
  );
}
