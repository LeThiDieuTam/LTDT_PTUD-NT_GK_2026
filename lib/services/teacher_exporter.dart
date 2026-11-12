import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../models/teacher.dart';

/// Xuất dữ liệu ra file CSV/JSON.
///
/// Trên web: file được tải xuống thư mục Download trình duyệt.
/// Trên mobile/desktop: file được lưu qua hộp thoại của hệ điều hành.
abstract final class TeacherExporter {
  static const List<String> columns = ['IDGV', 'Fullname', 'Image', 'SumClass'];

  static String toCsv(List<Teacher> teachers) {
    // BOM để Excel mở đúng tiếng Việt (UTF-8).
    return '\uFEFF${const ListToCsvConverter().convert([
      columns,
      ...teachers.map((teacher) => [teacher.idgv, teacher.fullname, teacher.image, teacher.sumClass]),
    ])}';
  }

  static String toJson(List<Teacher> teachers) {
    return const JsonEncoder.withIndent('  ')
        .convert(teachers.map((teacher) => teacher.toMap()).toList());
  }

  static String fileName(String extension) {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'giangvien_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.$extension';
  }

  /// Trả về true nếu lưu file thành công.
  static Future<bool> saveCsv(BuildContext context, List<Teacher> teachers) {
    return _save(
      context,
      fileName: fileName('csv'),
      content: toCsv(teachers),
      mimeType: MimeType.csv,
    );
  }

  static Future<bool> saveJson(BuildContext context, List<Teacher> teachers) {
    return _save(
      context,
      fileName: fileName('json'),
      content: toJson(teachers),
      mimeType: MimeType.json,
    );
  }

  static Future<bool> _save(
    BuildContext context, {
    required String fileName,
    required String content,
    required MimeType mimeType,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final extension = fileName.split('.').last;
      await FileSaver.instance.saveFile(
        name: fileName.substring(0, fileName.length - extension.length - 1),
        bytes: bytes,
        fileExtension: extension,
        mimeType: mimeType,
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Đã xuất file $fileName')));
      return true;
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Không xuất được file: $error')));
      return false;
    }
  }

  static IconData iconFor(String extension) => extension == 'json'
      ? Icons.data_object_rounded
      : Icons.table_view_rounded;
}
