import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String authorName;
  final String content;
  final DateTime timestamp;

  CommunityComment({
    required this.authorName,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory CommunityComment.fromMap(Map<String, dynamic> map) {
    return CommunityComment(
      authorName: map['authorName'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final int likesCount;
  final List<String> likedBy;
  final List<CommunityComment> comments;
  final DateTime timestamp;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.likesCount,
    required this.likedBy,
    required this.comments,
    required this.timestamp,
  });

  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? content,
    int? likesCount,
    List<String>? likedBy,
    List<CommunityComment>? comments,
    DateTime? timestamp,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'comments': comments.map((c) => c.toMap()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory CommunityPost.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    final rawComments = map['comments'] as List<dynamic>? ?? [];
    
    return CommunityPost(
      id: doc.id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Anonymous',
      content: map['content'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      comments: rawComments.map((c) => CommunityComment.fromMap(Map<String, dynamic>.from(c))).toList(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
