import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupRole { admin, user }

class GroupMember {
  final String userId;
  final String displayName;
  final GroupRole role;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  GroupMember copyWith({
    String? displayName,
    GroupRole? role,
  }) {
    return GroupMember(
      userId: userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'role': role.name,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    final roleStr = map['role'] as String? ?? 'user';
    return GroupMember(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Member',
      role: roleStr == 'admin' ? GroupRole.admin : GroupRole.user,
      joinedAt: _parseDate(map['joinedAt']),
    );
  }
}

class GroupJoinRequest {
  final String id;
  final String userId;
  final String displayName;
  final DateTime requestedAt;

  const GroupJoinRequest({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.requestedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'displayName': displayName,
        'requestedAt': Timestamp.fromDate(requestedAt),
      };

  factory GroupJoinRequest.fromMap(Map<String, dynamic> map) {
    return GroupJoinRequest(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'User',
      requestedAt: _parseDate(map['requestedAt']),
    );
  }
}

class GroupMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory GroupMessage.fromMap(String id, Map<String, dynamic> map) {
    return GroupMessage(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'Member',
      content: map['content'] as String? ?? '',
      timestamp: _parseDate(map['timestamp']),
    );
  }
}

class ChatGroup {
  final String id;
  final String name;
  final String description;
  final int avatarColorValue;
  final String avatarEmoji;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final List<GroupMember> members;
  final List<GroupJoinRequest> joinRequests;

  const ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarColorValue,
    required this.avatarEmoji,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    this.joinRequests = const [],
  });

  static const List<int> avatarColorPresets = [
    0xFFC85A53, // Rose
    0xFF437A5E, // Sage
    0xFFB57C3C, // Amber
    0xFF5C4330, // Espresso
    0xFF6B5B95, // Lavender
    0xFF3E6B89, // Slate Blue
  ];

  static const List<String> avatarEmojiPresets = [
    '🌸',
    '🌿',
    '☀️',
    '🌙',
    '💫',
    '🫶',
    '🍵',
    '🦋',
  ];

  static int generateAvatarColor(String groupName) {
    final hash = groupName.trim().toLowerCase().codeUnits.fold<int>(0, (a, b) => a + b);
    return avatarColorPresets[hash % avatarColorPresets.length];
  }

  static String generateAvatarEmoji(String groupName) {
    final hash = groupName.trim().toLowerCase().codeUnits.fold<int>(7, (a, b) => a * 31 + b);
    return avatarEmojiPresets[hash.abs() % avatarEmojiPresets.length];
  }

  static String generateDefaultDescription(String groupName) {
    return "Private invite-only group for ${groupName.trim()}.";
  }

  String get inviteLink => "https://ttod.app/join/$inviteCode";

  List<String> get memberIds => members.map((m) => m.userId).toList();

  bool isMember(String userId) => members.any((m) => m.userId == userId);

  bool isAdmin(String userId) =>
      members.any((m) => m.userId == userId && m.role == GroupRole.admin);

  int get adminCount => members.where((m) => m.role == GroupRole.admin).length;

  ChatGroup copyWith({
    String? name,
    String? description,
    int? avatarColorValue,
    String? avatarEmoji,
    String? inviteCode,
    List<GroupMember>? members,
    List<GroupJoinRequest>? joinRequests,
  }) {
    return ChatGroup(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy,
      createdAt: createdAt,
      members: members ?? this.members,
      joinRequests: joinRequests ?? this.joinRequests,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'avatarColorValue': avatarColorValue,
        'avatarEmoji': avatarEmoji,
        'inviteCode': inviteCode,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'memberIds': memberIds,
        'members': members.map((m) => m.toMap()).toList(),
        'joinRequests': joinRequests.map((r) => r.toMap()).toList(),
      };

  factory ChatGroup.fromMap(String id, Map<String, dynamic> map) {
    final rawMembers = map['members'] as List<dynamic>? ?? [];
    final rawRequests = map['joinRequests'] as List<dynamic>? ?? [];
    final name = map['name'] as String? ?? 'Group';
    return ChatGroup(
      id: id,
      name: name,
      description: (map['description'] as String?)?.isNotEmpty == true
          ? map['description'] as String
          : generateDefaultDescription(name),
      avatarColorValue: map['avatarColorValue'] as int? ?? generateAvatarColor(name),
      avatarEmoji: (map['avatarEmoji'] as String?)?.isNotEmpty == true
          ? map['avatarEmoji'] as String
          : generateAvatarEmoji(name),
      inviteCode: map['inviteCode'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      members: rawMembers
          .map((m) => GroupMember.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      joinRequests: rawRequests
          .map((r) => GroupJoinRequest.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
  }
}

class FriendEntry {
  final String userId;
  final String displayName;
  final DateTime addedAt;

  const FriendEntry({
    required this.userId,
    required this.displayName,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  factory FriendEntry.fromMap(Map<String, dynamic> map) {
    return FriendEntry(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Friend',
      addedAt: _parseDate(map['addedAt']),
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromDisplayName;
  final String toUserId;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.toUserId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'fromUserId': fromUserId,
        'fromDisplayName': fromDisplayName,
        'toUserId': toUserId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequest(
      id: id,
      fromUserId: map['fromUserId'] as String? ?? '',
      fromDisplayName: map['fromDisplayName'] as String? ?? 'User',
      toUserId: map['toUserId'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
