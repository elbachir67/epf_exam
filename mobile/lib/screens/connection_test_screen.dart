import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/platform_config.dart';
import '../services/auth_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final List<Map<String, dynamic>> _testResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
    });

    // Test 1: Platform info
    _addResult(
      'Platform Detection',
      true,
      'Current platform: ${PlatformConfig.currentPlatform}\n'
          'Is Mobile: ${PlatformConfig.isMobile}\n'
          'Is Web: ${PlatformConfig.isWeb}\n'
          'Is Desktop: ${PlatformConfig.isDesktop}',
    );

    // Test 2: API URLs
    _addResult(
      'API Configuration',
      true,
      'User Service: ${ApiConfig.userServiceBaseUrl}\n'
          'Content Service: ${ApiConfig.contentServiceBaseUrl}',
    );

    // Test 3: User Service Health Check
    await _testEndpoint(
      'User Service Health',
      '${ApiConfig.userServiceBaseUrl}/auth/health',
      'GET',
    );

    // Test 4: Content Service Health Check
    await _testEndpoint(
      'Content Service Health',
      '${ApiConfig.contentServiceBaseUrl}',
      'GET',
    );

    // Test 5: Categories Endpoint
    await _testEndpoint(
      'Categories Endpoint',
      '${ApiConfig.contentServiceBaseUrl}/categories',
      'GET',
    );

    // Test 6: Auth Service Connection Test
    final connectionOk = await AuthService.testConnection();
    _addResult(
      'Auth Service Connection',
      connectionOk,
      connectionOk ? 'Connection successful' : 'Connection failed',
    );

    // Test 7: Login Test
    await _testLogin();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testEndpoint(String name, String url, String method) async {
    try {
      final stopwatch = Stopwatch()..start();

      http.Response response;
      if (method == 'GET') {
        response = await http
            .get(Uri.parse(url), headers: ApiConfig.defaultHeaders)
            .timeout(const Duration(seconds: 5));
      } else {
        response = await http
            .post(Uri.parse(url), headers: ApiConfig.defaultHeaders)
            .timeout(const Duration(seconds: 5));
      }

      stopwatch.stop();

      final success = response.statusCode >= 200 && response.statusCode < 300;

      _addResult(
        name,
        success,
        'URL: $url\n'
        'Method: $method\n'
        'Status: ${response.statusCode}\n'
        'Time: ${stopwatch.elapsedMilliseconds}ms\n'
        'Body: ${response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body}',
      );
    } catch (e) {
      _addResult(
        name,
        false,
        'URL: $url\n'
        'Method: $method\n'
        'Error: ${e.toString()}',
      );
    }
  }

  Future<void> _testLogin() async {
    try {
      final result = await AuthService().login('admin', 'admin123');

      _addResult(
        'Login Test (admin/admin123)',
        result['success'] == true,
        'Success: ${result['success']}\n'
            'Error: ${result['error'] ?? 'None'}\n'
            'Token: ${result['token'] != null ? '${(result['token'] as String).substring(0, 20)}...' : 'None'}',
      );
    } catch (e) {
      _addResult('Login Test', false, 'Error: ${e.toString()}');
    }
  }

  void _addResult(String test, bool success, String details) {
    setState(() {
      _testResults.add({'test': test, 'success': success, 'details': details});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runTests,
          ),
        ],
      ),
      body: _isLoading && _testResults.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _testResults.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final result = _testResults[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: Icon(
                      result['success'] ? Icons.check_circle : Icons.error,
                      color: result['success'] ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      result['test'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      result['success'] ? 'Success' : 'Failed',
                      style: TextStyle(
                        color: result['success'] ? Colors.green : Colors.red,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            result['details'],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
