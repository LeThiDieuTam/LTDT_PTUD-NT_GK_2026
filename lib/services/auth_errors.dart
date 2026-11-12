import 'package:firebase_auth/firebase_auth.dart';

/// Dịch các mã lỗi FirebaseAuth thành câu tiếng Việt dễ hiểu.
String authErrorMessage(Object error, {bool isSignUp = false}) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email hoặc mật khẩu không chính xác.',
      'invalid-email' => 'Email không đúng định dạng.',
      'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
      'email-already-in-use' => 'Email này đã được sử dụng cho tài khoản khác.',
      'weak-password' => 'Mật khẩu quá yếu, cần tối thiểu 6 ký tự.',
      'too-many-requests' =>
        'Bạn đã thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.',
      'network-request-failed' =>
        'Không có kết nối mạng. Vui lòng kiểm tra lại.',
      'operation-not-allowed' =>
        'Firebase chưa bật phương thức đăng nhập Email/Password.',
      'requires-recent-login' =>
        'Phiên đăng nhập đã cũ, hãy đăng nhập lại để tiếp tục.',
      'admin-restricted-operation' => 'Chức năng này đã bị quản trị viên khóa.',
      _ => error.message ?? 'Đăng nhập thất bại (${error.code}).',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Tài khoản không có quyền thực hiện thao tác này.',
      'unavailable' => 'Không kết nối được Firebase, vui lòng thử lại.',
      _ => error.message ?? 'Lỗi Firebase (${error.code}).',
    };
  }
  return isSignUp ? 'Không thể tạo tài khoản. Vui lòng thử lại.' : '$error';
}
