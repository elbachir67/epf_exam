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

  @override
  void initState() {
    super.initState();
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreQuestions();
      }
    }
  }

  Future<void> _loadCategories() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.fetchCategories();
    
    if (categoryProvider.categories.isNotEmpty && mounted) {
      setState(() {
        _selectedCategory = categoryProvider.categories.first;
      });
      _loadQuestions(refresh: true);
    }
  }

  Future<void> _loadQuestions({bool refresh = false}) async {
    if (_selectedCategory == null) return;

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
      final result = await _questionService.getQuestionsByCategory(
        _selectedCategory!.id,
        page: _currentPage,
        limit: 10,
      );

      final List<Question> newQuestions = result['questions'] as List<Question>;
      final pagination = result['pagination'] as Map<String, dynamic>;

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
          _buildCategorySelector(categoryProvider),
          Expanded(
            child: _buildQuestionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_selectedCategory != null) {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreateQuestionScreen(
                  selectedCategory: _selectedCategory!,
                ),
              ),
            );
            
            if (result == true) {
              _loadQuestions(refresh: true);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySelector(CategoryProvider categoryProvider) {
    if (categoryProvider.categories.isEmpty) {
      return const SizedBox.shrink();
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
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
            Icon(
              Icons.help_outline,
              size: 64,
              color: Colors.grey[400],
            ),
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
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
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
                  builder: (context) => QuestionDetailScreen(
                    questionId: question.id,
                  ),
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
