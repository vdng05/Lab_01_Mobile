import 'package:flutter/material.dart';

import '../../application/study_document_controller.dart';
import '../../domain/entities/study_document.dart';
import '../../domain/entities/study_user.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../widgets/document_form_dialog.dart';
import 'profile_page.dart';

class DocumentLibraryPage extends StatefulWidget {
  const DocumentLibraryPage({
    super.key,
    required this.controller,
    this.user,
    this.authenticationRepository,
    this.cloudEnabled = true,
  });

  final StudyDocumentController controller;
  final StudyUser? user;
  final AuthenticationRepository? authenticationRepository;
  final bool cloudEnabled;
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
            Icon(Icons.local_library_outlined, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Text(
              'Study Library',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.authenticationRepository != null) _buildAccountAction(),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070D1E),
              Color(0xFF0B132B),
              Color(0xFF131D2E),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 100),
                children: [
                  _buildHeading(controller),
                  if (!widget.cloudEnabled &&
                      widget.authenticationRepository != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Text(
                        'Đang dùng dữ liệu cục bộ. Đăng nhập Google và trang cá nhân đã bật; cấu hình Supabase để đồng bộ và chia sẻ tài liệu.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
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
    ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(
            'Thêm tài liệu',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
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
            color: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${controller.documents.length} tài liệu đang được lưu',
          style: const TextStyle(color: Color(0xFF94A3B8)),
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

  Widget _buildAccountAction() {
    final user = widget.user;
    if (user == null) {
      return IconButton(
        key: const Key('googleSignInButton'),
        tooltip: 'Đăng nhập bằng Google',
        onPressed: _signIn,
        icon: const Icon(Icons.login),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('openProfile'),
          tooltip: 'Thông tin cá nhân (${user.email})',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProfilePage(
                user: user,
                authenticationRepository: widget.authenticationRepository!,
                statusMessage: widget.cloudEnabled
                    ? null
                    : 'Hồ sơ đăng nhập Firebase đã sẵn sàng. Dữ liệu tài liệu vẫn đang lưu trên thiết bị cho đến khi cấu hình Supabase.',
              ),
            ),
          ),
          icon: CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFF0F2644),
            foregroundImage: user.photoUrl.isEmpty ? null : NetworkImage(user.photoUrl),
            child: Text(
              user.displayName.isEmpty
                  ? '?'
                  : user.displayName.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          key: const Key('signOutHeaderButton'),
          tooltip: 'Đăng xuất (${user.email})',
          icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
          onPressed: _confirmSignOut,
        ),
      ],
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản ${widget.user?.email ?? ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC93B2B),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await widget.authenticationRepository?.signOut();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

  Future<void> _signIn() async {
    try {
      await widget.authenticationRepository!.signInWithGoogle();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập Google chưa thành công. Kiểm tra cấu hình Firebase.'),
        ),
      );
    }
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
        style: SegmentedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          selectedBackgroundColor: const Color(0xFF0284C7),
          foregroundColor: const Color(0xFF94A3B8),
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF334155)),
        ),
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
      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFFFCA5A5))),
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
            size: 44,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'Không tìm thấy tài liệu' : 'Chưa có tài liệu nào',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasFilter
                ? 'Thử từ khóa hoặc bộ lọc khác.'
                : 'Thêm bài giảng, bài tập hoặc tài liệu tham khảo đầu tiên.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8)),
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
                attachmentBytes: values.attachmentBytes,
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
                attachmentBytes: values.attachmentBytes,
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
        if (widget.cloudEnabled && document.isOwner)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareDocument(document);
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Chia sẻ'),
          ),
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

  Future<void> _shareDocument(StudyDocument document) async {
    final emailController = TextEditingController();
    var accessLevel = DocumentAccessLevel.view;
    final selection = await showDialog<DocumentAccessLevel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chia sẻ tài liệu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('shareEmailInput'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email người nhận',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DocumentAccessLevel>(
                initialValue: accessLevel,
                decoration: const InputDecoration(labelText: 'Quyền truy cập'),
                items: const [
                  DropdownMenuItem(
                    value: DocumentAccessLevel.view,
                    child: Text('Chỉ xem'),
                  ),
                  DropdownMenuItem(
                    value: DocumentAccessLevel.edit,
                    child: Text('Xem và chỉnh sửa'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => accessLevel = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, accessLevel),
              child: const Text('Chia sẻ'),
            ),
          ],
        ),
      ),
    );
    final email = emailController.text.trim();
    emailController.dispose();
    if (selection == null || email.isEmpty || !mounted) return;

    final sharedUser = await widget.controller.shareDocument(
      documentId: document.id,
      email: email,
      accessLevel: selection,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sharedUser == null
              ? widget.controller.errorMessage ?? 'Không thể chia sẻ tài liệu.'
              : 'Đã chia sẻ với ${sharedUser.email} (${selection == DocumentAccessLevel.view ? 'chỉ xem' : 'có thể sửa'}).',
        ),
      ),
    );
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E293B), Color(0xFF162032)],
      ),
      border: Border.all(color: const Color(0xFF334155)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFFF8FAFC),
          ),
        ),
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
    final (accentColor, gradientColors) = switch (document.category) {
      DocumentCategory.lesson => (
        const Color(0xFF38BDF8),
        [
          const Color(0xFF0284C7).withValues(alpha: 0.25),
          const Color(0xFF06B6D4).withValues(alpha: 0.08),
        ],
      ),
      DocumentCategory.assignment => (
        const Color(0xFFFBBF24),
        [
          const Color(0xFFF59E0B).withValues(alpha: 0.25),
          const Color(0xFFD97706).withValues(alpha: 0.08),
        ],
      ),
      DocumentCategory.reference => (
        const Color(0xFFA5B4FC),
        [
          const Color(0xFF6366F1).withValues(alpha: 0.25),
          const Color(0xFF4F46E5).withValues(alpha: 0.08),
        ],
      ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF141F32),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(Icons.description_outlined, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${document.course}  ·  ${document.category.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: accentColor.withValues(alpha: 0.9),
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
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xem chi tiết',
                  onPressed: onView,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                if (document.canEdit)
                  IconButton(
                    tooltip: 'Sửa tài liệu',
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                if (document.isOwner)
                  IconButton(
                    tooltip: 'Xóa tài liệu',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Color(0xFFF87171),
                    ),
                  ),
              ],
            ),
          ),
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
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: const TextStyle(color: Color(0xFFF8FAFC)),
        ),
      ],
    ),
  );
}
