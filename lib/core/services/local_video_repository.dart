import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../platform/firebase_video_uploader.dart';

/// Repository xử lý lưu video đa nền tảng.
///
/// Logic mới:
/// - File video thật được upload lên Firebase Storage.
/// - Metadata được lưu trong Cloud Firestore.
/// - Hỗ trợ Web bằng bytes và Windows/Android bằng file path.
class LocalVideoRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Lấy user hiện tại.
  ///
  /// Nếu chưa đăng nhập thì không cho lưu video.
  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập trước khi lưu video.');
    }

    return user;
  }

  /// Lắng nghe danh sách video của user hiện tại từ Firestore.
  ///
  /// Output:
  /// - Stream danh sách metadata video trong users/{uid}/videos.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyVideos() {
    final user = _currentUser;

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Lưu video từ [PlatformFile] sau khi user chọn bằng FilePicker.
  ///
  /// Input:
  /// - [file]: file lấy từ FilePicker.
  /// - [type]: original hoặc edited.
  /// - [title]: tên hiển thị trong app.
  /// - [durationMs]: thời lượng video nếu lấy được.
  ///
  /// Logic:
  /// - Windows/Android: ưu tiên upload bằng file.path.
  /// - Web: upload bằng file.bytes.
  /// - Lưu metadata vào Firestore, gồm downloadUrl và storagePath.
  Future<String> savePlatformFileVideo({
    required PlatformFile file,
    required String type,
    required String title,
    int? durationMs,
  }) {
    return saveVideo(
      sourcePath: file.path,
      bytes: file.bytes,
      originalFileName: file.name,
      type: type,
      title: title,
      durationMs: durationMs,
    );
  }

  /// Lưu video từ file path hoặc bytes lên Firebase Storage và metadata lên Firestore.
  ///
  /// Input:
  /// - [sourcePath]: đường dẫn file local, thường có trên Windows/Android.
  /// - [bytes]: dữ liệu video, bắt buộc trên Web.
  /// - [originalFileName]: tên file gốc nếu có.
  /// - [type]: original hoặc edited.
  /// - [title]: tên hiển thị.
  /// - [durationMs]: thời lượng video tính bằng milliseconds.
  ///
  /// Output:
  /// - Trả về Firestore document id.
  Future<String> saveVideo({
    String? sourcePath,
    Uint8List? bytes,
    String? originalFileName,
    required String type,
    required String title,
    int? durationMs,
  }) async {
    final user = _currentUser;

    if ((sourcePath == null || sourcePath.trim().isEmpty) &&
        (bytes == null || bytes.isEmpty)) {
      throw Exception('Không có dữ liệu video để lưu.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final extension = _resolveExtension(
      sourcePath: sourcePath,
      fileName: originalFileName,
    );
    final safeTitle = _sanitizeFileName(title);
    final fileName = '${safeTitle}_$now$extension';
    final storagePath = 'users/${user.uid}/videos/$type/$fileName';
    final contentType = _contentTypeFromExtension(extension);
    final storageRef = _storage.ref(storagePath);

    final snapshot = await uploadVideoContent(
      storageRef: storageRef,
      contentType: contentType,
      sourcePath: sourcePath,
      bytes: bytes,
    );

    final downloadUrl = await snapshot.ref.getDownloadURL();
    final sizeBytes = await getVideoSizeBytes(
      sourcePath: sourcePath,
      bytes: bytes,
    );

    final docRef = await _db
        .collection('users')
        .doc(user.uid)
        .collection('videos')
        .add({
      'ownerId': user.uid,
      'title': title,
      'type': type,
      'fileName': fileName,
      'originalFileName': originalFileName ?? '',
      'sourcePath': sourcePath ?? '',
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'durationMs': durationMs,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Xóa metadata video và file trên Firebase Storage nếu có.
  ///
  /// Input:
  /// - [videoId]: document id trong users/{uid}/videos.
  /// - [storagePath]: path file trên Firebase Storage.
  Future<void> deleteVideo({
    required String videoId,
    required String storagePath,
  }) async {
    final user = _currentUser;

    if (storagePath.trim().isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } on FirebaseException catch (e) {
        // Nếu file đã bị xóa trước đó thì vẫn cho xóa metadata.
        if (e.code != 'object-not-found') {
          rethrow;
        }
      }
    }

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('videos')
        .doc(videoId)
        .delete();
  }

  /// Xác định đuôi file từ path hoặc tên file.
  String _resolveExtension({
    String? sourcePath,
    String? fileName,
  }) {
    final fromName = _getExtension(fileName ?? '');
    if (fromName.isNotEmpty) {
      return fromName;
    }

    final fromPath = _getExtension(sourcePath ?? '');
    if (fromPath.isNotEmpty) {
      return fromPath;
    }

    return '.mp4';
  }

  /// Lấy phần mở rộng file.
  String _getExtension(String value) {
    final normalized = value.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    final dotIndex = name.lastIndexOf('.');

    if (dotIndex < 0 || dotIndex == name.length - 1) {
      return '';
    }

    return name.substring(dotIndex).toLowerCase();
  }

  /// Map extension sang content type cơ bản cho Firebase Storage.
  String _contentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.webm':
        return 'video/webm';
      case '.mkv':
        return 'video/x-matroska';
      case '.mp4':
      default:
        return 'video/mp4';
    }
  }

  /// Làm sạch tên file để tránh lỗi ký tự đặc biệt.
  String _sanitizeFileName(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (cleaned.isEmpty) {
      return 'video';
    }

    return cleaned;
  }
}
