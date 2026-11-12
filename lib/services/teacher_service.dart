import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/teacher.dart';

/// Lỗi hiển thị trực tiếp cho người dùng (message thân thiện, đã dịch tiếng Việt).
class TeacherException implements Exception {
  const TeacherException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tầng truy cập dữ liệu:
/// - Firestore collection `GiangVien` (IDGV làm document ID).
/// - Firebase Storage thư mục `giang_vien/` cho ảnh.
/// - Khi [useFirebase] = false thì dùng dữ liệu demo trong bộ nhớ để chấm offline.
class TeacherService {
  TeacherService({required this.useFirebase});

  final bool useFirebase;

  static const String collectionName = 'GiangVien';
  static const String storageFolder = 'giang_vien';

  static final List<Teacher> _demoTeachers = [
    const Teacher(
      idgv: 'GV001',
      fullname: 'Nguyễn Văn An',
      image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      sumClass: 5,
    ),
    const Teacher(
      idgv: 'GV002',
      fullname: 'Trần Thị Bình',
      image: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      sumClass: 8,
    ),
    const Teacher(
      idgv: 'GV003',
      fullname: 'Lê Minh Châu',
      image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      sumClass: 3,
    ),
  ];

  /// Đếm thay đổi ở chế độ demo: 1 instance (màn hình) lắng nghe nhiều
  /// subscription nhưng mọi thay đổi đều phát lại toàn bộ danh sách.
  static int _demoRevision = 0;
  static StreamController<int>? _demoController;

  /// `sync: true` để lần subscribe đầu tiên nhận dữ liệu ngay lập tức
  /// (StreamBuilder không bị kẹt ở trạng thái chờ).
  static StreamController<int> get _demoChanges =>
      _demoController ??= StreamController<int>.broadcast(sync: true);

  void _notifyDemoChanged() {
    _demoRevision++;
    _demoChanges.add(_demoRevision);
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(collectionName);

  /// Dữ liệu realtime: Firestore snapshot stream (tự cập nhật khi có thay đổi
  /// từ thiết bị khác) hoặc stream nội bộ ở chế độ demo.
  Stream<List<Teacher>> watchAll() {
    if (!useFirebase) {
      return Stream<List<Teacher>>.multi((controller) {
        controller.add(_sortedDemo());
        final subscription = _demoChanges.stream.listen(
          (_) => controller.add(_sortedDemo()),
          onError: controller.addError,
        );
        controller.onCancel = subscription.cancel;
      });
    }
    return _collection
        .snapshots()
        .map<List<Teacher>>((snapshot) {
          final teachers = snapshot.docs
              .map((document) => Teacher.fromMap(document.data()))
              .toList();
          teachers.sort((a, b) => a.idgv.compareTo(b.idgv));
          return teachers;
        })
        .handleError((Object error) {
          throw TeacherException(_friendlyFirestoreError(error));
        });
  }

  Future<List<Teacher>> getAll() async {
    if (!useFirebase) return _sortedDemo();
    try {
      final snapshot = await _collection.get();
      final teachers = snapshot.docs
          .map((document) => Teacher.fromMap(document.data()))
          .toList();
      teachers.sort((a, b) => a.idgv.compareTo(b.idgv));
      return teachers;
    } catch (error) {
      throw TeacherException(_friendlyFirestoreError(error));
    }
  }

  Future<void> save(
    Teacher teacher,
    Uint8List? imageBytes, {
    required bool isNew,
    required String imageMimeType,
  }) async {
    if (!useFirebase) {
      await _saveDemo(
        teacher,
        imageBytes,
        isNew: isNew,
        imageMimeType: imageMimeType,
      );
      return;
    }

    var imageUrl = teacher.image;
    try {
      final document = _collection.doc(teacher.idgv);
      if (isNew && (await document.get()).exists) {
        throw TeacherException(
          'Mã giảng viên ${teacher.idgv} đã tồn tại trong hệ thống.',
        );
      }
      if (!isNew && !(await document.get()).exists) {
        throw TeacherException('Không tìm thấy giảng viên ${teacher.idgv}.');
      }
      if (imageBytes != null) {
        final compressed = await Teacher.compressAvatar(imageBytes);
        try {
          imageUrl = await _uploadImage(teacher.idgv, compressed, imageMimeType);
        } catch (storageError) {
          // Khi Firebase Storage chưa bật trên Console hoặc lỗi quyền/CORS/timeout,
          // tự động fallback mã hóa base64 data URI vào trường Image của Firestore.
          // Do ảnh đã được nén về < 30KB nên lưu tức thì vào CSDL mà không bị lỗi.
          imageUrl = 'data:image/png;base64,${base64Encode(compressed)}';
        }
      }
      // Chỉ ghi đúng 4 trường bắt buộc.
      await document.set({
        'IDGV': teacher.idgv,
        'Fullname': teacher.fullname,
        'Image': imageUrl,
        'SumClass': teacher.sumClass,
      });
    } on TeacherException {
      rethrow;
    } catch (error) {
      throw TeacherException(
        'Không lưu được giảng viên: ${_friendlyFirestoreError(error)}',
      );
    }
  }

  Future<String> _uploadImage(
    String idgv,
    Uint8List bytes,
    String mimeType,
  ) async {
    // Đổi tên file theo thời điểm để trình duyệt không cache ảnh cũ.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final imageRef = FirebaseStorage.instance.ref().child(
      '$storageFolder/$idgv-$stamp',
    );
    // Timeout 6 giây để không bao giờ bị treo ứng dụng nếu Storage chưa kích hoạt
    await imageRef
        .putData(bytes, SettableMetadata(contentType: mimeType))
        .timeout(const Duration(seconds: 6));
    return await imageRef.getDownloadURL().timeout(const Duration(seconds: 4));
  }

  Future<void> delete(Teacher teacher) async {
    if (!useFirebase) {
      _demoTeachers.removeWhere((item) => item.idgv == teacher.idgv);
      _notifyDemoChanged();
      return;
    }
    try {
      await _collection.doc(teacher.idgv).delete();
      await _deleteImagesOf(teacher.idgv);
    } catch (error) {
      throw TeacherException(
        'Không xóa được giảng viên: ${_friendlyFirestoreError(error)}',
      );
    }
  }

  /// Xóa ảnh cũ trên Storage (ảnh được lưu tên `<IDGV>-<timestamp>`).
  Future<void> _deleteImagesOf(String idgv) async {
    try {
      final refs = await FirebaseStorage.instance.ref(storageFolder).listAll();
      for (final item in refs.items) {
        if (item.name.startsWith('$idgv-')) {
          try {
            await item.delete();
          } on FirebaseException catch (error) {
            if (error.code != 'object-not-found') rethrow;
          }
        }
      }
    } on FirebaseException catch (error) {
      // Vùng Storage chưa bật hoặc chưa cấu hình bucket: bỏ qua, DB đã xóa xong.
      if (error.code != 'object-not-found' && error.code != 'unauthorized') {
        rethrow;
      }
    }
  }

  /// Thêm nhanh dữ liệu mẫu (nút "Nạp dữ liệu mẫu" khi bảng trống).
  Future<int> seedSampleData() async {
    const samples = [
      Teacher(
        idgv: 'GV001',
        fullname: 'Nguyễn Văn An',
        image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        sumClass: 5,
      ),
      Teacher(
        idgv: 'GV002',
        fullname: 'Trần Thị Bình',
        image: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        sumClass: 8,
      ),
      Teacher(
        idgv: 'GV003',
        fullname: 'Lê Minh Châu',
        image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        sumClass: 3,
      ),
      Teacher(
        idgv: 'GV004',
        fullname: 'Phạm Quốc Dũng',
        image: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        sumClass: 12,
      ),
      Teacher(
        idgv: 'GV005',
        fullname: 'Hoàng Thị Em',
        image: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        sumClass: 6,
      ),
    ];
    var inserted = 0;
    for (final sample in samples) {
      final exists = useFirebase
          ? (await _collection.doc(sample.idgv).get()).exists
          : _demoTeachers.any((item) => item.idgv == sample.idgv);
      if (exists) continue;
      await save(sample, null, isNew: true, imageMimeType: 'image/jpeg');
      inserted++;
    }
    return inserted;
  }

  /// Nạp hàng loạt giảng viên từ file CSV / JSON (chức năng Import).
  /// Trả về số lượng giảng viên đã được lưu thành công.
  Future<int> importBatch(List<Teacher> teachers) async {
    if (teachers.isEmpty) return 0;
    var count = 0;
    for (final teacher in teachers) {
      final exists = useFirebase
          ? (await _collection.doc(teacher.idgv).get()).exists
          : _demoTeachers.any((item) => item.idgv == teacher.idgv);

      await save(
        teacher,
        null,
        isNew: !exists,
        imageMimeType: 'image/jpeg',
      );
      count++;
    }
    return count;
  }

  /// Chuỗi JSON 4 trường — dùng cho nút "Xuất JSON" và file nộp bài.
  String exportJson(List<Teacher> teachers) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(teachers.map((teacher) => teacher.toMap()).toList());
  }



  List<Teacher> _sortedDemo() {
    final teachers = List<Teacher>.of(_demoTeachers)
      ..sort((a, b) => a.idgv.compareTo(b.idgv));
    return teachers;
  }

  Future<void> _saveDemo(
    Teacher teacher,
    Uint8List? imageBytes, {
    required bool isNew,
    required String imageMimeType,
  }) async {
    var imageUrl = teacher.image;
    if (imageBytes != null) {
      final compressed = await Teacher.compressAvatar(imageBytes);
      imageUrl = 'data:image/png;base64,${base64Encode(compressed)}';
    }
    final index = _demoTeachers.indexWhere((item) => item.idgv == teacher.idgv);
    if (isNew && index != -1) {
      throw TeacherException(
        'Mã giảng viên ${teacher.idgv} đã tồn tại trong hệ thống.',
      );
    }
    final saved = Teacher(
      idgv: teacher.idgv,
      fullname: teacher.fullname,
      image: imageUrl,
      sumClass: teacher.sumClass,
    );
    if (index == -1) {
      _demoTeachers.add(saved);
    } else {
      _demoTeachers[index] = saved;
    }
    _notifyDemoChanged();
  }

  String _friendlyFirestoreError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Tài khoản không có quyền truy cập collection GiangVien. '
              'Hãy kiểm tra Firestore Rules.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Không có kết nối tới Firebase. Vui lòng thử lại.';
        case 'not-found':
          return 'Collection GiangVien chưa tồn tại. Hãy tạo collection trong Firestore.';
        case 'unauthenticated':
          return 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.';
        case 'canceled':
          return 'Yêu cầu đã bị hủy.';
        case 'storage/unauthorized':
          return 'Không có quyền tải ảnh lên Firebase Storage.';
        default:
          return error.message ?? 'Lỗi Firebase (${error.code}).';
      }
    }
    return '$error';
  }
}
