import 'category.dart';

class Question {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String categoryId;
  final Category? category;
  final List<String> tags;
  final int viewCount;
  final int answerCount;
  final bool isActive;
  final bool isClosed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Question({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.categoryId,
    this.category,
    this.tags = const [],
    this.viewCount = 0,
    this.answerCount = 0,
    this.isActive = true,
    this.isClosed = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Debug print
    print('Parsing question from JSON: ${json.toString()}');

    // Handle different possible category formats
    Category? parsedCategory;
    String parsedCategoryId = '';

    if (json['categoryId'] != null) {
      if (json['categoryId'] is String) {
        parsedCategoryId = json['categoryId'];
      } else if (json['categoryId'] is Map) {
        parsedCategoryId =
            json['categoryId']['_id'] ?? json['categoryId']['id'] ?? '';
        parsedCategory = Category.fromJson(json['categoryId']);
      }
    }

    // If category is provided separately
    if (parsedCategory == null &&
        json['category'] != null &&
        json['category'] is Map) {
      parsedCategory = Category.fromJson(json['category']);
    }

    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Unknown',
      categoryId: parsedCategoryId,
      category: parsedCategory,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      viewCount: json['viewCount'] ?? 0,
      answerCount: json['answerCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      isClosed: json['isClosed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'categoryId': categoryId,
      'tags': tags,
      'viewCount': viewCount,
      'answerCount': answerCount,
      'isActive': isActive,
      'isClosed': isClosed,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
