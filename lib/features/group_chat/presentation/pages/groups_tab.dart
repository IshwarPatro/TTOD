import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../data/models/group_models.dart';
import '../../data/repositories/group_chat_repository.dart';
import 'group_chat_screen.dart';

class GroupsTab extends StatefulWidget {
  const GroupsTab({super.key});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  int _activeSegment = 0; // 0 = My Groups, 1 = Friends

  (String userId, String displayName) _currentUser(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final profileState = context.read<ProfileBloc>().state;
    final userId = authState is AuthSuccess ? authState.user.uid : 'local_offline_user';
    String name = 'Member';
    if (profileState is ProfileLoaded && profileState.profile.name.trim().isNotEmpty) {
      name = profileState.profile.name.trim();
    } else if (authState is AuthSuccess && authState.user.displayName.trim().isNotEmpty) {
      name = authState.user.displayName.trim();
    }
    return (userId, name);
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<GroupChatRepository>(context);
    final (userId, displayName) = _currentUser(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: StreamBuilder<List<FriendRequest>>(
            stream: repo.watchIncomingFriendRequests(userId),
            builder: (context, reqSnap) {
              final pendingCount = reqSnap.data?.length ?? 0;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildSegment(0, "My Groups"),
                    _buildSegment(1, "Friends", badgeCount: pendingCount),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _activeSegment == 0
              ? _buildGroupsView(context, repo, userId, displayName)
              : _buildFriendsView(context, repo, userId, displayName),
        ),
      ],
    );
  }

  Widget _buildSegment(int index, String label, {int badgeCount = 0}) {
    final active = _activeSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSegment = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.onPrimary : AppColors.onBackground,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.periodRose,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$badgeCount",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MY GROUPS VIEW ====================

  Widget _buildGroupsView(
    BuildContext context,
    GroupChatRepository repo,
    String userId,
    String displayName,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openCreateGroupSheet(context, repo, userId, displayName),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text("Create Group", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openJoinGroupSheet(context, repo, userId, displayName),
                  icon: const Icon(Icons.link, size: 18, color: AppColors.onBackground),
                  label: Text(
                    "Join via Link",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.onBackground,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    side: const BorderSide(color: AppColors.outline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatGroup>>(
            stream: repo.watchMyGroups(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryAccent),
                );
              }
              final groups = snapshot.data ?? [];
              if (groups.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_outlined, size: 44, color: AppColors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          "No private groups yet",
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Create an invite-only group for close friends, or join one using an invite link or code.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                physics: const BouncingScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isAdmin = group.isAdmin(userId);
                  final pendingReqs = isAdmin ? group.joinRequests.length : 0;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupChatScreen(
                            groupId: group.id,
                            currentUserId: userId,
                            currentUserName: displayName,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(group.avatarColorValue),
                            child: Text(
                              group.avatarEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        group.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.sora(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onBackground,
                                        ),
                                      ),
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.periodRoseSoft,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Admin",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.periodRose,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  group.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${group.members.length} ${group.members.length == 1 ? 'member' : 'members'} · Invite only",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (pendingReqs > 0)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.periodRose,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$pendingReqs req",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== FRIENDS VIEW ====================

  Widget _buildFriendsView(
    BuildContext context,
    GroupChatRepository repo,
    String userId,
    String displayName,
  ) {
    final myLink = GroupChatRepository.friendInviteLink(userId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Friend ID & QR Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Friend ID",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userId,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: myLink));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Friend invite link copied!")),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text("Copy Link", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardBackground,
                          foregroundColor: AppColors.primaryAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQrDialog(
                          context,
                          title: "Your Friend QR",
                          subtitle: "Friends can scan or paste this link to send you a friend request.",
                          data: myLink,
                          codeLabel: userId,
                        ),
                        icon: const Icon(Icons.qr_code_2, size: 18, color: AppColors.onPrimary),
                        label: Text("Show QR", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onPrimary)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.onPrimary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAddFriendSheet(context, repo, userId, displayName),
              icon: const Icon(Icons.person_add_outlined, size: 18, color: AppColors.onBackground),
              label: Text(
                "Add Friend by ID or Link",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.onBackground),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                side: const BorderSide(color: AppColors.outline),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Incoming Friend Requests
          StreamBuilder<List<FriendRequest>>(
            stream: repo.watchIncomingFriendRequests(userId),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Friend Requests (${requests.length})",
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                  ),
                  const SizedBox(height: 10),
                  ...requests.map((req) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.periodRoseSoft,
                              child: Text(
                                req.fromDisplayName[0].toUpperCase(),
                                style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: AppColors.periodRose),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.fromDisplayName,
                                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                                  ),
                                  Text(
                                    "Wants to be friends",
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: "Decline",
                              onPressed: () => repo.declineFriendRequest(
                                currentUserId: userId,
                                requestId: req.id,
                              ),
                              icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                            ),
                            IconButton.filled(
                              tooltip: "Accept",
                              onPressed: () => repo.acceptFriendRequest(
                                currentUserId: userId,
                                currentUserName: displayName,
                                request: req,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.ovulationSage,
                                foregroundColor: AppColors.onPrimary,
                              ),
                              icon: const Icon(Icons.check, size: 18),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // Friend List
          Text(
            "Friends",
            style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<FriendEntry>>(
            stream: repo.watchFriends(userId),
            builder: (context, snapshot) {
              final friends = snapshot.data ?? [];
              if (friends.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 32, color: AppColors.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        "No friends added yet",
                        style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Share your QR code or Friend ID to connect and invite friends directly to your groups.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final friend = friends[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.ovulationSageSoft,
                          child: Text(
                            friend.displayName[0].toUpperCase(),
                            style: GoogleFonts.sora(fontWeight: FontWeight.bold, color: AppColors.ovulationSage),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.displayName,
                                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBackground),
                              ),
                              Text(
                                friend.userId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: "Remove friend",
                          onPressed: () => repo.removeFriend(
                            currentUserId: userId,
                            friendUserId: friend.userId,
                          ),
                          icon: const Icon(Icons.person_remove_outlined, size: 19, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== SHEETS & DIALOGS ====================

  void _openCreateGroupSheet(
    BuildContext context,
    GroupChatRepository repo,
    String userId,
    String displayName,
  ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int? selectedColor;
    String? selectedEmoji;

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
              final previewName = nameController.text.trim().isEmpty ? 'Group' : nameController.text.trim();
              final previewColor = selectedColor ?? ChatGroup.generateAvatarColor(previewName);
              final previewEmoji = selectedEmoji ?? ChatGroup.generateAvatarEmoji(previewName);

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Create Private Group",
                            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Avatar Preview
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(previewColor),
                              child: Text(previewEmoji, style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedColor == null && selectedEmoji == null
                                  ? "Auto-generated avatar (optional to customize)"
                                  : "Custom avatar selected",
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Optional Emoji & Color Pickers
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text("Auto"),
                                selected: selectedEmoji == null && selectedColor == null,
                                showCheckmark: false,
                                onSelected: (_) => setSheetState(() {
                                  selectedEmoji = null;
                                  selectedColor = null;
                                }),
                                selectedColor: AppColors.primaryAccent,
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: (selectedEmoji == null && selectedColor == null)
                                      ? AppColors.onPrimary
                                      : AppColors.onBackground,
                                ),
                              ),
                            ),
                            ...ChatGroup.avatarEmojiPresets.map((emoji) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(emoji, style: const TextStyle(fontSize: 16)),
                                    selected: selectedEmoji == emoji,
                                    showCheckmark: false,
                                    onSelected: (_) => setSheetState(() => selectedEmoji = emoji),
                                    selectedColor: AppColors.periodRoseSoft,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ChatGroup.avatarColorPresets.map((colorVal) {
                          final isSelected = selectedColor == colorVal;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedColor = colorVal),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: AppColors.primaryAccent, width: 2.5)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: nameController,
                        maxLength: 40,
                        onChanged: (_) => setSheetState(() {}),
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.onBackground),
                        decoration: InputDecoration(
                          labelText: "Group Name *",
                          hintText: "e.g., Besties Circle",
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        maxLength: 140,
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                        decoration: InputDecoration(
                          labelText: "Description (Optional)",
                          hintText: "Auto-generated if left blank",
                          fillColor: AppColors.background,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final group = await repo.createGroup(
                              creatorId: userId,
                              creatorName: displayName,
                              name: nameController.text,
                              description: descController.text,
                              avatarColorValue: selectedColor,
                              avatarEmoji: selectedEmoji,
                            );
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupChatScreen(
                                    groupId: group.id,
                                    currentUserId: userId,
                                    currentUserName: displayName,
                                  ),
                                ),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text("Create Group", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openJoinGroupSheet(
    BuildContext context,
    GroupChatRepository repo,
    String userId,
    String displayName,
  ) {
    final codeController = TextEditingController();
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
              18,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Join Invite-Only Group",
                  style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 6),
                Text(
                  "Paste an invite link or 8-character code from a friend. A group admin will approve your request.",
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: codeController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                  decoration: InputDecoration(
                    hintText: "https://ttod.app/join/ABCD1234 or ABCD1234",
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final groupName = await repo.requestToJoinByCodeOrLink(
                        rawInput: codeController.text,
                        userId: userId,
                        displayName: displayName,
                      );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Join request sent to '$groupName'!")),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("Send Join Request", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddFriendSheet(
    BuildContext context,
    GroupChatRepository repo,
    String userId,
    String displayName,
  ) {
    final friendIdController = TextEditingController();
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
              18,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Add a Friend",
                  style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 6),
                Text(
                  "Enter your friend's ID or paste their friend invite link.",
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: friendIdController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
                  decoration: InputDecoration(
                    hintText: "Friend ID or https://ttod.app/friend/...",
                    fillColor: AppColors.background,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await repo.sendFriendRequest(
                        fromUserId: userId,
                        fromDisplayName: displayName,
                        rawTargetIdOrLink: friendIdController.text,
                      );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Friend request sent!")),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("Send Friend Request", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String data,
    required String codeLabel,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 190,
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
              const SizedBox(height: 12),
              SelectableText(
                codeLabel,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Close", style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: data));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Link copied to clipboard!")),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text("Copy Link", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }
}
