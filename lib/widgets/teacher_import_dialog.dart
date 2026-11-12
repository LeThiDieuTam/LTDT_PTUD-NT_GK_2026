import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../services/teacher_importer.dart';
import '../theme/app_theme.dart';
import '../utils/file_reader.dart';
import 'common.dart';

/// Hộp thoại nhập dữ liệu hàng loạt từ tệp CSV hoặc JSON.
class TeacherImportDialog extends StatefulWidget {
  const TeacherImportDialog({super.key});

  @override
  State<TeacherImportDialog> createState() => _TeacherImportDialogState();
}

class _TeacherImportDialogState extends State<TeacherImportDialog> {
  final _contentController = TextEditingController();
  ImportParseResult? _parseResult;
  bool _isLoadingFile = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() => _parseResult = null);
      return;
    }
    final result = TeacherImporter.parse(text);
    setState(() => _parseResult = result);
  }

  Future<void> _pickFile() async {
    setState(() => _isLoadingFile = true);
    try {
      final content = await pickAndReadTextFile();
      if (content != null && content.isNotEmpty) {
        _contentController.text = content;
        _onContentChanged(content);
      }
    } finally {
      if (mounted) setState(() => _isLoadingFile = false);
    }
  }

  void _useSampleData() {
    _contentController.text = TeacherImporter.sampleCsv;
    _onContentChanged(TeacherImporter.sampleCsv);
  }

  void _submit() {
    final teachers = _parseResult?.teachers ?? [];
    if (teachers.isEmpty) return;
    Navigator.pop(context, teachers);
  }

  @override
  Widget build(BuildContext context) {
    final result = _parseResult;
    final validTeachers = result?.teachers ?? <Teacher>[];

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhập danh sách giảng viên',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Hỗ trợ tệp định dạng CSV hoặc JSON (chuẩn 4 trường dữ liệu).',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Action Toolbar
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isLoadingFile ? null : _pickFile,
                    icon: _isLoadingFile
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Chọn tệp từ máy (.csv, .json)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _useSampleData,
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: const Text('Dán mẫu 5 GV thử nghiệm'),
                  ),
                  if (_contentController.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        _contentController.clear();
                        _onContentChanged('');
                      },
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: const Text('Xóa nội dung'),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Text Area
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  onChanged: _onContentChanged,
                  decoration: InputDecoration(
                    hintText:
                        'Dán nội dung CSV hoặc JSON vào đây...\nVí dụ CSV:\nIDGV,Fullname,Image,SumClass\nGV006,Võ Thị Kim Phượng,,7',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),

              // Preview Section
              if (result != null) ...[
                const SizedBox(height: 12),
                if (result.hasErrors) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(
                            alpha: 0.1,
                          ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withValues(
                              alpha: 0.3,
                            ),
                      ),
                    ),
                    child: Text(
                      'Có ${result.errors.length} lỗi:\n• ${result.errors.take(2).join('\n• ')}${result.errors.length > 2 ? '\n• ...' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: validTeachers.isNotEmpty
                          ? const Color(0xFF16A34A)
                          : context.mutedColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tìm thấy ${validTeachers.length} giảng viên hợp lệ sẵn sàng nạp.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: validTeachers.isNotEmpty
                            ? const Color(0xFF16A34A)
                            : context.mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.softFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.lineColor),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: validTeachers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = validTeachers[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: TeacherAvatar(teacher: t, size: 32),
                          title: Text(
                            t.fullname,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Mã: ${t.idgv} • ${t.sumClass} lớp phụ trách',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorForId(t.idgv).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.idgv,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colorForId(t.idgv),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              // Bottom Actions
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: validTeachers.isEmpty ? null : _submit,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text('Nạp ${validTeachers.length} giảng viên vào CSDL'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
