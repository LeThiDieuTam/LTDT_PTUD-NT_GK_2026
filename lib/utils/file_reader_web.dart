import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Đọc tệp text (.csv, .json) trực tiếp trên Web mà không cần package ngoài.
Future<String?> pickAndReadTextFile() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = '.csv,.json,text/csv,application/json';
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsText(files[0]);
    reader.onLoadEnd.listen((_) {
      completer.complete(reader.result as String?);
    });
    reader.onError.listen((_) {
      completer.complete(null);
    });
  });

  return completer.future;
}
