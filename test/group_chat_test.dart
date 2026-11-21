import 'package:flutter_test/flutter_test.dart';
import 'package:thattimeofday/features/group_chat/data/models/group_models.dart';
import 'package:thattimeofday/features/group_chat/data/repositories/group_chat_repository.dart';

void main() {
  group('GroupChatRepository (Invite-Only Groups, Roles, Friends & Rate Limits)', () {
    late GroupChatRepository repo;

    setUp(() {
      repo = GroupChatRepository(forceLocal: true);
    });

    test('createGroup auto-generates avatar and description when omitted, and sets creator as admin', () async {
      final group = await repo.createGroup(
        creatorId: 'user_1',
        creatorName: 'Alice',
        name: 'Close Friends',
      );

      expect(group.name, 'Close Friends');
      expect(group.description, 'Private invite-only group for Close Friends.');
      expect(group.avatarEmoji.isNotEmpty, isTrue);
      expect(ChatGroup.avatarColorPresets.contains(group.avatarColorValue), isTrue);
      expect(group.inviteCode.length, 8);
      expect(group.isAdmin('user_1'), isTrue);
      expect(group.members.length, 1);
    });

    test('join via invite link -> admin approval adds user with User role', () async {
      final group = await repo.createGroup(
        creatorId: 'admin_1',
        creatorName: 'Alice',
        name: 'Wellness Circle',
      );

      final groupName = await repo.requestToJoinByCodeOrLink(
        rawInput: group.inviteLink,
        userId: 'user_2',
        displayName: 'Bella',
      );
      expect(groupName, 'Wellness Circle');

      final pendingGroup = await repo.watchGroup(group.id).first;
      expect(pendingGroup!.joinRequests.length, 1);
      expect(pendingGroup.isMember('user_2'), isFalse);

      await repo.approveJoinRequest(
        groupId: group.id,
        actorId: 'admin_1',
        request: pendingGroup.joinRequests.first,
      );

      final updated = await repo.watchGroup(group.id).first;
      expect(updated!.isMember('user_2'), isTrue);
      expect(updated.isAdmin('user_2'), isFalse);
      expect(updated.joinRequests, isEmpty);
    });

    test('non-admin user cannot edit group or promote/remove members', () async {
      final group = await repo.createGroup(
        creatorId: 'admin_1',
        creatorName: 'Alice',
        name: 'Tea Club',
      );
      await repo.requestToJoinByCodeOrLink(
        rawInput: group.inviteCode,
        userId: 'user_2',
        displayName: 'Bella',
      );
      final req = (await repo.watchGroup(group.id).first)!.joinRequests.first;
      await repo.approveJoinRequest(groupId: group.id, actorId: 'admin_1', request: req);

      await expectLater(
        () => repo.updateGroup(groupId: group.id, actorId: 'user_2', name: 'Hacked'),
        throwsA(isA<GroupChatException>()),
      );
      await expectLater(
        () => repo.updateMemberRole(
          groupId: group.id,
          actorId: 'user_2',
          targetUserId: 'user_2',
          newRole: GroupRole.admin,
        ),
        throwsA(isA<GroupChatException>()),
      );
    });

    test('friend request -> accept -> invite friend directly into group', () async {
      final link = GroupChatRepository.friendInviteLink('user_2');
      await repo.sendFriendRequest(
        fromUserId: 'user_1',
        fromDisplayName: 'Alice',
        rawTargetIdOrLink: link,
      );

      final incoming = await repo.watchIncomingFriendRequests('user_2').first;
      expect(incoming.length, 1);

      await repo.acceptFriendRequest(
        currentUserId: 'user_2',
        currentUserName: 'Bella',
        request: incoming.first,
      );

      final aliceFriends = await repo.watchFriends('user_1').first;
      expect(aliceFriends.length, 1);
      expect(aliceFriends.first.userId, 'user_2');

      final group = await repo.createGroup(
        creatorId: 'user_1',
        creatorName: 'Alice',
        name: 'Squad',
      );
      await repo.inviteFriendToGroup(
        groupId: group.id,
        actorId: 'user_1',
        friend: aliceFriends.first,
      );

      final updated = await repo.watchGroup(group.id).first;
      expect(updated!.isMember('user_2'), isTrue);
    });

    test('anti-abuse rate limiters enforce max groups, max messages/min, and self-request blocks', () async {
      // Max groups per user
      for (int i = 0; i < GroupChatRepository.maxGroupsCreatedPerUser; i++) {
        await repo.createGroup(creatorId: 'u1', creatorName: 'A', name: 'Group $i');
      }
      await expectLater(
        () => repo.createGroup(creatorId: 'u1', creatorName: 'A', name: 'Too Many'),
        throwsA(isA<GroupChatException>()),
      );

      // Message rate limit
      final group = (await repo.watchMyGroups('u1').first).first;
      for (int i = 0; i < GroupChatRepository.maxMessagesPerMinute; i++) {
        await repo.sendMessage(groupId: group.id, senderId: 'u1', senderName: 'A', content: 'Hi $i');
      }
      await expectLater(
        () => repo.sendMessage(groupId: group.id, senderId: 'u1', senderName: 'A', content: 'Spam'),
        throwsA(isA<GroupChatException>()),
      );

      // Self friend request blocked
      await expectLater(
        () => repo.sendFriendRequest(fromUserId: 'u1', fromDisplayName: 'A', rawTargetIdOrLink: 'u1'),
        throwsA(isA<GroupChatException>()),
      );
    });
  });
}
