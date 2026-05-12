import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Upload video lên Firebase Storage trên Windows/Android.
///
/// Ưu tiên upload bằng file path để không nạp toàn bộ video vào RAM.
Future<TaskSnapshot> uploadVideoContent({
  required Reference storageRef,
  required String contentType,
  String? sourcePath,
  Uint8List? bytes,
}) async {
  final metadata = SettableMetadata(contentType: contentType);

  if (sourcePath != null && sourcePath.trim().isNotEmpty) {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('File video không tồn tại: $sourcePath');
    }

    return await storageRef.putFile(file, metadata);
  }

  if (bytes != null && bytes.isNotEmpty) {
    return await storageRef.putData(bytes, metadata);
  }

  throw Exception('Không có dữ liệu video để upload.');
}

/// Lấy dung lượng video từ file path hoặc bytes.
Future<int> getVideoSizeBytes({
  String? sourcePath,
  Uint8List? bytes,
}) async {
  if (sourcePath != null && sourcePath.trim().isNotEmpty) {
    final file = File(sourcePath);
    if (await file.exists()) {
      return file.length();
    }
  }

  return bytes?.lengthInBytes ?? 0;
}
