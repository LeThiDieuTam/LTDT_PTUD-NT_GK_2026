import 'dart:convert';
import 'package:csv/csv.dart';
import '../models/teacher.dart';

/// Kết quả phân tích tệp import CSV/JSON.
class ImportParseResult {
  const ImportParseResult({
    required this.teachers,
    required this.errors,
    required this.totalProcessed,
  });

  final List<Teacher> teachers;
  final List<String> errors;
  final int totalProcessed;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasValidTeachers => teachers.isNotEmpty;
}

/// Dịch vụ nhập dữ liệu hàng loạt từ chuỗi CSV hoặc JSON.
abstract final class TeacherImporter {
  /// Phân tích dữ liệu văn bản thành danh sách Teacher.
  static ImportParseResult parse(String rawContent) {
    final text = rawContent.trim();
    if (text.isEmpty) {
      return const ImportParseResult(
        teachers: [],
        errors: ['Nội dung trống, không có dữ liệu để nhập.'],
        totalProcessed: 0,
      );
    }

    if (text.startsWith('[') || text.startsWith('{')) {
      return _parseJson(text);
    }

    return _parseCsv(text);
  }

  static ImportParseResult _parseJson(String text) {
    final teachers = <Teacher>[];
    final errors = <String>[];
    var count = 0;

    try {
      final decoded = jsonDecode(text);
      final list = decoded is List ? decoded : [decoded];
      for (var i = 0; i < list.length; i++) {
        count++;
        final item = list[i];
        if (item is! Map) {
          errors.add('Mục #${i + 1}: Định dạng không phải đối tượng JSON.');
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        final idgv = '${map['IDGV'] ?? map['idgv'] ?? map['id'] ?? ''}'.trim();
        final fullname =
            '${map['Fullname'] ?? map['fullname'] ?? map['name'] ?? ''}'
                .trim();
        final image = '${map['Image'] ?? map['image'] ?? ''}'.trim();
        final rawSum =
            map['SumClass'] ?? map['sumClass'] ?? map['classes'] ?? 0;
        final sumClass = rawSum is num
            ? rawSum.toInt()
            : (int.tryParse('$rawSum') ?? 0);

        if (idgv.isEmpty) {
          errors.add('Mục #${i + 1}: Thiếu mã giảng viên (IDGV).');
          continue;
        }
        if (idgv.contains('/')) {
          errors.add(
            'Mục #${i + 1}: Mã giảng viên "$idgv" không được chứa dấu "/".',
          );
          continue;
        }
        if (fullname.isEmpty) {
          errors.add('Mục #${i + 1}: Thiếu họ và tên (Fullname).');
          continue;
        }

        teachers.add(
          Teacher(
            idgv: idgv,
            fullname: fullname,
            image: image,
            sumClass: sumClass < 0 ? 0 : sumClass,
          ),
        );
      }
    } catch (e) {
      errors.add('Lỗi cú pháp JSON: $e');
    }

    return ImportParseResult(
      teachers: teachers,
      errors: errors,
      totalProcessed: count,
    );
  }

  static ImportParseResult _parseCsv(String text) {
    final teachers = <Teacher>[];
    final errors = <String>[];
    var count = 0;

    try {
      var clean = text;
      if (clean.startsWith('\uFEFF')) {
        clean = clean.substring(1);
      }

      // Chuẩn hóa ký tự xuống dòng
      clean = clean.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(clean);

      if (rows.isEmpty) {
        return const ImportParseResult(
          teachers: [],
          errors: ['Tệp CSV không có dữ liệu.'],
          totalProcessed: 0,
        );
      }

      var idIndex = 0;
      var nameIndex = 1;
      var imageIndex = 2;
      var classIndex = 3;

      var startIndex = 0;
      final header = rows.first.map((e) => '$e'.trim().toLowerCase()).toList();
      final hasHeader = header.any(
        (col) =>
            col.contains('idgv') ||
            col.contains('id') ||
            col.contains('mã') ||
            col.contains('fullname') ||
            col.contains('tên'),
      );

      if (hasHeader) {
        startIndex = 1;
        for (var c = 0; c < header.length; c++) {
          final h = header[c];
          if (h.contains('idgv') || h.contains('mã')) {
            idIndex = c;
          } else if (h.contains('fullname') ||
              h.contains('tên') ||
              h.contains('name')) {
            nameIndex = c;
          } else if (h.contains('image') || h.contains('ảnh')) {
            imageIndex = c;
          } else if (h.contains('sumclass') ||
              h.contains('lớp') ||
              h.contains('class')) {
            classIndex = c;
          }
        }
      }

      for (var r = startIndex; r < rows.length; r++) {
        final row = rows[r];
        if (row.isEmpty || (row.length == 1 && '${row[0]}'.trim().isEmpty)) {
          continue;
        }
        count++;

        final idgv = idIndex < row.length ? '${row[idIndex]}'.trim() : '';
        final fullname =
            nameIndex < row.length ? '${row[nameIndex]}'.trim() : '';
        final image = imageIndex < row.length ? '${row[imageIndex]}'.trim() : '';
        final classStr =
            classIndex < row.length ? '${row[classIndex]}'.trim() : '0';
        final sumClass = int.tryParse(classStr) ?? 0;

        if (idgv.isEmpty) {
          errors.add('Dòng #${r + 1}: Thiếu mã giảng viên.');
          continue;
        }
        if (idgv.contains('/')) {
          errors.add('Dòng #${r + 1}: Mã "$idgv" chứa ký tự cấm "/".');
          continue;
        }
        if (fullname.isEmpty) {
          errors.add('Dòng #${r + 1}: Thiếu họ tên giảng viên.');
          continue;
        }

        teachers.add(
          Teacher(
            idgv: idgv,
            fullname: fullname,
            image: image,
            sumClass: sumClass < 0 ? 0 : sumClass,
          ),
        );
      }
    } catch (e) {
      errors.add('Lỗi định dạng CSV: $e');
    }

    return ImportParseResult(
      teachers: teachers,
      errors: errors,
      totalProcessed: count,
    );
  }

  /// Chuỗi dữ liệu mẫu để người dùng thử nghiệm nhanh.
  static const String sampleCsv = '''IDGV,Fullname,Image,SumClass
GV006,Võ Thị Kim Phượng,https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150,7
GV007,Phan Thanh Tùng,https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150,11
GV008,Bùi Đức Thắng,https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150,4
GV009,Đỗ Ngọc Mai,https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150,9
GV010,Dương Gia Huy,https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150,2''';
}
