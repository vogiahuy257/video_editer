import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service xử lý đăng nhập, đăng ký và đăng xuất bằng Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream theo dõi trạng thái đăng nhập hiện tại.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại.
  User? get currentUser => _auth.currentUser;

  /// Kiểm tra user đã đăng nhập hay chưa.
  bool get isSignedIn => _auth.currentUser != null;

  /// Đăng ký tài khoản mới.
  ///
  /// Input:
  /// - [email]: email đăng nhập.
  /// - [password]: mật khẩu đăng nhập.
  /// - [displayName]: tên hiển thị của user.
  ///
  /// Logic:
  /// - Tạo user bằng Firebase Auth.
  /// - Cập nhật displayName.
  /// - Tạo document metadata trong Firestore tại users/{uid}.
  ///
  /// Output:
  /// - Trả về [UserCredential] nếu đăng ký thành công.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Không thể tạo tài khoản.');
    }

    await user.updateDisplayName(displayName.trim());

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return credential;
  }

  /// Đăng nhập bằng email và mật khẩu.
  ///
  /// Input:
  /// - [email]: email đã đăng ký.
  /// - [password]: mật khẩu.
  ///
  /// Output:
  /// - Trả về [UserCredential] nếu đăng nhập thành công.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Đăng xuất user hiện tại.
  Future<void> signOut() {
    return _auth.signOut();
  }
}
