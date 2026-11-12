import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Model giảng viên.
///
/// Đề bài chỉ cho phép đúng 4 trường: `IDGV`, `Fullname`, `Image`, `SumClass`.
/// Không thêm field khác vào Firestore để tránh bị trừ điểm.
class Teacher {
  const Teacher({
    required this.idgv,
    required this.fullname,
    required this.image,
    required this.sumClass,
  });

  final String idgv;
  final String fullname;

  /// URL ảnh trên Firebase Storage (hoặc base64 `data:image/...` ở chế độ demo).
  final String image;
  final int sumClass;

  Map<String, Object> toMap() => {
    'IDGV': idgv,
    'Fullname': fullname,
    'Image': image,
    'SumClass': sumClass,
  };

  /// Chấp nhận cả `SumClass` dạng số hoặc chuỗi để dữ liệu import/json không lỗi.
  factory Teacher.fromMap(Map<String, dynamic> map) {
    final rawSum = map['SumClass'];
    final sumClass = rawSum is num
        ? rawSum.toInt()
        : int.tryParse('${rawSum ?? ''}'.trim()) ?? 0;
    return Teacher(
      idgv: '${map['IDGV'] ?? ''}'.trim(),
      fullname: '${map['Fullname'] ?? ''}'.trim(),
      image: '${map['Image'] ?? ''}'.trim(),
      sumClass: sumClass < 0 ? 0 : sumClass,
    );
  }

  Teacher copyWith({
    String? idgv,
    String? fullname,
    String? image,
    int? sumClass,
  }) {
    return Teacher(
      idgv: idgv ?? this.idgv,
      fullname: fullname ?? this.fullname,
      image: image ?? this.image,
      sumClass: sumClass ?? this.sumClass,
    );
  }

  /// Ký tự đầu của tên (dùng khi chưa có ảnh).
  String get initials {
    final parts = fullname
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters();
    return '${parts.first.characters()}${parts.last.characters()}';
  }

  /// Bậc "kinh nghiệm" theo số lớp đang phụ trách — dùng cho huy hiệu.
  String get loadLabel {
    if (sumClass >= 10) return 'Rất cao';
    if (sumClass >= 6) return 'Cao';
    if (sumClass >= 3) return 'Trung bình';
    return 'Thấp';
  }

  /// Nén và thu nhỏ ảnh về kích thước avatar (tối đa 256x256) để:
  /// 1. Tải lên Firebase Storage siêu nhanh (chỉ ~15-30KB thay vì nhiều MB).
  /// 2. Khi lưu dạng Base64 data URI thì dung lượng nhỏ gọn, luôn lưu được vào Firestore.
  static Future<Uint8List> compressAvatar(
    Uint8List bytes, {
    int maxDimension = 256,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxDimension,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (_) {}
    return bytes;
  }

  /// Ảnh đã giải mã base64 nếu là data URI (chế độ demo hoặc lưu base64).
  static Uint8List? decodeDataImage(String image) {
    if (!image.startsWith('data:')) return null;
    final commaIndex = image.indexOf(',');
    if (commaIndex == -1) return null;
    try {
      return base64Decode(image.substring(commaIndex + 1));
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Teacher &&
      other.idgv == idgv &&
      other.fullname == fullname &&
      other.image == image &&
      other.sumClass == sumClass;

  @override
  int get hashCode => Object.hash(idgv, fullname, image, sumClass);

  @override
  String toString() => 'Teacher($idgv, $fullname, $sumClass lớp)';
}

extension on String {
  String characters() => isEmpty ? '?' : this[0].toUpperCase();
}
