import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/community_post_model.dart' as db;
import '../../data/repositories/firestore_community_repository.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  final _postController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  void _openNewPostSheet(
    BuildContext context,
    FirestoreCommunityRepository communityRepo,
    String authorId,
    String authorName,
  ) {
    _postController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: StatefulBuilder(
              builder: (context, setStateSheet) {
                final text = _postController.text;
                final words = text.trim().isEmpty
                    ? 0
                    : text.trim().split(RegExp(r'\s+')).length;
                final isOverLimit = words > 100;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Share with Community",
                          style: GoogleFonts.sora(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColors.onBackground,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                          onPressed: () {
                            _postController.clear();
                            Navigator.pop(sheetContext);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _postController,
                      maxLines: 4,
                      autofocus: true,
                      onChanged: (_) => setStateSheet(() {}),
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                      decoration: InputDecoration(
                        hintText: "Share a tip, question, or how you're feeling...",
                        hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                        fillColor: AppColors.background,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$words / 100 words",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isOverLimit ? AppColors.errorRed : AppColors.onSurfaceVariant,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: (isOverLimit || text.trim().isEmpty)
                              ? null
                              : () async {
                                  try {
                                    await communityRepo.createPost(
                                      authorId: authorId,
                                      authorName: authorName,
                                      content: _postController.text.trim(),
                                    );
                                    _postController.clear();
                                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString()),
                                          backgroundColor: AppColors.errorRed,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Post", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openCommentsSheet(
    BuildContext context,
    db.CommunityPost post,
    FirestoreCommunityRepository communityRepo,
    String currentUserName,
  ) {
    _commentController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.of(modalContext).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Comments (${post.comments.length})",
                  style: GoogleFonts.sora(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: post.comments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              "No comments yet. Be the first to reply!",
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: post.comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final comment = post.comments[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment.authorName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.onBackground,
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(comment.timestamp),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.content,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onBackground),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                        decoration: InputDecoration(
                          hintText: "Write a reply...",
                          hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                          fillColor: AppColors.background,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () async {
                        final text = _commentController.text.trim();
                        if (text.isEmpty) return;
                        try {
                          await communityRepo.addComment(
                            postId: post.id,
                            authorName: currentUserName,
                            content: text,
                          );
                          _commentController.clear();
                          if (modalContext.mounted) Navigator.pop(modalContext);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityRepo = RepositoryProvider.of<FirestoreCommunityRepository>(context);
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthSuccess ? authState.user.uid : "guest_user";
    final currentUserName = (authState is AuthSuccess && authState.user.displayName.isNotEmpty)
        ? authState.user.displayName
        : "Community Member";

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewPostSheet(context, communityRepo, currentUserId, currentUserName),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text("New Post", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<db.CommunityPost>>(
        stream: communityRepo.getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Unable to load posts right now.",
                  style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                ),
              ),
            );
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forum_outlined, size: 40, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      "No posts yet",
                      style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap 'New Post' to start a conversation.",
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
            physics: const BouncingScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isLiked = post.likedBy.contains(currentUserId);
              final initial = post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : "M";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.periodRoseSoft,
                          child: Text(
                            initial,
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.periodRose,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.onBackground,
                              ),
                            ),
                            Text(
                              _formatTimestamp(post.timestamp),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.content,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.outlineVariant, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            try {
                              await communityRepo.toggleLikePost(
                                postId: post.id,
                                userId: currentUserId,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? AppColors.periodRose : AppColors.onSurfaceVariant,
                                  size: 19,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "${post.likesCount}",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _openCommentsSheet(context, post, communityRepo, currentUserName),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline, color: AppColors.onSurfaceVariant, size: 18),
                                const SizedBox(width: 5),
                                Text(
                                  "${post.comments.length}",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
