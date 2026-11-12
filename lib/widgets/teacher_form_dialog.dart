import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/teacher.dart';
import '../theme/app_theme.dart';

/// Kết quả form gửi về dashboard.
class TeacherFormResult {
  const TeacherFormResult(this.teacher, this.imageBytes, this.imageMimeType);

  final Teacher teacher;
  final Uint8List? imageBytes;
  final String imageMimeType;
}

/// Hộp thoại thêm/sửa giảng viên: chọn ảnh từ thư viện hoặc chụp ảnh,
/// validate IDGV (không trùng, không chứa "/"), SumClass là số nguyên >= 0.
class TeacherFormDialog extends StatefulWidget {
  const TeacherFormDialog({required this.teacher, super.key});

  final Teacher? teacher;

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _classController;
  late final TextEditingController _imageUrlController;
  final _imagePicker = ImagePicker();
  Uint8List? _imageBytes;
  String _imageMimeType = 'image/jpeg';
  String _existingImage = '';
  bool _isPickingImage = false;

  bool get _isEditing => widget.teacher != null;

  @override
  void initState() {
    super.initState();
    final teacher = widget.teacher;
    _idController = TextEditingController(text: teacher?.idgv ?? '');
    _nameController = TextEditingController(text: teacher?.fullname ?? '');
    _classController = TextEditingController(
      text: teacher == null ? '' : '${teacher.sumClass}',
    );
    _existingImage = teacher?.image ?? '';
    _imageUrlController = TextEditingController(
      text: (teacher?.image.startsWith('data:') ?? false) ? '' : (teacher?.image ?? ''),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPickingImage = true);
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file != null) {
        final rawBytes = await file.readAsBytes();
        final compressed = await Teacher.compressAvatar(rawBytes);
        if (mounted) {
          setState(() {
            _imageBytes = compressed;
            _imageMimeType = 'image/png';
            _imageUrlController.clear();
          });
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $error')));
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final finalImageUrl = _imageBytes != null
        ? _existingImage
        : _imageUrlController.text.trim();
    final teacher = Teacher(
      idgv: _idController.text.trim(),
      fullname: _nameController.text.trim(),
      image: finalImageUrl,
      sumClass: int.parse(_classController.text.trim()),
    );
    Navigator.pop(
      context,
      TeacherFormResult(teacher, _imageBytes, _imageMimeType),
    );
  }

  ImageProvider? get _previewImage {
    if (_imageBytes != null) return MemoryImage(_imageBytes!);
    final url = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : _existingImage;
    final decoded = Teacher.decodeDataImage(url);
    if (decoded != null) return MemoryImage(decoded);
    if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
      return NetworkImage(url);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preview = Teacher(
      idgv: _idController.text.trim().isEmpty
          ? 'GV'
          : _idController.text.trim(),
      fullname: _nameController.text.trim().isEmpty
          ? '?'
          : _nameController.text.trim(),
      image: '',
      sumClass: 0,
    );
    final imageProvider = _previewImage;

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditing
                              ? Icons.edit_note_rounded
                              : Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Cập nhật giảng viên'
                                  : 'Thêm giảng viên mới',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                            Text(
                              'Dữ liệu gồm 4 trường: IDGV, Fullname, Image, SumClass.',
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isPickingImage
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        child: SizedBox(
                          width: 92,
                          height: 92,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: imageProvider == null
                                      ? LinearGradient(
                                          colors: [
                                            colorForId(preview.idgv),
                                            Color.lerp(
                                              colorForId(preview.idgv),
                                              Colors.white,
                                              0.45,
                                            )!,
                                          ],
                                        )
                                      : null,
                                  image: imageProvider != null
                                      ? DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  border: Border.all(
                                    color: context.lineColor,
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: imageProvider == null
                                    ? Text(
                                        preview.initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 28,
                                        ),
                                      )
                                    : null,
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: _isPickingImage
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ảnh đại diện',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ảnh được tải lên Firebase Storage và lưu URL vào trường Image.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.mutedColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _isPickingImage
                                      ? null
                                      : () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Thư viện'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                  ),
                                ),
                                if (!kIsWeb)
                                  OutlinedButton.icon(
                                    onPressed: _isPickingImage
                                        ? null
                                        : () => _pickImage(ImageSource.camera),
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Chụp ảnh'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 36),
                                    ),
                                  )
                                  else
                                    const SizedBox.shrink(),
                                if (imageProvider != null)
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _imageBytes = null;
                                      _existingImage = '';
                                      _imageUrlController.clear();
                                    }),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                    ),
                                    label: const Text('Bỏ ảnh'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _idController,
                    enabled: !_isEditing,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Mã giảng viên (IDGV)',
                      hintText: 'Ví dụ: GV001',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      helperText: _isEditing
                          ? 'Không thể đổi mã vì IDGV là document ID.'
                          : 'Dùng làm document ID trên Firestore.',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Vui lòng nhập mã giảng viên.';
                      if (text.contains('/')) {
                        return 'Mã giảng viên không được chứa dấu "/".';
                      }
                      if (text.length > 32) {
                        return 'Mã giảng viên tối đa 32 ký tự.';
                      }
                      if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(text)) {
                        return 'Chỉ dùng chữ, số và . _ -';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên (Fullname)',
                      hintText: 'Nguyễn Văn A',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập họ và tên.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _classController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tổng số lớp (SumClass)',
                      hintText: '0',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    validator: (value) {
                      final number = int.tryParse(value?.trim() ?? '');
                      if (number == null || number < 0) {
                        return 'Nhập số nguyên không âm.';
                      }
                      if (number > 999) return 'Số lớp tối đa là 999.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {
                      _imageBytes = null;
                    }),
                    decoration: InputDecoration(
                      labelText: 'Đường dẫn ảnh (URL tùy chọn)',
                      hintText: 'https://... hoặc data:image/...',
                      prefixIcon: const Icon(Icons.link_rounded),
                      helperText: _imageBytes != null
                          ? 'Đang dùng ảnh tải lên từ máy.'
                          : 'Dán link ảnh trực tiếp hoặc chọn tệp ở trên.',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: Icon(
                            _isEditing ? Icons.save_rounded : Icons.add_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _isEditing ? 'Lưu thay đổi' : 'Thêm giảng viên',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog xác nhận xóa dạng "nguy hiểm" (đỏ).
Future<bool> showDeleteConfirmDialog(
  BuildContext context,
  Teacher teacher,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final error = Theme.of(context).colorScheme.error;
      return AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.delete_forever_rounded, color: error),
        ),
        title: const Text('Xóa giảng viên?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn sắp xóa "${teacher.fullname}" (${teacher.idgv}). '
              'Ảnh trên Storage cũng sẽ bị xóa. Thao tác không thể hoàn tác.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.mutedColor, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
