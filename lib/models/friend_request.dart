/// Модель заявки в друзья
class FriendRequest {
  final String id;
  final String senderId;
  final String senderEmail;
  final String senderDisplayName;
  final String receiverId;
  final DateTime createdAt;
  final FriendRequestStatus status;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.senderDisplayName,
    required this.receiverId,
    required this.createdAt,
    this.status = FriendRequestStatus.pending,
  });

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? senderEmail,
    String? senderDisplayName,
    String? receiverId,
    DateTime? createdAt,
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      receiverId: receiverId ?? this.receiverId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'senderDisplayName': senderDisplayName,
      'receiverId': receiverId,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      senderEmail: map['senderEmail'] as String,
      senderDisplayName: map['senderDisplayName'] as String? ?? '',
      receiverId: map['receiverId'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
    );
  }
}

/// Статусы заявки в друзья
enum FriendRequestStatus {
  pending,   // Ожидает подтверждения
  accepted,  // Принята
  declined,  // Отклонена
}

extension FriendRequestStatusExtension on FriendRequestStatus {
  String get displayName {
    switch (this) {
      case FriendRequestStatus.pending:
        return 'Ожидает';
      case FriendRequestStatus.accepted:
        return 'Принята';
      case FriendRequestStatus.declined:
        return 'Отклонена';
    }
  }
}
