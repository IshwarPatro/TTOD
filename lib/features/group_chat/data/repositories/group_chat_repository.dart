import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/group_models.dart';

class GroupChatException implements Exception {
  final String message;
  const GroupChatException(this.message);

  @override
  String toString() => message;
}

class GroupChatRepository {
  // Anti-abuse rate limits
  static const int maxGroupsCreatedPerUser = 5;
  static const int maxMembersPerGroup = 25;
  static const int maxPendingRequestsPerGroup = 20;
  static const int maxMessagesPerMinute = 10;
  static const int maxMessageLength = 500;
  static const int maxRequestsPerHour = 10;

  final FirebaseFirestore? _firestore;

  // In-memory rate-limit trackers (per user)
  final Map<String, List<DateTime>> _messageTimestamps = {};
  final Map<String, List<DateTime>> _requestTimestamps = {};

  // Local fallback stores (used when Firebase is unavailable / offline / tests)
  final Map<String, ChatGroup> _localGroups = {};
  final Map<String, List<GroupMessage>> _localMessages = {};
  final Map<String, List<FriendEntry>> _localFriends = {};
  final Map<String, List<FriendRequest>> _localFriendRequests = {};

  final StreamController<void> _localChangeController =
      StreamController<void>.broadcast();

  GroupChatRepository({FirebaseFirestore? firestore, bool forceLocal = false})
      : _firestore = (!forceLocal && _isFirebaseAvailable())
            ? (firestore ?? FirebaseFirestore.instance)
            : null;

  static bool _isFirebaseAvailable() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get isFirebaseEnabled => _firestore != null;

  static String friendInviteLink(String userId) => "https://ttod.app/friend/$userId";

  static String parseGroupInviteCode(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last.trim().toUpperCase();
    }
    return trimmed.toUpperCase();
  }

  static String parseFriendUserId(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last.trim();
    }
    return trimmed;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _checkMessageRateLimit(String userId) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 1));
    final list = (_messageTimestamps[userId] ?? [])
      ..removeWhere((t) => t.isBefore(cutoff));
    if (list.length >= maxMessagesPerMinute) {
      throw const GroupChatException(
        "You're sending messages too fast. Please wait a moment.",
      );
    }
    list.add(now);
    _messageTimestamps[userId] = list;
  }

  void _checkRequestRateLimit(String userId) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1));
    final list = (_requestTimestamps[userId] ?? [])
      ..removeWhere((t) => t.isBefore(cutoff));
    if (list.length >= maxRequestsPerHour) {
      throw const GroupChatException(
        "Request limit reached (max $maxRequestsPerHour per hour). Please try again later.",
      );
    }
    list.add(now);
    _requestTimestamps[userId] = list;
  }

  void _notifyLocal() {
    if (!_localChangeController.isClosed) {
      _localChangeController.add(null);
    }
  }

  // ==================== GROUPS ====================

  Stream<List<ChatGroup>> watchMyGroups(String userId) {
    if (isFirebaseEnabled) {
      return _firestore!
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .snapshots()
          .map((snap) {
        final groups = snap.docs
            .map((d) => ChatGroup.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return groups;
      });
    }

    Stream<List<ChatGroup>> emitLocal() async* {
      List<ChatGroup> current() => _localGroups.values
          .where((g) => g.isMember(userId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      yield current();
      await for (final _ in _localChangeController.stream) {
        yield current();
      }
    }

    return emitLocal();
  }

  Stream<ChatGroup?> watchGroup(String groupId) {
    if (isFirebaseEnabled) {
      return _firestore!
          .collection('groups')
          .doc(groupId)
          .snapshots()
          .map((doc) => doc.exists && doc.data() != null
              ? ChatGroup.fromMap(doc.id, doc.data()!)
              : null);
    }

    Stream<ChatGroup?> emitLocal() async* {
      yield _localGroups[groupId];
      await for (final _ in _localChangeController.stream) {
        yield _localGroups[groupId];
      }
    }

    return emitLocal();
  }

  Future<ChatGroup> createGroup({
    required String creatorId,
    required String creatorName,
    required String name,
    String? description,
    int? avatarColorValue,
    String? avatarEmoji,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const GroupChatException("Please enter a group name.");
    }
    if (trimmedName.length > 40) {
      throw const GroupChatException("Group name must be 40 characters or fewer.");
    }

    final finalDescription = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : ChatGroup.generateDefaultDescription(trimmedName);
    final finalColor = avatarColorValue ?? ChatGroup.generateAvatarColor(trimmedName);
    final finalEmoji = (avatarEmoji != null && avatarEmoji.trim().isNotEmpty)
        ? avatarEmoji.trim()
        : ChatGroup.generateAvatarEmoji(trimmedName);

    final now = DateTime.now();
    final inviteCode = _generateInviteCode();
    final adminMember = GroupMember(
      userId: creatorId,
      displayName: creatorName.trim().isNotEmpty ? creatorName.trim() : 'Admin',
      role: GroupRole.admin,
      joinedAt: now,
    );

    if (isFirebaseEnabled) {
      final createdSnap = await _firestore!
          .collection('groups')
          .where('createdBy', isEqualTo: creatorId)
          .get();
      if (createdSnap.docs.length >= maxGroupsCreatedPerUser) {
        throw const GroupChatException(
          "You can create up to $maxGroupsCreatedPerUser groups.",
        );
      }

      final docRef = _firestore.collection('groups').doc();
      final group = ChatGroup(
        id: docRef.id,
        name: trimmedName,
        description: finalDescription,
        avatarColorValue: finalColor,
        avatarEmoji: finalEmoji,
        inviteCode: inviteCode,
        createdBy: creatorId,
        createdAt: now,
        members: [adminMember],
      );
      await docRef.set(group.toMap());
      return group;
    }

    final existingCreated =
        _localGroups.values.where((g) => g.createdBy == creatorId).length;
    if (existingCreated >= maxGroupsCreatedPerUser) {
      throw const GroupChatException(
        "You can create up to $maxGroupsCreatedPerUser groups.",
      );
    }

    final id = "grp_${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}";
    final group = ChatGroup(
      id: id,
      name: trimmedName,
      description: finalDescription,
      avatarColorValue: finalColor,
      avatarEmoji: finalEmoji,
      inviteCode: inviteCode,
      createdBy: creatorId,
      createdAt: now,
      members: [adminMember],
    );
    _localGroups[id] = group;
    _localMessages[id] = [];
    _notifyLocal();
    return group;
  }

  Future<void> updateGroup({
    required String groupId,
    required String actorId,
    required String name,
    String? description,
    int? avatarColorValue,
    String? avatarEmoji,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const GroupChatException("Group name cannot be empty.");
    }
    final group = await _getGroupOrThrow(groupId);
    if (!group.isAdmin(actorId)) {
      throw const GroupChatException("Only group admins can edit group details.");
    }

    final updated = group.copyWith(
      name: trimmedName,
      description: (description != null && description.trim().isNotEmpty)
          ? description.trim()
          : ChatGroup.generateDefaultDescription(trimmedName),
      avatarColorValue: avatarColorValue ?? group.avatarColorValue,
      avatarEmoji: (avatarEmoji != null && avatarEmoji.trim().isNotEmpty)
          ? avatarEmoji.trim()
          : group.avatarEmoji,
    );
    await _saveGroup(updated);
  }

  Future<String> regenerateInviteCode({
    required String groupId,
    required String actorId,
  }) async {
    final group = await _getGroupOrThrow(groupId);
    if (!group.isAdmin(actorId)) {
      throw const GroupChatException("Only admins can reset the invite link.");
    }
    final newCode = _generateInviteCode();
    await _saveGroup(group.copyWith(inviteCode: newCode));
    return newCode;
  }

  Future<String> requestToJoinByCodeOrLink({
    required String rawInput,
    required String userId,
    required String displayName,
  }) async {
    final code = parseGroupInviteCode(rawInput);
    if (code.isEmpty) {
      throw const GroupChatException("Please enter a valid invite link or code.");
    }

    _checkRequestRateLimit(userId);

    ChatGroup? group;
    if (isFirebaseEnabled) {
      final snap = await _firestore!
          .collection('groups')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        group = ChatGroup.fromMap(snap.docs.first.id, snap.docs.first.data());
      }
    } else {
      for (final g in _localGroups.values) {
        if (g.inviteCode.toUpperCase() == code) {
          group = g;
          break;
        }
      }
    }

    if (group == null) {
      throw const GroupChatException("No group found for that invite link or code.");
    }
    if (group.isMember(userId)) {
      throw const GroupChatException("You are already a member of this group.");
    }
    if (group.members.length >= maxMembersPerGroup) {
      throw const GroupChatException("This group is full (max $maxMembersPerGroup members).");
    }
    if (group.joinRequests.any((r) => r.userId == userId)) {
      throw const GroupChatException("Your join request is already pending approval.");
    }
    if (group.joinRequests.length >= maxPendingRequestsPerGroup) {
      throw const GroupChatException("This group has too many pending requests right now.");
    }

    final req = GroupJoinRequest(
      id: "req_${DateTime.now().microsecondsSinceEpoch}",
      userId: userId,
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : 'User',
      requestedAt: DateTime.now(),
    );
    await _saveGroup(group.copyWith(joinRequests: [...group.joinRequests, req]));
    return group.name;
  }

  Future<void> approveJoinRequest({
    required String groupId,
    required String actorId,
    required GroupJoinRequest request,
  }) async {
    final group = await _getGroupOrThrow(groupId);
    if (!group.isAdmin(actorId)) {
      throw const GroupChatException("Only admins can approve join requests.");
    }
    if (group.members.length >= maxMembersPerGroup) {
      throw const GroupChatException("Group member limit ($maxMembersPerGroup) reached.");
    }

    final remainingRequests =
        group.joinRequests.where((r) => r.userId != request.userId).toList();
    final updatedMembers = List<GroupMember>.from(group.members);
    if (!group.isMember(request.userId)) {
      updatedMembers.add(GroupMember(
        userId: request.userId,
        displayName: request.displayName,
        role: GroupRole.user,
        joinedAt: DateTime.now(),
      ));
    }

    await _saveGroup(group.copyWith(
      members: updatedMembers,
      joinRequests: remainingRequests,
    ));
  }

  Future<void> rejectJoinRequest({
    required String groupId,
    required String actorId,
    required String requestUserId,
  }) async {
    final group = await _getGroupOrThrow(groupId);
    if (!group.isAdmin(actorId)) {
      throw const GroupChatException("Only admins can decline join requests.");
    }
    final remaining =
        group.joinRequests.where((r) => r.userId != requestUserId).toList();
    await _saveGroup(group.copyWith(joinRequests: remaining));
  }

  Future<void> inviteFriendToGroup({
    required String groupId,
    required String actorId,
    required FriendEntry friend,
  }) async {
    final group = await _getGroupOrThrow(groupId);
    if (!group.isAdmin(actorId)) {
      throw const GroupChatException("Only admins can add friends to this group.");
    }
    if (group.isMember(friend.userId)) {
      throw GroupChatException("${friend.displayName} is already in this group.");
    }
    if (group.members.length >= maxMembersPerGroup) {
      throw const GroupChatException("Group member limit ($maxMembersPerGroup) reached.");
    }

    final updatedMembers = [
      ...group.members,
      GroupMember(
        userId: friend.userId,
        displayName: friend.displayName,
        role: GroupRole.user,
        joinedAt: DateTime.now(),
      ),
    ];
    final remainingRequests =
        group.joinRequests.where((r) => r.userId != friend.userId).toList();
    await _saveGroup(group.copyWith(
      members: updatedMembers,
      joinRequests: remainingRequests,
    ));
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String actorId,
    required String targetUserId,
    required GroupRole newRole,
  }) async {
    final group = await _getGroupOrThrow(groupId);
    if (!group.isAdmin(actorId)) {
      throw const GroupChatException("Only admins can change member roles.");
    }
    if (newRole == GroupRole.user &&
        group.isAdmin(targetUserId) &&
        group.adminCount <= 1) {
      throw const GroupChatException(
        "Promote another member to Admin before stepping down.",
      );
    }

    final updatedMembers = group.members.map((m) {
      if (m.userId == targetUserId) {
        return m.copyWith(role: newRole);
      }
      return m;
    }).toList();
    await _saveGroup(group.copyWith(members: updatedMembers));
  }

  Future<void> removeMember({
    required String groupId,
    required String actorId,
    required String targetUserId,
  }) async {
    final group = await _getGroupOrThrow(groupId);
    final isSelfLeave = actorId == targetUserId;
    if (!isSelfLeave && !group.isAdmin(actorId)) {
      throw const GroupChatException("Only admins can remove other members.");
    }

    final remaining = group.members.where((m) => m.userId != targetUserId).toList();
    if (remaining.isEmpty) {
      await _deleteGroupInternal(groupId);
      return;
    }

    // Ensure at least one admin remains if the last admin leaves
    final hasAdmin = remaining.any((m) => m.role == GroupRole.admin);
    final finalMembers = hasAdmin
        ? remaining
        : [remaining.first.copyWith(role: GroupRole.admin), ...remaining.skip(1)];

    await _saveGroup(group.copyWith(members: finalMembers));
  }

  Future<void> deleteGroup({
    required String groupId,
    required String actorId,
  }) async {
    final group = await _getGroupOrThrow(groupId);
    if (!group.isAdmin(actorId)) {
      throw const GroupChatException("Only admins can delete this group.");
    }
    await _deleteGroupInternal(groupId);
  }

  Future<ChatGroup> _getGroupOrThrow(String groupId) async {
    if (isFirebaseEnabled) {
      final doc = await _firestore!.collection('groups').doc(groupId).get();
      if (!doc.exists || doc.data() == null) {
        throw const GroupChatException("Group not found.");
      }
      return ChatGroup.fromMap(doc.id, doc.data()!);
    }
    final group = _localGroups[groupId];
    if (group == null) {
      throw const GroupChatException("Group not found.");
    }
    return group;
  }

  Future<void> _saveGroup(ChatGroup group) async {
    if (isFirebaseEnabled) {
      await _firestore!.collection('groups').doc(group.id).set(group.toMap());
    } else {
      _localGroups[group.id] = group;
      _notifyLocal();
    }
  }

  Future<void> _deleteGroupInternal(String groupId) async {
    if (isFirebaseEnabled) {
      await _firestore!.collection('groups').doc(groupId).delete();
    } else {
      _localGroups.remove(groupId);
      _localMessages.remove(groupId);
      _notifyLocal();
    }
  }

  // ==================== MESSAGES ====================

  Stream<List<GroupMessage>> watchMessages(String groupId) {
    if (isFirebaseEnabled) {
      return _firestore!
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => GroupMessage.fromMap(d.id, d.data()))
              .toList());
    }

    Stream<List<GroupMessage>> emitLocal() async* {
      yield List<GroupMessage>.from(_localMessages[groupId] ?? const []);
      await for (final _ in _localChangeController.stream) {
        yield List<GroupMessage>.from(_localMessages[groupId] ?? const []);
      }
    }

    return emitLocal();
  }

  Future<void> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > maxMessageLength) {
      throw const GroupChatException(
        "Messages can be up to $maxMessageLength characters.",
      );
    }

    final group = await _getGroupOrThrow(groupId);
    if (!group.isMember(senderId)) {
      throw const GroupChatException("You must be a member of this group to send messages.");
    }

    _checkMessageRateLimit(senderId);

    final now = DateTime.now();
    if (isFirebaseEnabled) {
      final msgRef = _firestore!
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc();
      final msg = GroupMessage(
        id: msgRef.id,
        senderId: senderId,
        senderName: senderName.trim().isNotEmpty ? senderName.trim() : 'Member',
        content: trimmed,
        timestamp: now,
      );
      await msgRef.set(msg.toMap());
      return;
    }

    final msg = GroupMessage(
      id: "msg_${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}",
      senderId: senderId,
      senderName: senderName.trim().isNotEmpty ? senderName.trim() : 'Member',
      content: trimmed,
      timestamp: now,
    );
    final list = _localMessages[groupId] ?? [];
    list.add(msg);
    _localMessages[groupId] = list;
    _notifyLocal();
  }

  // ==================== FRIENDS ====================

  Stream<List<FriendEntry>> watchFriends(String userId) {
    if (isFirebaseEnabled) {
      return _firestore!
          .collection('users')
          .doc(userId)
          .collection('friends')
          .orderBy('addedAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => FriendEntry.fromMap(d.data())).toList());
    }

    Stream<List<FriendEntry>> emitLocal() async* {
      yield List<FriendEntry>.from(_localFriends[userId] ?? const []);
      await for (final _ in _localChangeController.stream) {
        yield List<FriendEntry>.from(_localFriends[userId] ?? const []);
      }
    }

    return emitLocal();
  }

  Stream<List<FriendRequest>> watchIncomingFriendRequests(String userId) {
    if (isFirebaseEnabled) {
      return _firestore!
          .collection('users')
          .doc(userId)
          .collection('friend_requests')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => FriendRequest.fromMap(d.id, d.data()))
              .toList());
    }

    Stream<List<FriendRequest>> emitLocal() async* {
      yield List<FriendRequest>.from(_localFriendRequests[userId] ?? const []);
      await for (final _ in _localChangeController.stream) {
        yield List<FriendRequest>.from(_localFriendRequests[userId] ?? const []);
      }
    }

    return emitLocal();
  }

  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromDisplayName,
    required String rawTargetIdOrLink,
  }) async {
    final targetUserId = parseFriendUserId(rawTargetIdOrLink);
    if (targetUserId.isEmpty) {
      throw const GroupChatException("Please enter a valid Friend ID or link.");
    }
    if (targetUserId == fromUserId) {
      throw const GroupChatException("You cannot send a friend request to yourself.");
    }

    _checkRequestRateLimit(fromUserId);

    final now = DateTime.now();
    if (isFirebaseEnabled) {
      final friendDoc = await _firestore!
          .collection('users')
          .doc(fromUserId)
          .collection('friends')
          .doc(targetUserId)
          .get();
      if (friendDoc.exists) {
        throw const GroupChatException("You are already friends with this user.");
      }

      final existingReq = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friend_requests')
          .doc(fromUserId)
          .get();
      if (existingReq.exists) {
        throw const GroupChatException("Friend request already sent.");
      }

      final req = FriendRequest(
        id: fromUserId,
        fromUserId: fromUserId,
        fromDisplayName:
            fromDisplayName.trim().isNotEmpty ? fromDisplayName.trim() : 'User',
        toUserId: targetUserId,
        createdAt: now,
      );
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friend_requests')
          .doc(fromUserId)
          .set(req.toMap());
      return;
    }

    final myFriends = _localFriends[fromUserId] ?? [];
    if (myFriends.any((f) => f.userId == targetUserId)) {
      throw const GroupChatException("You are already friends with this user.");
    }
    final targetReqs = _localFriendRequests[targetUserId] ?? [];
    if (targetReqs.any((r) => r.fromUserId == fromUserId)) {
      throw const GroupChatException("Friend request already sent.");
    }

    targetReqs.add(FriendRequest(
      id: fromUserId,
      fromUserId: fromUserId,
      fromDisplayName:
          fromDisplayName.trim().isNotEmpty ? fromDisplayName.trim() : 'User',
      toUserId: targetUserId,
      createdAt: now,
    ));
    _localFriendRequests[targetUserId] = targetReqs;
    _notifyLocal();
  }

  Future<void> acceptFriendRequest({
    required String currentUserId,
    required String currentUserName,
    required FriendRequest request,
  }) async {
    final now = DateTime.now();
    final friendForMe = FriendEntry(
      userId: request.fromUserId,
      displayName: request.fromDisplayName,
      addedAt: now,
    );
    final meForFriend = FriendEntry(
      userId: currentUserId,
      displayName: currentUserName.trim().isNotEmpty ? currentUserName.trim() : 'Friend',
      addedAt: now,
    );

    if (isFirebaseEnabled) {
      final batch = _firestore!.batch();
      batch.set(
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(request.fromUserId),
        friendForMe.toMap(),
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(request.fromUserId)
            .collection('friends')
            .doc(currentUserId),
        meForFriend.toMap(),
      );
      batch.delete(
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friend_requests')
            .doc(request.id),
      );
      await batch.commit();
      return;
    }

    final myFriends = _localFriends[currentUserId] ?? [];
    if (!myFriends.any((f) => f.userId == friendForMe.userId)) {
      myFriends.add(friendForMe);
      _localFriends[currentUserId] = myFriends;
    }
    final theirFriends = _localFriends[request.fromUserId] ?? [];
    if (!theirFriends.any((f) => f.userId == meForFriend.userId)) {
      theirFriends.add(meForFriend);
      _localFriends[request.fromUserId] = theirFriends;
    }
    _localFriendRequests[currentUserId] =
        (_localFriendRequests[currentUserId] ?? [])
            .where((r) => r.id != request.id)
            .toList();
    _notifyLocal();
  }

  Future<void> declineFriendRequest({
    required String currentUserId,
    required String requestId,
  }) async {
    if (isFirebaseEnabled) {
      await _firestore!
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests')
          .doc(requestId)
          .delete();
      return;
    }
    _localFriendRequests[currentUserId] =
        (_localFriendRequests[currentUserId] ?? [])
            .where((r) => r.id != requestId)
            .toList();
    _notifyLocal();
  }

  Future<void> removeFriend({
    required String currentUserId,
    required String friendUserId,
  }) async {
    if (isFirebaseEnabled) {
      final batch = _firestore!.batch();
      batch.delete(
        _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(friendUserId),
      );
      batch.delete(
        _firestore
            .collection('users')
            .doc(friendUserId)
            .collection('friends')
            .doc(currentUserId),
      );
      await batch.commit();
      return;
    }

    _localFriends[currentUserId] = (_localFriends[currentUserId] ?? [])
        .where((f) => f.userId != friendUserId)
        .toList();
    _localFriends[friendUserId] = (_localFriends[friendUserId] ?? [])
        .where((f) => f.userId != currentUserId)
        .toList();
    _notifyLocal();
  }
}
