import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category.dart' as app_models;
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  Future<List<app_models.Category>> getAllCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/categories'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map((json) => app_models.Category.fromJson(json))
              .toList();
        }
      }
      
      throw Exception('Failed to fetch categories');
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Server error');
    } catch (e) {
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }

  Future<app_models.Category> getCategoryById(String categoryId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/categories/$categoryId'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return app_models.Category.fromJson(responseData['data']);
        }
      }
      
      throw Exception('Failed to fetch category');
    } catch (e) {
      throw Exception('Failed to fetch category: ${e.toString()}');
    }
  }
}
