import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart' as app_models;
import '../../models/question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/question_service.dart';
import '../../widgets/question_card.dart';
import '../../widgets/category_chip.dart';
import '../questions/create_question_screen.dart';
import '../questions/question_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuestionService _questionService = QuestionService();
  app_models.Category? _selectedCategory;
  List<Question> _questions = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    print('HomeScreen initState called');
    _loadCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreQuestions();
      }
    }
  }

  Future<void> _loadCategories() async {
    print('Loading categories...');
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    setState(() {
      _error = null;
    });

    try {
      await categoryProvider.fetchCategories();

      if (categoryProvider.error != null) {
        setState(() {
          _error = 'Failed to load categories: ${categoryProvider.error}';
        });
        print('Category error: ${categoryProvider.error}');
        return;
      }

      print('Categories loaded: ${categoryProvider.categories.length}');

      if (categoryProvider.categories.isNotEmpty && mounted) {
        setState(() {
          _selectedCategory = categoryProvider.categories.first;
        });
        print('Selected category: ${_selectedCategory?.name}');
        _loadQuestions(refresh: true);
      } else {
        setState(() {
          _error =
              'No categories available. Please check if the backend is running correctly.';
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _error = 'Error loading categories: $e';
      });
    }
  }

  Future<void> _loadQuestions({bool refresh = false}) async {
    if (_selectedCategory == null) {
      print('No category selected');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _questions.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      print(
        'Loading questions for category: ${_selectedCategory!.name} (${_selectedCategory!.id})',
      );

      final result = await _questionService.getQuestionsByCategory(
        _selectedCategory!.id,
        page: _currentPage,
        limit: 10,
      );

      final List<Question> newQuestions = result['questions'] as List<Question>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      print('Questions loaded: ${newQuestions.length}');

      setState(() {
        if (refresh) {
          _questions = newQuestions;
        } else {
          _questions.addAll(newQuestions);
        }
        _hasMore = pagination['hasMore'] ?? false;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreQuestions() async {
    if (!_hasMore || _isLoading) return;
    await _loadQuestions(refresh: false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EPF Africa Q&A'),
        actions: [
          // Debug toggle
          IconButton(
            icon: Icon(
              _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            onPressed: () {
              setState(() {
                _debugMode = !_debugMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(authProvider);
              } else if (value == 'profile') {
                // TODO: Navigate to profile
              } else if (value == 'refresh') {
                _loadCategories();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 8),
                    Text(authProvider.currentUser?.displayName ?? 'Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh Categories'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug info
          if (_debugMode)
            Container(
              color: Colors.blue[50],
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${authProvider.currentUser?.username ?? "Unknown"}',
                  ),
                  Text('Categories: ${categoryProvider.categories.length}'),
                  Text('Selected: ${_selectedCategory?.name ?? "None"}'),
                  Text('Questions: ${_questions.length}'),
                  if (_error != null)
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),

          // Error banner
          if (_error != null && !_debugMode)
            Container(
              width: double.infinity,
              color: Colors.red[100],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadCategories,
                  ),
                ],
              ),
            ),

          _buildCategorySelector(categoryProvider),
          Expanded(child: _buildQuestionList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_selectedCategory != null) {
            print(
              'Opening create question screen with category: ${_selectedCategory!.name}',
            );

            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    CreateQuestionScreen(selectedCategory: _selectedCategory!),
              ),
            );

            if (result == true) {
              print('Question created, refreshing list');
              _loadQuestions(refresh: true);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait for categories to load'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
        backgroundColor: _selectedCategory != null
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
    );
  }

  Widget _buildCategorySelector(CategoryProvider categoryProvider) {
    if (categoryProvider.isLoading) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (categoryProvider.error != null) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Error loading categories: ${categoryProvider.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (categoryProvider.categories.isEmpty) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: const Text('No categories available'),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryProvider.categories.length,
        itemBuilder: (context, index) {
          final category = categoryProvider.categories[index];
          final isSelected = _selectedCategory?.id == category.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _loadQuestions(refresh: true);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionList() {
    if (_isLoading && _questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadQuestions(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No questions yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to ask a question!',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadQuestions(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _questions.length + (_hasMore ? 1 : 0),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (index == _questions.length) {
            return _buildLoadMoreIndicator();
          }

          final question = _questions[index];
          return QuestionCard(
            question: question,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      QuestionDetailScreen(questionId: question.id),
                ),
              );
              _loadQuestions(refresh: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text(
              'No more questions',
              style: TextStyle(color: Colors.grey),
            ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
