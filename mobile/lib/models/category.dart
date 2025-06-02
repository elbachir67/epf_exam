import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final String color;
  final String icon;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? questionCount;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.color = '#007bff',
    this.icon = 'book',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.questionCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#007bff',
      icon: json['icon'] ?? 'book',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      questionCount: json['questionCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'isActive': isActive,
    };
  }

  Color getColor() {
    try {
      return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF007bff);
    }
  }
}
