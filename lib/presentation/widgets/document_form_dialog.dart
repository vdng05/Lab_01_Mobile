import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../domain/entities/study_document.dart';

class DocumentFormValues {
  const DocumentFormValues({
    required this.title,
    required this.course,
    required this.category,
    required this.description,
    required this.link,
    required this.author,
    required this.semester,
    required this.tags,
    required this.attachmentSourcePath,
    required this.attachmentFileName,
  });

  final String title;
  final String course;
  final DocumentCategory category;
  final String description;
  final String link;
  final String author;
  final String semester;
  final List<String> tags;
  final String? attachmentSourcePath;
  final String? attachmentFileName;
}

class DocumentFormDialog extends StatefulWidget {
  const DocumentFormDialog({super.key, required this.onSave, this.document});

  final StudyDocument? document;
  final Future<bool> Function(DocumentFormValues values) onSave;

  @override
  State<DocumentFormDialog> createState() => _DocumentFormDialogState();
}

class _DocumentFormDialogState extends State<DocumentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.document?.title ?? '');
  late final _course = TextEditingController(
    text: widget.document?.course ?? '',
  );
  late final _description = TextEditingController(
    text: widget.document?.description ?? '',
  );
  late final _link = TextEditingController(text: widget.document?.link ?? '');
  late final _author = TextEditingController(
    text: widget.document?.author ?? '',
  );
  late final _semester = TextEditingController(
    text: widget.document?.semester ?? '',
  );
  late final _tags = TextEditingController(
    text: widget.document?.tags.join(', ') ?? '',
  );
  late DocumentCategory _category =
      widget.document?.category ?? DocumentCategory.lesson;
  bool _saving = false;
  String? _error;
  String? _pickedFilePath;
  String? _pickedFileName;

  @override
  void dispose() {
    _title.dispose();
    _course.dispose();
    _description.dispose();
    _link.dispose();
    _author.dispose();
    _semester.dispose();
    _tags.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.document == null ? 'Tài liệu mới' : 'Sửa tài liệu'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('titleInput'),
                controller: _title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Tên tài liệu *'),
                validator: _required('Nhập tên tài liệu.'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('courseInput'),
                controller: _course,
                decoration: const InputDecoration(labelText: 'Môn học *'),
                validator: _required('Nhập tên môn học.'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DocumentCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Loại tài liệu'),
                items: DocumentCategory.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _author,
                decoration: const InputDecoration(
                  labelText: 'Giảng viên / tác giả',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _semester,
                decoration: const InputDecoration(
                  labelText: 'Học kỳ / năm học',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Từ khóa',
                  hintText: 'Ví dụ: chương 1, ôn thi',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _link,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Liên kết (không bắt buộc)',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('pickDocumentFile'),
                  onPressed: _saving ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Chọn file từ thiết bị'),
                ),
              ),
              if (_pickedFileName != null ||
                  (widget.document?.attachmentName.isNotEmpty ?? false))
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'File: ${_pickedFileName ?? widget.document!.attachmentName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Color(0xFF9C3025))),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check, size: 18),
        label: Text(widget.document == null ? 'Thêm vào kho' : 'Lưu thay đổi'),
      ),
    ],
  );

  FormFieldValidator<String> _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'png',
          'jpg',
          'jpeg',
        ],
      );
      if (result.isEmpty || !mounted) return;
      final file = result.single;
      if (file.path == null) {
        setState(
          () => _error = 'Nền tảng này không cung cấp đường dẫn file cục bộ.',
        );
        return;
      }
      setState(() {
        _pickedFilePath = file.path;
        _pickedFileName = file.name;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể chọn file này.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(
      DocumentFormValues(
        title: _title.text,
        course: _course.text,
        category: _category,
        description: _description.text,
        link: _link.text,
        author: _author.text,
        semester: _semester.text,
        tags: _tags.text.split(',').map((tag) => tag.trim()).toList(),
        attachmentSourcePath: _pickedFilePath,
        attachmentFileName: _pickedFileName,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = 'Không thể lưu tài liệu. Vui lòng thử lại.';
      });
    }
  }
}
