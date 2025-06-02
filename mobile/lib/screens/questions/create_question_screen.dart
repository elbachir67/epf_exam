import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart' as app_models;
import '../../providers/category_provider.dart';
import '../../services/question_service.dart';
import '../../config/api_config.dart';

class CreateQuestionScreen extends StatefulWidget {
  final app_models.Category? selectedCategory;

  const CreateQuestionScreen({Key? key, this.selectedCategory})
    : super(key: key);

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final QuestionService _questionService = QuestionService();

  app_models.Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;
  bool _debugMode = false; // Mode debug pour voir les détails

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    // Afficher la configuration API au démarrage
    ApiConfig.printConfig();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() {
        _error = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (_debugMode) {
        print('=== Debug Create Question ===');
        print('Title: ${_titleController.text.trim()}');
        print('Content: ${_contentController.text.trim()}');
        print('Category ID: ${_selectedCategory!.id}');
        print('Tags: $tags');
        print('============================');
      }

      await _questionService.createQuestion(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        categoryId: _selectedCategory!.id,
        tags: tags,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (_debugMode) {
        print('=== Error Details ===');
        print(e.toString());
        print('====================');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
        actions: [
          // Bouton debug
          IconButton(
            icon: Icon(
              _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            onPressed: () {
              setState(() {
                _debugMode = !_debugMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Debug mode: ${_debugMode ? "ON" : "OFF"}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Message de debug
              if (_debugMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Info:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('API URL: ${ApiConfig.contentServiceBaseUrl}'),
                      Text(
                        'Categories loaded: ${categoryProvider.categories.length}',
                      ),
                      if (_selectedCategory != null)
                        Text('Selected category ID: ${_selectedCategory!.id}'),
                    ],
                  ),
                ),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Error:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),

              DropdownButtonFormField<app_models.Category>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categoryProvider.categories
                    .map(
                      (app_models.Category category) =>
                          DropdownMenuItem<app_models.Category>(
                            value: category,
                            child: Text(category.name),
                          ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Question Title',
                  prefixIcon: Icon(Icons.title),
                  helperText:
                      'Be specific and imagine you\'re asking a question to another person',
                ),
                maxLines: 2,
                minLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  if (value.trim().length > 200) {
                    return 'Title must be less than 200 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Question Details',
                  prefixIcon: Icon(Icons.description),
                  helperText:
                      'Include all the information someone would need to answer your question',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide question details';
                  }
                  if (value.trim().length < 10) {
                    return 'Details must be at least 10 characters';
                  }
                  if (value.trim().length > 5000) {
                    return 'Details must be less than 5000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (optional)',
                  prefixIcon: Icon(Icons.label),
                  helperText: 'Add up to 5 tags separated by commas',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final tags = value
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                    if (tags.length > 5) {
                      return 'Maximum 5 tags allowed';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _createQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Post Question',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
