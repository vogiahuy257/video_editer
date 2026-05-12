import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Upload video lên Firebase Storage trên Web.
///
/// Web không có file path local an toàn, nên cần upload bằng bytes.
Future<TaskSnapshot> uploadVideoContent({
  required Reference storageRef,
  required String contentType,
  String? sourcePath,
  Uint8List? bytes,
}) async {
  if (bytes == null || bytes.isEmpty) {
    throw Exception(
      'Web cần bytes của video để upload. Hãy chọn video bằng FilePicker với withData: true.',
    );
  }

  return await storageRef.putData(
    bytes,
    SettableMetadata(contentType: contentType),
  );
}

/// Lấy dung lượng video từ bytes trên Web.
Future<int> getVideoSizeBytes({
  String? sourcePath,
  Uint8List? bytes,
}) async {
  return bytes?.lengthInBytes ?? 0;
}
