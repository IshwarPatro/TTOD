import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/group_models.dart';
import '../../data/repositories/group_chat_repository.dart';
import 'group_manage_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;
  final String currentUserName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Future<void> _sendMessage(GroupChatRepository repo) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await repo.sendMessage(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        content: text,
      );
      _messageController.clear();
      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<GroupChatRepository>(context);

    return StreamBuilder<ChatGroup?>(
      stream: repo.watchGroup(widget.groupId),
      builder: (context, groupSnap) {
        final group = groupSnap.data;
        if (groupSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
          );
        }
        if (group == null || !group.isMember(widget.currentUserId)) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
            body: Center(
              child: Text(
                "This group is no longer available.",
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }

        final isAdmin = group.isAdmin(widget.currentUserId);
        final pendingCount = isAdmin ? group.joinRequests.length : 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            title: InkWell(
              onTap: () => _openManageScreen(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(group.avatarColorValue),
                    child: Text(group.avatarEmoji, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Text(
                          "${group.members.length} ${group.members.length == 1 ? 'member' : 'members'}",
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    tooltip: "Manage Group",
                    onPressed: () => _openManageScreen(context),
                    icon: const Icon(Icons.settings_outlined, color: AppColors.onBackground),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.periodRose,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$pendingCount",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              const Divider(color: AppColors.outline, height: 1),
              Expanded(
                child: StreamBuilder<List<GroupMessage>>(
                  stream: repo.watchMessages(widget.groupId),
                  builder: (context, msgSnap) {
                    final messages = msgSnap.data ?? [];
                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Color(group.avatarColorValue),
                                child: Text(group.avatarEmoji, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                group.name,
                                style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                group.description,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Say hi to start the conversation!",
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == widget.currentUserId;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.76,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primaryAccent : AppColors.cardBackground,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              border: isMe ? null : Border.all(color: AppColors.outline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  Text(
                                    msg.senderName,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.periodRose,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                ],
                                Text(
                                  msg.content,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: isMe ? AppColors.onPrimary : AppColors.onBackground,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    _formatTime(msg.timestamp),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isMe
                                          ? AppColors.onPrimary.withValues(alpha: 0.7)
                                          : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border(top: BorderSide(color: AppColors.outline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLength: GroupChatRepository.maxMessageLength,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(repo),
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                          decoration: InputDecoration(
                            hintText: "Message ${group.name}...",
                            hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                            fillColor: AppColors.background,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppColors.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : () => _sendMessage(repo),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 19),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openManageScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupManageScreen(
          groupId: widget.groupId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }
}
