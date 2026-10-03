import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/study_document.dart';

abstract interface class LocalDocumentDataSource {
  Future<List<StudyDocument>> readDocuments();
  Future<void> writeDocuments(List<StudyDocument> documents);
}

class SharedPreferencesDocumentDataSource implements LocalDocumentDataSource {
  SharedPreferencesDocumentDataSource({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  // Đã đổi khóa thành v2 để ép app tải lại dữ liệu mẫu
  static const _storageKey = 'study_documents_v2';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<StudyDocument>> readDocuments() async {
    final content = await _preferences.getString(_storageKey);
    if (content == null) {
      await writeDocuments(_sampleDocuments);
      return List.of(_sampleDocuments);
    }
    if (content.isEmpty) return [];
    final records = jsonDecode(content) as List<Object?>;
    return records
        .cast<Map<String, Object?>>()
        .map(StudyDocument.fromJson)
        .toList();
  }

  @override
  Future<void> writeDocuments(List<StudyDocument> documents) async {
    final content = jsonEncode(
      documents.map((document) => document.toJson()).toList(),
    );
    await _preferences.setString(_storageKey, content);
  }

  static final _sampleDocuments = <StudyDocument>[
    _sample(
      'lesson-01',
      'Ma trận và định thức',
      'Đại số tuyến tính',
      DocumentCategory.lesson,
      'Bài giảng về phép toán ma trận, định thức và ứng dụng.',
    ),
    _sample(
      'lesson-02',
      'Widgets cơ bản trong Flutter',
      'Lập trình di động',
      DocumentCategory.lesson,
      'Tổng quan StatelessWidget, StatefulWidget và bố cục.',
    ),
    _sample(
      'lesson-03',
      'Mô hình thực thể liên kết',
      'Cơ sở dữ liệu',
      DocumentCategory.lesson,
      'Bài giảng thiết kế ERD và chuyển sang mô hình quan hệ.',
    ),
    _sample(
      'lesson-04',
      'Phân lớp trong kiến trúc phần mềm',
      'Kiến trúc phần mềm',
      DocumentCategory.lesson,
      'Tổng quan presentation, application, domain và data.',
    ),
    _sample(
      'lesson-05',
      'Biến ngẫu nhiên và phân phối',
      'Xác suất thống kê',
      DocumentCategory.lesson,
      'Các phân phối thường gặp và kỳ vọng toán học.',
    ),
    _sample(
      'assignment-01',
      'Bài tập hệ phương trình tuyến tính',
      'Đại số tuyến tính',
      DocumentCategory.assignment,
      'Bài tập luyện khử Gauss và tìm hạng ma trận.',
    ),
    _sample(
      'assignment-02',
      'Ứng dụng danh sách công việc',
      'Lập trình di động',
      DocumentCategory.assignment,
      'Thực hành form, danh sách và quản lý trạng thái.',
    ),
    _sample(
      'assignment-03',
      'Thiết kế cơ sở dữ liệu thư viện',
      'Cơ sở dữ liệu',
      DocumentCategory.assignment,
      'Vẽ ERD và chuẩn hóa các bảng dữ liệu.',
    ),
    _sample(
      'assignment-04',
      'Tách lớp ứng dụng quản lý tài liệu',
      'Kiến trúc phần mềm',
      DocumentCategory.assignment,
      'Xây dựng use case và repository có thể kiểm thử.',
    ),
    _sample(
      'assignment-05',
      'Bài tập xác suất có điều kiện',
      'Xác suất thống kê',
      DocumentCategory.assignment,
      'Giải bài tập Bayes và xác suất toàn phần.',
    ),
    _sample(
      'reference-01',
      'Tóm tắt công thức đại số tuyến tính',
      'Đại số tuyến tính',
      DocumentCategory.reference,
      'Bảng công thức ma trận, định thức và trị riêng.',
    ),
    _sample(
      'reference-02',
      'Flutter Widget Catalog',
      'Lập trình di động',
      DocumentCategory.reference,
      'Tài liệu tra cứu widget và thành phần giao diện Flutter.',
    ),
    _sample(
      'reference-03',
      'SQL cơ bản và truy vấn mẫu',
      'Cơ sở dữ liệu',
      DocumentCategory.reference,
      'Tổng hợp cú pháp SQL thường dùng và ví dụ.',
    ),
    _sample(
      'reference-04',
      'Clean Architecture Notes',
      'Kiến trúc phần mềm',
      DocumentCategory.reference,
      'Ghi chú về dependency rule và kiểm thử độc lập.',
    ),
    _sample(
      'reference-05',
      'Bảng phân phối xác suất',
      'Xác suất thống kê',
      DocumentCategory.reference,
      'Bảng tra phân phối nhị thức, chuẩn và Poisson.',
    ),
  ];

  static StudyDocument _sample(
    String id,
    String title,
    String course,
    DocumentCategory category,
    String description,
  ) => StudyDocument(
    id: 'sample-$id',
    title: title,
    course: course,
    category: category,
    description: description,
    link: '',
    updatedAt: DateTime.utc(
      2026,
      9,
      1,
    ).add(Duration(days: int.parse(id.split('-').last))),
    author: 'Bộ môn $course',
    semester: 'HK1 2026-2027',
    tags: [course, category.label],
  );
}
