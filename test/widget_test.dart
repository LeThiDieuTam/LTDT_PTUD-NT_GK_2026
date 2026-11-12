import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:giang_vien_admin/main.dart';
import 'package:giang_vien_admin/models/teacher.dart';
import 'package:giang_vien_admin/screens/teacher_dashboard.dart';
import 'package:giang_vien_admin/services/teacher_exporter.dart';
import 'package:giang_vien_admin/services/teacher_importer.dart';
import 'package:giang_vien_admin/services/teacher_service.dart';
import 'package:giang_vien_admin/theme/app_theme.dart';

void main() {
  group('Teacher model', () {
    test('map đúng 4 trường bắt buộc của đề bài', () {
      const teacher = Teacher(
        idgv: 'GV009',
        fullname: 'Nguyễn Thị Hương',
        image: 'https://example.com/a.jpg',
        sumClass: 7,
      );
      expect(teacher.toMap().keys.toList(), [
        'IDGV',
        'Fullname',
        'Image',
        'SumClass',
      ]);
    });

    test('fromMap chấp nhận SumClass dạng chuỗi (dữ liệu import json)', () {
      final teacher = Teacher.fromMap({
        'IDGV': ' GV010 ',
        'Fullname': ' Trần Văn Khoa ',
        'Image': null,
        'SumClass': '4',
      });
      expect(teacher.idgv, 'GV010');
      expect(teacher.fullname, 'Trần Văn Khoa');
      expect(teacher.image, '');
      expect(teacher.sumClass, 4);
      expect(teacher.initials, 'TK');
    });
  });

  group('TeacherService (demo)', () {
    test('realtime stream phát dữ liệu mới khi thêm giảng viên', () async {
      final service = TeacherService(useFirebase: false);
      final emissions = <List<Teacher>>[];
      final subscription = service.watchAll().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);
      final initialCount = emissions.length;
      expect(emissions.last, isNotEmpty);

      const teacher = Teacher(
        idgv: 'DEMO-RT-1',
        fullname: 'Giảng viên Realtime',
        image: '',
        sumClass: 1,
      );
      await service.save(
        teacher,
        null,
        isNew: true,
        imageMimeType: 'image/jpeg',
      );
      await Future<void>.delayed(Duration.zero);
      expect(emissions.length, initialCount + 1);
      expect(emissions.last.any((item) => item.idgv == teacher.idgv), isTrue);

      await service.delete(teacher);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.any((item) => item.idgv == teacher.idgv), isFalse);
      await subscription.cancel();
    });

    test('chặn mã giảng viên trùng khi thêm mới', () async {
      final service = TeacherService(useFirebase: false);
      const teacher = Teacher(
        idgv: 'DEMO-DUP',
        fullname: 'Trùng mã',
        image: '',
        sumClass: 2,
      );
      await service.save(
        teacher,
        null,
        isNew: true,
        imageMimeType: 'image/jpeg',
      );
      await expectLater(
        service.save(teacher, null, isNew: true, imageMimeType: 'image/jpeg'),
        throwsA(isA<TeacherException>()),
      );
      await service.delete(teacher);
    });
  });

  group('TeacherExporter', () {
    test('CSV có BOM UTF-8, header 4 trường và xuống dòng', () {
      const teacher = Teacher(
        idgv: 'GV100',
        fullname: 'Đặng Minh Khoa',
        image: '',
        sumClass: 9,
      );
      final csv = TeacherExporter.toCsv([teacher]);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('IDGV,Fullname,Image,SumClass'));
      expect(csv, contains('GV100,Đặng Minh Khoa,,9'));
    });

    test('JSON tương thích cấu trúc Firestore', () {
      const teacher = Teacher(
        idgv: 'GV101',
        fullname: 'Lý Thị Mai',
        image: 'https://example.com/x.jpg',
        sumClass: 3,
      );
      final decoded =
          jsonDecode(TeacherExporter.toJson([teacher])) as List<dynamic>;
      final map = decoded.single as Map<String, dynamic>;
      expect(map, {
        'IDGV': 'GV101',
        'Fullname': 'Lý Thị Mai',
        'Image': 'https://example.com/x.jpg',
        'SumClass': 3,
      });
    });
  });

  group('TeacherImporter', () {
    test('phân tích CSV chuẩn thành danh sách Teacher', () {
      const csv = '''IDGV,Fullname,Image,SumClass
GV201,Phạm Văn Nam,https://img.com/1.jpg,5
GV202,Trương Thị Lan,,8''';
      final result = TeacherImporter.parse(csv);
      expect(result.errors, isEmpty);
      expect(result.teachers.length, 2);
      expect(result.teachers.first.idgv, 'GV201');
      expect(result.teachers.first.fullname, 'Phạm Văn Nam');
      expect(result.teachers.first.sumClass, 5);
      expect(result.teachers.last.idgv, 'GV202');
      expect(result.teachers.last.sumClass, 8);
    });

    test('phân tích JSON chuẩn thành danh sách Teacher', () {
      const json = '''[
        {"IDGV": "GV203", "Fullname": "Đặng Quốc Việt", "Image": "", "SumClass": 10}
      ]''';
      final result = TeacherImporter.parse(json);
      expect(result.errors, isEmpty);
      expect(result.teachers.length, 1);
      expect(result.teachers.single.idgv, 'GV203');
      expect(result.teachers.single.fullname, 'Đặng Quốc Việt');
      expect(result.teachers.single.sumClass, 10);
    });

    test('bắt lỗi khi thiếu IDGV hoặc Fullname trong CSV', () {
      const invalidCsv = '''IDGV,Fullname,Image,SumClass
,Chưa có mã,,3
GV204,,,4''';
      final result = TeacherImporter.parse(invalidCsv);
      expect(result.hasErrors, isTrue);
      expect(result.errors.length, 2);
    });
  });

  testWidgets('dashboard demo hiển thị thống kê và danh sách giảng viên', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: TeacherDashboard(service: TeacherService(useFirebase: false)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Xin chào, Quản trị viên 👋'), findsOneWidget);
    expect(find.text('Tổng giảng viên'), findsOneWidget);
    expect(find.text('Giảng viên nổi bật'), findsOneWidget);
    expect(find.text('Chế độ demo'), findsOneWidget);
    expect(find.text('Hiển thị 3 / 3 giảng viên'), findsOneWidget);

    // Tìm kiếm theo tên: danh sách chỉ còn đúng 1 giảng viên.
    await tester.enterText(find.byType(TextField).first, 'Bình');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hiển thị 1 / 3 giảng viên'), findsOneWidget);

    // Không có kết quả → hiện trạng thái rỗng.
    await tester.enterText(find.byType(TextField).first, 'khongtontai');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hiển thị 0 / 3 giảng viên'), findsOneWidget);
  });

  testWidgets('chế độ demo của app mở thẳng dashboard', (tester) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GiangVienApp(useFirebase: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('QLHocPhan'), findsOneWidget);
    expect(find.text('Quản lý giảng viên'), findsWidgets);
  });

  testWidgets('app hiển thị lỗi Firebase thay vì chạy demo khi khởi tạo lỗi', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GiangVienApp(
        useFirebase: false,
        initError: 'Firebase config is missing',
      ),
    );

    expect(find.text('Không thể khởi tạo Firebase'), findsOneWidget);
    expect(find.text('Firebase config is missing'), findsOneWidget);
    expect(find.text('Quản trị viên (demo)'), findsNothing);
  });
}
