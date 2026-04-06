/// Модель профиля пользователя
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final bool notificationsEnabled;
  final String languageCode;
  final bool isDarkMode;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.notificationsEnabled = true,
    this.languageCode = 'ru',
    this.isDarkMode = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? notificationsEnabled,
    String? languageCode,
    bool? isDarkMode,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      languageCode: languageCode ?? this.languageCode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'notificationsEnabled': notificationsEnabled,
      'languageCode': languageCode,
      'isDarkMode': isDarkMode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? '',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      languageCode: map['languageCode'] as String? ?? 'ru',
      isDarkMode: map['isDarkMode'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
