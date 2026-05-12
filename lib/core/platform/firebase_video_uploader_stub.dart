import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

Future<TaskSnapshot> uploadVideoContent({
  required Reference storageRef,
  required String contentType,
  String? sourcePath,
  Uint8List? bytes,
}) async {
  throw UnsupportedError('Nền tảng hiện tại chưa hỗ trợ upload video.');
}

Future<int> getVideoSizeBytes({
  String? sourcePath,
  Uint8List? bytes,
}) async {
  return bytes?.lengthInBytes ?? 0;
}
