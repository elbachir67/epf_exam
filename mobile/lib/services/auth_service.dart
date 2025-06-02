import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Pour TimeoutException
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  // Mode debug
  static bool debugMode = true;

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      if (debugMode) {
        print('=== DEBUG REGISTER ===');
        print('URL: ${ApiConfig.userServiceBaseUrl}/auth/register');
        print('Username: $username');
        print('Email: $email');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.userServiceBaseUrl}/auth/register'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode({
              'username': username,
              'email': email,
              'password': password,
              'firstName': firstName,
              'lastName': lastName,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      if (debugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true && responseData['data'] != null) {
          return {'success': true, 'user': User.fromJson(responseData['data'])};
        }
      }

      return {
        'success': false,
        'error': responseData['message'] ?? 'Registration failed',
      };
    } on SocketException catch (e) {
      if (debugMode) print('SocketException: $e');
      return {
        'success': false,
        'error':
            'No internet connection. Check if backend is running on ${ApiConfig.userServiceBaseUrl}',
      };
    } on HttpException catch (e) {
      if (debugMode) print('HttpException: $e');
      return {'success': false, 'error': 'Server error: $e'};
    } on FormatException catch (e) {
      if (debugMode) print('FormatException: $e');
      return {'success': false, 'error': 'Invalid response format from server'};
    } on TimeoutException catch (e) {
      if (debugMode) print('TimeoutException: $e');
      return {
        'success': false,
        'error': 'Connection timeout. Server took too long to respond.',
      };
    } catch (e, stackTrace) {
      if (debugMode) {
        print('Unknown error: $e');
        print('Stack trace: $stackTrace');
      }
      return {
        'success': false,
        'error': 'Registration failed: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      if (debugMode) {
        print('=== DEBUG LOGIN ===');
        print('URL: ${ApiConfig.userServiceBaseUrl}/auth/login');
        print('Username: $username');
        print('Headers: ${ApiConfig.defaultHeaders}');
      }

      final requestBody = json.encode({
        'username': username,
        'password': password,
      });

      if (debugMode) {
        print('Request body: $requestBody');
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.userServiceBaseUrl}/auth/login'),
            headers: ApiConfig.defaultHeaders,
            body: requestBody,
          )
          .timeout(ApiConfig.requestTimeout);

      if (debugMode) {
        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
      }

      // Vérifier si la réponse est vide
      if (response.body.isEmpty) {
        return {'success': false, 'error': 'Empty response from server'};
      }

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Vérifier la structure de la réponse
        final token = responseData['token'];
        if (token == null) {
          return {'success': false, 'error': 'No token in response'};
        }

        final userData = User(
          id: responseData['id'],
          username: responseData['username'] ?? username,
          email: responseData['email'] ?? '',
          firstName: responseData['firstName'],
          lastName: responseData['lastName'],
        );

        await _saveToken(token);
        await _saveUser(userData);

        if (debugMode) {
          print('Login successful!');
          print('Token saved: ${token.substring(0, 20)}...');
        }

        return {'success': true, 'token': token, 'user': userData};
      }

      return {
        'success': false,
        'error':
            responseData['message'] ??
            responseData['error'] ??
            'Invalid credentials',
      };
    } on SocketException catch (e) {
      if (debugMode) print('SocketException: $e');
      return {
        'success': false,
        'error':
            'Cannot connect to server at ${ApiConfig.userServiceBaseUrl}. Is the backend running?',
      };
    } on TimeoutException catch (e) {
      if (debugMode) print('TimeoutException: $e');
      return {
        'success': false,
        'error': 'Connection timeout. Server took too long to respond.',
      };
    } on HttpException catch (e) {
      if (debugMode) print('HttpException: $e');
      return {'success': false, 'error': 'Server error: $e'};
    } on FormatException catch (e) {
      if (debugMode) print('FormatException: $e');
      return {
        'success': false,
        'error':
            'Invalid response format from server. Response might not be JSON.',
      };
    } catch (e, stackTrace) {
      if (debugMode) {
        print('Unknown error: $e');
        print('Stack trace: $stackTrace');
      }
      return {'success': false, 'error': 'Login failed: ${e.toString()}'};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (debugMode && token != null) {
      print('Retrieved token from storage: ${token.substring(0, 20)}...');
    }
    return token;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (debugMode) print('Token saved to storage');
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    if (debugMode) print('User saved to storage: ${user.username}');
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      final user = User.fromJson(json.decode(userJson));
      if (debugMode) print('Retrieved user from storage: ${user.username}');
      return user;
    }

    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    if (debugMode) print('User logged out, storage cleared');
  }

  // Méthode utilitaire pour tester la connexion
  static Future<bool> testConnection() async {
    try {
      if (debugMode) {
        print(
          'Testing connection to: ${ApiConfig.userServiceBaseUrl}/auth/health',
        );
      }

      final response = await http
          .get(Uri.parse('${ApiConfig.userServiceBaseUrl}/auth/health'))
          .timeout(const Duration(seconds: 5));

      if (debugMode) {
        print('Health check response: ${response.statusCode}');
        print('Health check body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (debugMode) print('Connection test failed: $e');
      return false;
    }
  }
}
