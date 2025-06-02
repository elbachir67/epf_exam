import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/question.dart';
import '../models/answer.dart';
import 'auth_service.dart';

class QuestionService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getQuestionsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.contentServiceBaseUrl}/categories/$categoryId/questions'
      ).replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final List<Question> questions = (data['questions'] as List)
              .map((json) => Question.fromJson(json))
              .toList();
          
          return {
            'questions': questions,
            'pagination': data['pagination'],
          };
        }
      }
      
      throw Exception('Failed to fetch questions');
    } catch (e) {
      throw Exception('Failed to fetch questions: ${e.toString()}');
    }
  }

  Future<Question> createQuestion({
    required String title,
    required String content,
    required String categoryId,
    List<String> tags = const [],
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/questions'),
            headers: ApiConfig.getAuthHeaders(token),
            body: json.encode({
              'title': title,
              'content': content,
              'categoryId': categoryId,
              'tags': tags,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return Question.fromJson(responseData['data']);
        }
      }
      
      throw Exception('Failed to create question');
    } catch (e) {
      throw Exception('Failed to create question: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getQuestionById(String questionId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/questions/$questionId'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final question = Question.fromJson(responseData['data']);
          
          // Get answers separately
          final answersResponse = await getAnswersByQuestion(questionId);
          
          return {
            'question': question,
            'answers': answersResponse,
          };
        }
      }
      
      throw Exception('Failed to fetch question');
    } catch (e) {
      throw Exception('Failed to fetch question: ${e.toString()}');
    }
  }

  Future<List<Answer>> getAnswersByQuestion(String questionId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/questions/$questionId/answers'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map((json) => Answer.fromJson(json))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Answer> createAnswer({
    required String questionId,
    required String content,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/questions/$questionId/answers'),
            headers: ApiConfig.getAuthHeaders(token),
            body: json.encode({
              'content': content,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return Answer.fromJson(responseData['data']);
        }
      }
      
      throw Exception('Failed to create answer');
    } catch (e) {
      throw Exception('Failed to create answer: ${e.toString()}');
    }
  }

  Future<Answer> voteAnswer({
    required String answerId,
    required int vote,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/answers/$answerId/vote'),
            headers: ApiConfig.getAuthHeaders(token),
            body: json.encode({
              'vote': vote,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return Answer.fromJson(responseData['data']);
        }
      }
      
      throw Exception('Failed to vote');
    } catch (e) {
      throw Exception('Failed to vote: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> searchQuestions(
    String query, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.contentServiceBaseUrl}/questions/search'
      ).replace(queryParameters: {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final List<Question> questions = (data['questions'] as List)
              .map((json) => Question.fromJson(json))
              .toList();
          
          return {
            'questions': questions,
            'pagination': data['pagination'],
            'query': data['query'],
          };
        }
      }
      
      throw Exception('Failed to search questions');
    } catch (e) {
      throw Exception('Failed to search questions: ${e.toString()}');
    }
  }
}
