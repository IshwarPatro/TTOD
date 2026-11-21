import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/group_models.dart';
import '../../data/repositories/group_chat_repository.dart';

class GroupManageScreen extends StatelessWidget {
  final String groupId;
  final String currentUserId;

  const GroupManageScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<GroupChatRepository>(context);

    return StreamBuilder<ChatGroup?>(
      stream: repo.watchGroup(groupId),
      builder: (context, snapshot) {
        final group = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
          );
        }
        if (group == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
            body: Center(
              child: Text("Group deleted.", style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
          );
        }

        final isAdmin = group.isAdmin(currentUserId);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Group Info",
              style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: "Edit Group",
                  onPressed: () => _openEditGroupSheet(context, repo, group),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.onBackground),
                ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(group.avatarColorValue),
                        child: Text(group.avatarEmoji, style: const TextStyle(fontSize: 30)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        group.name,
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppColors.periodRoseSoft : AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isAdmin ? "Your role: Admin" : "Your role: User",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAdmin ? AppColors.periodRose : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Admin Invite & QR Section
                if (isAdmin) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Invite Friends",
                          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Share this link or QR code. New people must be approved by an admin.",
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: QrImageView(
                              data: group.inviteLink,
                              version: QrVersions.auto,
                              size: 160,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.primaryAccent,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: SelectableText(
                            group.inviteCode,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: AppColors.onBackground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: group.inviteLink));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Group invite link copied!")),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                label: Text("Copy Link", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAccent,
                                  foregroundColor: AppColors.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await repo.regenerateInviteCode(
                                    groupId: group.id,
                                    actorId: currentUserId,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Invite link reset.")),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.refresh, size: 16, color: AppColors.onBackground),
                              label: Text("Reset", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onBackground)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.outline),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openAddFromFriendsSheet(context, repo, group),
                            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18, color: AppColors.onBackground),
                            label: Text(
                              "Add from Friend List",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onBackground),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.outline),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Pending Join Requests (Admin Only)
                if (isAdmin && group.joinRequests.isNotEmpty) ...[
                  Text(
                    "Join Requests (${group.joinRequests.length})",
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                  ),
                  const SizedBox(height: 8),
                  ...group.joinRequests.map((req) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                req.displayName,
                                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                              ),
                            ),
                            IconButton(
                              tooltip: "Decline",
                              onPressed: () => repo.rejectJoinRequest(
                                groupId: group.id,
                                actorId: currentUserId,
                                requestUserId: req.userId,
                              ),
                              icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                            ),
                            IconButton.filled(
                              tooltip: "Approve",
                              onPressed: () async {
                                try {
                                  await repo.approveJoinRequest(
                                    groupId: group.id,
                                    actorId: currentUserId,
                                    request: req,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
                                    );
                                  }
                                }
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.ovulationSage,
                                foregroundColor: AppColors.onPrimary,
                              ),
                              icon: const Icon(Icons.check, size: 18),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Members List
                Text(
                  "Members (${group.members.length}/${GroupChatRepository.maxMembersPerGroup})",
                  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.members.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.outlineVariant, height: 1),
                    itemBuilder: (context, idx) {
                      final member = group.members[idx];
                      final isSelf = member.userId == currentUserId;
                      final memberIsAdmin = member.role == GroupRole.admin;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: memberIsAdmin ? AppColors.periodRoseSoft : AppColors.surfaceSubtle,
                          child: Text(
                            member.displayName[0].toUpperCase(),
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.bold,
                              color: memberIsAdmin ? AppColors.periodRose : AppColors.onBackground,
                            ),
                          ),
                        ),
                        title: Text(
                          isSelf ? "${member.displayName} (You)" : member.displayName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onBackground),
                        ),
                        subtitle: Text(
                          memberIsAdmin ? "Admin" : "User",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: memberIsAdmin ? AppColors.periodRose : AppColors.onSurfaceVariant,
                          ),
                        ),
                        trailing: (isAdmin && !isSelf)
                            ? PopupMenuButton<String>(
                                onSelected: (action) async {
                                  try {
                                    if (action == 'toggle_role') {
                                      await repo.updateMemberRole(
                                        groupId: group.id,
                                        actorId: currentUserId,
                                        targetUserId: member.userId,
                                        newRole: memberIsAdmin ? GroupRole.user : GroupRole.admin,
                                      );
                                    } else if (action == 'remove') {
                                      await repo.removeMember(
                                        groupId: group.id,
                                        actorId: currentUserId,
                                        targetUserId: member.userId,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'toggle_role',
                                    child: Text(memberIsAdmin ? "Make User" : "Make Admin"),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Text("Remove from Group", style: TextStyle(color: AppColors.errorRed)),
                                  ),
                                ],
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Leave / Delete Group
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
                        title: Text(
                          "Leave Group",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.errorRed),
                        ),
                        onTap: () async {
                          await repo.removeMember(
                            groupId: group.id,
                            actorId: currentUserId,
                            targetUserId: currentUserId,
                          );
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                      ),
                      if (isAdmin) ...[
                        const Divider(color: AppColors.outlineVariant, height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                          title: Text(
                            "Delete Group",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.errorRed),
                          ),
                          onTap: () async {
                            await repo.deleteGroup(groupId: group.id, actorId: currentUserId);
                            if (context.mounted) {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddFromFriendsSheet(
    BuildContext context,
    GroupChatRepository repo,
    ChatGroup group,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Friends to ${group.name}",
                  style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<FriendEntry>>(
                  stream: repo.watchFriends(currentUserId),
                  builder: (context, snap) {
                    final friends = (snap.data ?? [])
                        .where((f) => !group.isMember(f.userId))
                        .toList();
                    if (friends.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "No friends available to add right now.",
                            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: friends.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.outlineVariant, height: 1),
                        itemBuilder: (context, idx) {
                          final friend = friends[idx];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.ovulationSageSoft,
                              child: Text(
                                friend.displayName[0].toUpperCase(),
                                style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: AppColors.ovulationSage),
                              ),
                            ),
                            title: Text(friend.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await repo.inviteFriendToGroup(
                                    groupId: group.id,
                                    actorId: currentUserId,
                                    friend: friend,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Added ${friend.displayName}!")),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAccent,
                                foregroundColor: AppColors.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Add"),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditGroupSheet(
    BuildContext context,
    GroupChatRepository repo,
    ChatGroup group,
  ) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);
    int selectedColor = group.avatarColorValue;
    String selectedEmoji = group.avatarEmoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Edit Group",
                      style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ChatGroup.avatarColorPresets.map((c) {
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedColor = c),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: selectedColor == c
                                  ? Border.all(color: AppColors.primaryAccent, width: 2.5)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: ChatGroup.avatarEmojiPresets.map((emoji) {
                        return ChoiceChip(
                          label: Text(emoji, style: const TextStyle(fontSize: 16)),
                          selected: selectedEmoji == emoji,
                          showCheckmark: false,
                          onSelected: (_) => setSheetState(() => selectedEmoji = emoji),
                          selectedColor: AppColors.periodRoseSoft,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: "Group Name",
                        fillColor: AppColors.background,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      maxLength: 140,
                      decoration: InputDecoration(
                        labelText: "Description (auto-generated if blank)",
                        fillColor: AppColors.background,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await repo.updateGroup(
                            groupId: group.id,
                            actorId: currentUserId,
                            name: nameController.text,
                            description: descController.text,
                            avatarColorValue: selectedColor,
                            avatarEmoji: selectedEmoji,
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("Save Changes", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
