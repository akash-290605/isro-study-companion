class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int streakDays;
  final DateTime? lastStudyDate;
  final int dailyStudyGoalMinutes;
  final int dailyQuestionsGoal;
  final int dailyTestsGoal;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.streakDays = 1,
    this.lastStudyDate,
    this.dailyStudyGoalMinutes = 240,
    this.dailyQuestionsGoal = 30,
    this.dailyTestsGoal = 1,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'streakDays': streakDays,
    'lastStudyDate': lastStudyDate?.toIso8601String(),
    'dailyStudyGoalMinutes': dailyStudyGoalMinutes,
    'dailyQuestionsGoal': dailyQuestionsGoal,
    'dailyTestsGoal': dailyTestsGoal,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String? ?? '',
    photoUrl: json['photoUrl'] as String?,
    streakDays: json['streakDays'] as int? ?? 1,
    lastStudyDate: json['lastStudyDate'] != null
        ? DateTime.tryParse(json['lastStudyDate'] as String)
        : null,
    dailyStudyGoalMinutes: json['dailyStudyGoalMinutes'] as int? ?? 240,
    dailyQuestionsGoal: json['dailyQuestionsGoal'] as int? ?? 30,
    dailyTestsGoal: json['dailyTestsGoal'] as int? ?? 1,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'] as String)
        : DateTime.now(),
  );

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    int? streakDays,
    DateTime? lastStudyDate,
    int? dailyStudyGoalMinutes,
    int? dailyQuestionsGoal,
    int? dailyTestsGoal,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      streakDays: streakDays ?? this.streakDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      dailyStudyGoalMinutes:
          dailyStudyGoalMinutes ?? this.dailyStudyGoalMinutes,
      dailyQuestionsGoal: dailyQuestionsGoal ?? this.dailyQuestionsGoal,
      dailyTestsGoal: dailyTestsGoal ?? this.dailyTestsGoal,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

