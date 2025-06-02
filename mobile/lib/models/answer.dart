class Answer {
  final String id;
  final String questionId;
  final String content;
  final String authorId;
  final String authorName;
  final List<Vote> votes;
  final int score;
  final bool isAccepted;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Answer({
    required this.id,
    required this.questionId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.votes = const [],
    this.score = 0,
    this.isAccepted = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    List<Vote> votesList = [];
    if (json['votes'] != null) {
      votesList = (json['votes'] as List)
          .map((v) => Vote.fromJson(v))
          .toList();
    }

    return Answer(
      id: json['_id'] ?? json['id'] ?? '',
      questionId: json['questionId'] ?? '',
      content: json['content'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      votes: votesList,
      score: json['score'] ?? 0,
      isAccepted: json['isAccepted'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  Vote? getUserVote(String userId) {
    try {
      return votes.firstWhere((vote) => vote.userId == userId);
    } catch (e) {
      return null;
    }
  }
}

class Vote {
  final String userId;
  final int vote;

  Vote({
    required this.userId,
    required this.vote,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      userId: json['userId'] ?? '',
      vote: json['vote'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'vote': vote,
    };
  }
}
