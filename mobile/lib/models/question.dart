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
    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      categoryId: json['categoryId'] is String 
          ? json['categoryId'] 
          : (json['categoryId']?['_id'] ?? ''),
      category: json['categoryId'] != null && json['categoryId'] is Map
          ? Category.fromJson(json['categoryId'])
          : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : [],
      viewCount: json['viewCount'] ?? 0,
      answerCount: json['answerCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      isClosed: json['isClosed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'tags': tags,
    };
  }
}
