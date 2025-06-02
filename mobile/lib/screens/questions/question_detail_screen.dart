import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/question.dart';
import '../../models/answer.dart';
import '../../services/question_service.dart';
import '../../widgets/answer_card.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const QuestionDetailScreen({Key? key, required this.questionId})
    : super(key: key);

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final QuestionService _questionService = QuestionService();
  final _answerController = TextEditingController();
  final _answerFormKey = GlobalKey<FormState>();

  Question? _question;
  List<Answer> _answers = [];
  bool _isLoading = true;
  bool _isSubmittingAnswer = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestionDetails();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading question details for ID: ${widget.questionId}');
      final result = await _questionService.getQuestionById(widget.questionId);

      setState(() {
        _question = result['question'];
        _answers = result['answers'] ?? [];
        _isLoading = false;
      });

      print('Question loaded: ${_question?.title}');
      print('Answers loaded: ${_answers.length}');
    } catch (e) {
      print('Error loading question details: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (!_answerFormKey.currentState!.validate()) return;

    setState(() {
      _isSubmittingAnswer = true;
    });

    try {
      await _questionService.createAnswer(
        questionId: widget.questionId,
        content: _answerController.text.trim(),
      );

      _answerController.clear();
      await _loadQuestionDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting answer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmittingAnswer = false;
      });
    }
  }

  Future<void> _voteAnswer(String answerId, int vote) async {
    try {
      await _questionService.voteAnswer(answerId: answerId, vote: vote);
      await _loadQuestionDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Question not found',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestionDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuestionDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadQuestionDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuestionSection(),
              _buildAnswersSection(),
              _buildAnswerForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSection() {
    if (_question == null) {
      print('ERROR: _question is null in _buildQuestionSection');
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Question data not loaded')),
        ),
      );
    }

    print('Building question section for: ${_question!.title}');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chip
            if (_question?.category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _question!.category!.getColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _question!.category!.name,
                  style: TextStyle(
                    color: _question!.category!.getColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Title
            Text(
              _question?.title ?? 'No title',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              _question?.content ?? 'No content',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),

            // Tags
            if (_question?.tags.isNotEmpty ?? false)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _question!.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (_question?.tags.isNotEmpty ?? false) const SizedBox(height: 16),

            // Metadata
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _question?.authorName ?? 'Unknown',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_question?.viewCount ?? 0} views',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (_question?.createdAt != null)
                  Text(
                    DateFormat('MMM d, yyyy').format(_question!.createdAt!),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${_answers.length} ${_answers.length == 1 ? 'Answer' : 'Answers'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        if (_answers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No answers yet. Be the first to answer!',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ..._answers.map(
            (answer) => AnswerCard(
              answer: answer,
              onVote: (vote) => _voteAnswer(answer.id, vote),
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _answerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your Answer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(
                  hintText: 'Write your answer here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your answer';
                  }
                  if (value.trim().length < 5) {
                    return 'Answer must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSubmittingAnswer ? null : _submitAnswer,
                child: _isSubmittingAnswer
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
                    : const Text('Post Answer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
