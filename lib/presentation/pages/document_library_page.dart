import 'package:flutter/material.dart';

import '../../application/study_document_controller.dart';
import '../../domain/entities/study_document.dart';
import '../widgets/document_form_dialog.dart';

class DocumentLibraryPage extends StatefulWidget {
  const DocumentLibraryPage({super.key, required this.controller});

  final StudyDocumentController controller;

  @override
  State<DocumentLibraryPage> createState() => _DocumentLibraryPageState();
}

class _DocumentLibraryPageState extends State<DocumentLibraryPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 22,
        title: const Row(
          children: [
            Icon(Icons.local_library_outlined, color: Color(0xFF176B52)),
            SizedBox(width: 10),
            Text(
              'Cashew Study Library',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 100),
              children: [
                _buildHeading(controller),
                const SizedBox(height: 22),
                TextField(
                  key: const Key('documentSearch'),
                  controller: _searchController,
                  onChanged: controller.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên tài liệu, môn học...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () {
                              _searchController.clear();
                              controller.setQuery('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilters(controller),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildError(controller.errorMessage!),
                ],
                const SizedBox(height: 18),
                if (controller.isLoading && controller.documents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.visibleDocuments.isEmpty)
                  _buildEmptyState(controller)
                else
                  ...controller.visibleDocuments.map(
                    (document) => _DocumentTile(
                      document: document,
                      onView: () => _showDetails(document),
                      onEdit: () => _openForm(document: document),
                      onDelete: () => _confirmDelete(document),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF176B52),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm tài liệu'),
      ),
    );
  }

  Widget _buildHeading(StudyDocumentController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kho học tập',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF17231E),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${controller.documents.length} tài liệu đang được lưu',
          style: const TextStyle(color: Color(0xFF68746D)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryChip(
              icon: Icons.menu_book_outlined,
              label: 'Bài giảng',
              count: controller.countFor(DocumentCategory.lesson),
            ),
            _SummaryChip(
              icon: Icons.edit_note_outlined,
              label: 'Bài tập',
              count: controller.countFor(DocumentCategory.assignment),
            ),
            _SummaryChip(
              icon: Icons.bookmark_border,
              label: 'Tham khảo',
              count: controller.countFor(DocumentCategory.reference),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(StudyDocumentController controller) {
    const categories = <DocumentCategory?>[
      null,
      DocumentCategory.lesson,
      DocumentCategory.assignment,
      DocumentCategory.reference,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<DocumentCategory?>(
        showSelectedIcon: false,
        segments: categories
            .map(
              (category) => ButtonSegment<DocumentCategory?>(
                value: category,
                label: Text(category?.label ?? 'Tất cả'),
              ),
            )
            .toList(),
        selected: {controller.category},
        onSelectionChanged: (selection) =>
            controller.setCategory(selection.first),
      ),
    );
  }

  Widget _buildError(String message) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE8E3),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFF8B2E1F))),
  );

  Widget _buildEmptyState(StudyDocumentController controller) {
    final hasFilter =
        controller.query.isNotEmpty || controller.category != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 58, horizontal: 22),
      child: Column(
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.folder_open_outlined,
            size: 42,
            color: const Color(0xFF829087),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'Không tìm thấy tài liệu' : 'Chưa có tài liệu nào',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            hasFilter
                ? 'Thử từ khóa hoặc bộ lọc khác.'
                : 'Thêm bài giảng, bài tập hoặc tài liệu tham khảo đầu tiên.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF68746D)),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({StudyDocument? document}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DocumentFormDialog(
        document: document,
        onSave: (values) => document == null
            ? widget.controller.addDocument(
                title: values.title,
                course: values.course,
                category: values.category,
                description: values.description,
                link: values.link,
                author: values.author,
                semester: values.semester,
                tags: values.tags,
                attachmentSourcePath: values.attachmentSourcePath,
                attachmentFileName: values.attachmentFileName,
              )
            : widget.controller.updateDocument(
                document.copyWith(
                  title: values.title,
                  course: values.course,
                  category: values.category,
                  description: values.description,
                  link: values.link,
                  author: values.author,
                  semester: values.semester,
                  tags: values.tags,
                ),
                attachmentSourcePath: values.attachmentSourcePath,
                attachmentFileName: values.attachmentFileName,
              ),
      ),
    );
  }

  Future<void> _showDetails(StudyDocument document) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(document.title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailField(label: 'Môn học', value: document.course),
              _DetailField(label: 'Danh mục', value: document.category.label),
              if (document.author.isNotEmpty)
                _DetailField(
                  label: 'Giảng viên / tác giả',
                  value: document.author,
                ),
              if (document.semester.isNotEmpty)
                _DetailField(
                  label: 'Học kỳ / năm học',
                  value: document.semester,
                ),
              if (document.description.isNotEmpty)
                _DetailField(label: 'Mô tả', value: document.description),
              if (document.link.isNotEmpty)
                _DetailField(label: 'Liên kết', value: document.link),
              if (document.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: document.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                ),
              _DetailField(
                label: 'File đính kèm',
                value: document.attachmentName.isEmpty
                    ? 'Chưa có file'
                    : '${document.attachmentName}\nĐã sao chép vào bộ nhớ của ứng dụng',
              ),
              if (document.attachmentPath.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('openDocumentAttachment'),
                    onPressed: () async {
                      final opened = await widget.controller.openAttachment(
                        document.attachmentPath,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            opened ? 'Đã mở file bằng ứng dụng mặc định.' : 'Không thể mở file. Kiểm tra file và ứng dụng hỗ trợ định dạng này.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Mở file đính kèm'),
                  ),
                ),
              _DetailField(
                label: 'Cập nhật',
                value: MaterialLocalizations.of(context)
                    .formatMediumDate(document.updatedAt),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );

  Future<void> _confirmDelete(StudyDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài liệu?'),
        content: Text('“${document.title}” sẽ bị xóa khỏi kho học tập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.deleteDocument(document.id);
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 124),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E6E1)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF176B52)),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 7),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final StudyDocument document;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (document.category) {
      DocumentCategory.lesson => const Color(0xFF176B52),
      DocumentCategory.assignment => const Color(0xFFB55B2A),
      DocumentCategory.reference => const Color(0xFF495E8A),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E6E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 13, 7, 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description_outlined, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${document.course}  ·  ${document.category.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF68746D),
                    ),
                  ),
                  if (document.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      document.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF68746D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Xem chi tiết',
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Sửa tài liệu',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Xóa tài liệu',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF68746D),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        SelectableText(value),
      ],
    ),
  );
}
