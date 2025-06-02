import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/question.dart';
import '../models/answer.dart';
import 'auth_service.dart';

class QuestionService {
  final AuthService _authService = AuthService();

  // Mode debug
  static bool debugMode = true;

  Future<Map<String, dynamic>> getQuestionsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri =
          Uri.parse(
            '${ApiConfig.contentServiceBaseUrl}/categories/$categoryId/questions',
          ).replace(
            queryParameters: {
              'page': page.toString(),
              'limit': limit.toString(),
            },
          );

      if (debugMode) {
        print('=== GET QUESTIONS BY CATEGORY ===');
        print('URL: $uri');
      }

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (debugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final List<Question> questions = (data['questions'] as List)
              .map((json) => Question.fromJson(json))
              .toList();

          return {'questions': questions, 'pagination': data['pagination']};
        }
      }

      throw Exception('Failed to fetch questions');
    } catch (e) {
      if (debugMode) print('Error fetching questions: $e');
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
        throw Exception('User not authenticated - no token found');
      }

      if (debugMode) {
        print('=== CREATE QUESTION DEBUG ===');
        print('URL: ${ApiConfig.contentServiceBaseUrl}/questions');
        print('Token: ${token.substring(0, 50)}...');
        print('Title: $title');
        print('Content: $content');
        print('CategoryId: $categoryId');
        print('Tags: $tags');
      }

      // Décoder le token pour voir son contenu
      if (debugMode) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64.normalize(payload);
            final decoded = utf8.decode(base64.decode(normalized));
            print('Token payload: $decoded');
          }
        } catch (e) {
          print('Could not decode token: $e');
        }
      }

      final requestBody = json.encode({
        'title': title,
        'content': content,
        'categoryId': categoryId,
        'tags': tags,
      });

      if (debugMode) {
        print('Request headers: ${ApiConfig.getAuthHeaders(token)}');
        print('Request body: $requestBody');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.contentServiceBaseUrl}/questions'),
            headers: ApiConfig.getAuthHeaders(token),
            body: requestBody,
          )
          .timeout(ApiConfig.requestTimeout);

      if (debugMode) {
        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return Question.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response structure: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - invalid or expired token');
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        throw Exception(
          'Validation error: ${responseData['error'] ?? responseData['message'] ?? response.body}',
        );
      } else {
        throw Exception(
          'Server error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (debugMode) {
        print('=== CREATE QUESTION ERROR ===');
        print('Error type: ${e.runtimeType}');
        print('Error message: $e');
      }
      throw Exception('Failed to create question: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getQuestionById(String questionId) async {
    try {
      if (debugMode) {
        print('=== GET QUESTION BY ID ===');
        print('Question ID: $questionId');
        print('URL: ${ApiConfig.contentServiceBaseUrl}/questions/$questionId');
      }

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.contentServiceBaseUrl}/questions/$questionId',
            ),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.requestTimeout);

      if (debugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final question = Question.fromJson(responseData['data']);

          if (debugMode) {
            print('Question parsed successfully: ${question.title}');
          }

          // Get answers separately
          final answersResponse = await getAnswersByQuestion(questionId);

          return {'question': question, 'answers': answersResponse};
        }
      }

      throw Exception('Failed to fetch question: ${response.body}');
    } catch (e) {
      if (debugMode) {
        print('Error fetching question: $e');
      }
      throw Exception('Failed to fetch question: ${e.toString()}');
    }
  }

  Future<List<Answer>> getAnswersByQuestion(String questionId) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.contentServiceBaseUrl}/questions/$questionId/answers',
            ),
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
            Uri.parse(
              '${ApiConfig.contentServiceBaseUrl}/questions/$questionId/answers',
            ),
            headers: ApiConfig.getAuthHeaders(token),
            body: json.encode({'content': content}),
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
            Uri.parse(
              '${ApiConfig.contentServiceBaseUrl}/answers/$answerId/vote',
            ),
            headers: ApiConfig.getAuthHeaders(token),
            body: json.encode({'vote': vote}),
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
      final uri =
          Uri.parse(
            '${ApiConfig.contentServiceBaseUrl}/questions/search',
          ).replace(
            queryParameters: {
              'q': query,
              'page': page.toString(),
              'limit': limit.toString(),
            },
          );

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
