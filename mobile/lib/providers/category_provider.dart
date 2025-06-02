import 'package:flutter/foundation.dart' as flutter;
import '../models/category.dart' as app_models;
import '../services/category_service.dart';

class CategoryProvider with flutter.ChangeNotifier {
  List<app_models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  final CategoryService _categoryService = CategoryService();

  List<app_models.Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    if (_categories.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getAllCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCategories() async {
    _categories.clear();
    await fetchCategories();
  }

  app_models.Category? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
