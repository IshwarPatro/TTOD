import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post_model.dart';

class FirestoreCommunityRepository {
  final FirebaseFirestore? _firestore;
  
  static final List<CommunityPost> _mockPosts = [
    CommunityPost(
      id: "mock_post_1",
      authorId: "mock_ref_1",
      authorName: "RickC137",
      content: "Listen Morty, I-I *burp* figured out that ginger tea completely blocks prostaglandin receptors. It's science, Morty! Drink your ginger tea!",
      likesCount: 42,
      likedBy: ["current_user_id"],
      comments: [
        CommunityComment(authorName: "MortySmith", content: "Gee Rick, I don't know...", timestamp: DateTime.now().subtract(const Duration(hours: 2))),
        CommunityComment(authorName: "SummerVibe", content: "Drink it Morty!", timestamp: DateTime.now().subtract(const Duration(minutes: 45))),
      ],
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityPost(
      id: "mock_post_2",
      authorId: "mock_ref_2",
      authorName: "SummerVibe",
      content: "Prioritizing light yoga poses on day 2 of my cycle. Avoid heavy weightlifting, focus on recovery!",
      likesCount: 15,
      likedBy: [],
      comments: [
        CommunityComment(authorName: "RickC137", content: "Yoga? That's just stretching with extra steps.", timestamp: DateTime.now().subtract(const Duration(hours: 1))),
        CommunityComment(authorName: "BethS", content: "Great advice, Summer!", timestamp: DateTime.now().subtract(const Duration(minutes: 10))),
      ],
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  static final StreamController<List<CommunityPost>> _mockPostsStreamController = 
      StreamController<List<CommunityPost>>.broadcast();

  FirestoreCommunityRepository({FirebaseFirestore? firestore})
      : _firestore = _isFirebaseAvailable() ? (firestore ?? FirebaseFirestore.instance) : null {
    if (!isFirebaseEnabled) {
      // Seed initial stream
      _mockPostsStreamController.add(List.from(_mockPosts));
    }
  }

  static bool _isFirebaseAvailable() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get isFirebaseEnabled => _firestore != null;

  // Stream of all posts sorted by timestamp desc
  Stream<List<CommunityPost>> getPosts() {
    if (isFirebaseEnabled) {
      return _firestore!
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => CommunityPost.fromSnapshot(doc)).toList();
      });
    } else {
      // Periodically ensure stream has data
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_mockPostsStreamController.isClosed) {
          _mockPostsStreamController.add(List.from(_mockPosts));
        }
      });
      return _mockPostsStreamController.stream;
    }
  }

  // Create a new post
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw Exception("Post content cannot be empty.");
    }
    
    final words = trimmedContent.split(RegExp(r'\s+'));
    if (words.length > 100) {
      throw Exception("Post exceeds word limit. Maximum allowed: 100 words (Current: ${words.length} words).");
    }

    if (isFirebaseEnabled) {
      await _firestore!.collection('posts').add({
        'authorId': authorId,
        'authorName': authorName,
        'content': trimmedContent,
        'likesCount': 0,
        'likedBy': <String>[],
        'comments': <dynamic>[],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
      final newPost = CommunityPost(
        id: "mock_post_${DateTime.now().millisecondsSinceEpoch}",
        authorId: authorId,
        authorName: authorName,
        content: trimmedContent,
        likesCount: 0,
        likedBy: [],
        comments: [],
        timestamp: DateTime.now(),
      );
      _mockPosts.insert(0, newPost);
      _mockPostsStreamController.add(List.from(_mockPosts));
    }
  }

  // Like or unlike a post
  Future<void> toggleLikePost({
    required String postId,
    required String userId,
  }) async {
    if (isFirebaseEnabled) {
      final postRef = _firestore!.collection('posts').doc(postId);
      final doc = await postRef.get();
      if (!doc.exists) return;

      final post = CommunityPost.fromSnapshot(doc);
      final isLiked = post.likedBy.contains(userId);

      if (isLiked) {
        await postRef.update({
          'likesCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await postRef.update({
          'likesCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } else {
      final index = _mockPosts.indexWhere((p) => p.id == postId);
      if (index == -1) return;

      final post = _mockPosts[index];
      final isLiked = post.likedBy.contains(userId);
      
      final updatedLikedBy = List<String>.from(post.likedBy);
      int updatedLikesCount = post.likesCount;

      if (isLiked) {
        updatedLikedBy.remove(userId);
        updatedLikesCount--;
      } else {
        updatedLikedBy.add(userId);
        updatedLikesCount++;
      }

      _mockPosts[index] = post.copyWith(
        likedBy: updatedLikedBy,
        likesCount: updatedLikesCount,
      );
      
      _mockPostsStreamController.add(List.from(_mockPosts));
    }
  }

  // Add comment to a post
  Future<void> addComment({
    required String postId,
    required String authorName,
    required String content,
  }) async {
    final trimmedComment = content.trim();
    if (trimmedComment.isEmpty) {
      throw Exception("Comment cannot be empty.");
    }

    if (isFirebaseEnabled) {
      final postRef = _firestore!.collection('posts').doc(postId);
      final comment = CommunityComment(
        authorName: authorName,
        content: trimmedComment,
        timestamp: DateTime.now(),
      );

      await postRef.update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } else {
      final index = _mockPosts.indexWhere((p) => p.id == postId);
      if (index == -1) return;

      final post = _mockPosts[index];
      final updatedComments = List<CommunityComment>.from(post.comments);
      updatedComments.add(CommunityComment(
        authorName: authorName,
        content: trimmedComment,
        timestamp: DateTime.now(),
      ));

      _mockPosts[index] = post.copyWith(comments: updatedComments);
      _mockPostsStreamController.add(List.from(_mockPosts));
    }
  }
}
