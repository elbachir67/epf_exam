import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
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

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true && responseData['data'] != null) {
          return {
            'success': true,
            'user': User.fromJson(responseData['data']),
          };
        }
      }
      
      return {
        'success': false,
        'error': responseData['message'] ?? 'Registration failed',
      };
    } on SocketException {
      return {'success': false, 'error': 'No internet connection'};
    } on HttpException {
      return {'success': false, 'error': 'Server error'};
    } catch (e) {
      return {'success': false, 'error': 'Registration failed: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.userServiceBaseUrl}/auth/login'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['token'];
        final userData = User(
          id: responseData['id'],
          username: responseData['username'],
          email: responseData['email'],
          firstName: responseData['firstName'],
          lastName: responseData['lastName'],
        );

        await _saveToken(token);
        await _saveUser(userData);
        
        return {
          'success': true,
          'token': token,
          'user': userData,
        };
      }
      
      return {
        'success': false,
        'error': responseData['message'] ?? 'Invalid credentials',
      };
    } on SocketException {
      return {'success': false, 'error': 'No internet connection'};
    } on HttpException {
      return {'success': false, 'error': 'Server error'};
    } catch (e) {
      return {'success': false, 'error': 'Login failed: ${e.toString()}'};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
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
  }
}
