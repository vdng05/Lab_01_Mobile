enum DocumentCategory { lesson, assignment, reference }

extension DocumentCategoryLabel on DocumentCategory {
  String get label => switch (this) {
    DocumentCategory.lesson => 'Bài giảng',
    DocumentCategory.assignment => 'Bài tập',
    DocumentCategory.reference => 'Tham khảo',
  };
}

class StudyDocument {
  const StudyDocument({
    required this.id,
    required this.title,
    required this.course,
    required this.category,
    required this.description,
    required this.link,
    required this.updatedAt,
    this.author = '',
    this.semester = '',
    this.tags = const [],
    this.attachmentName = '',
    this.attachmentPath = '',
  });

  final String id;
  final String title;
  final String course;
  final DocumentCategory category;
  final String description;
  final String link;
  final DateTime updatedAt;
  final String author;
  final String semester;
  final List<String> tags;
  final String attachmentName;
  final String attachmentPath;

  StudyDocument copyWith({
    String? title,
    String? course,
    DocumentCategory? category,
    String? description,
    String? link,
    DateTime? updatedAt,
    String? author,
    String? semester,
    List<String>? tags,
    String? attachmentName,
    String? attachmentPath,
  }) => StudyDocument(
    id: id,
    title: title ?? this.title,
    course: course ?? this.course,
    category: category ?? this.category,
    description: description ?? this.description,
    link: link ?? this.link,
    updatedAt: updatedAt ?? this.updatedAt,
    author: author ?? this.author,
    semester: semester ?? this.semester,
    tags: tags ?? this.tags,
    attachmentName: attachmentName ?? this.attachmentName,
    attachmentPath: attachmentPath ?? this.attachmentPath,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'course': course,
    'category': category.name,
    'description': description,
    'link': link,
    'updatedAt': updatedAt.toIso8601String(),
    'author': author,
    'semester': semester,
    'tags': tags,
    'attachmentName': attachmentName,
    'attachmentPath': attachmentPath,
  };

  factory StudyDocument.fromJson(Map<String, Object?> json) => StudyDocument(
    id: json['id'] as String,
    title: json['title'] as String,
    course: json['course'] as String,
    category: DocumentCategory.values.byName(json['category'] as String),
    description: json['description'] as String? ?? '',
    link: json['link'] as String? ?? '',
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    author: json['author'] as String? ?? '',
    semester: json['semester'] as String? ?? '',
    tags: (json['tags'] as List<Object?>? ?? const []).cast<String>(),
    attachmentName: json['attachmentName'] as String? ?? '',
    attachmentPath: json['attachmentPath'] as String? ?? '',
  );
}
