enum FeedbackCategory {
  bug('Bug / Problem', 'Something is broken or not working'),
  feature('New requirement', 'Suggest a feature or improvement'),
  general('General feedback', 'Questions, praise, or other notes');

  final String label;
  final String hint;

  const FeedbackCategory(this.label, this.hint);
}

enum FeedbackStatus {
  newFeedback('New'),
  inProgress('In progress'),
  resolved('Resolved'),
  closed('Closed');

  final String label;

  const FeedbackStatus(this.label);

  String get storageKey => name;

  static FeedbackStatus fromKey(String? key) {
    return FeedbackStatus.values.firstWhere(
      (s) => s.storageKey == key,
      orElse: () => FeedbackStatus.newFeedback,
    );
  }
}

class UserFeedback {
  final int? id;
  final FeedbackCategory category;
  final String subject;
  final String message;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String appVersion;
  final FeedbackStatus status;
  final String adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool syncedToServer;

  const UserFeedback({
    this.id,
    required this.category,
    required this.subject,
    required this.message,
    this.userName = '',
    this.userEmail = '',
    this.userPhone = '',
    this.appVersion = '',
    this.status = FeedbackStatus.newFeedback,
    this.adminNotes = '',
    required this.createdAt,
    this.updatedAt,
    this.syncedToServer = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category': category.name,
        'subject': subject,
        'message': message,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'appVersion': appVersion,
        'status': status.storageKey,
        'adminNotes': adminNotes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'syncedToServer': syncedToServer ? 1 : 0,
      };

  factory UserFeedback.fromMap(Map<String, dynamic> map) => UserFeedback(
        id: map['id'] as int?,
        category: FeedbackCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => FeedbackCategory.general,
        ),
        subject: map['subject'] as String? ?? '',
        message: map['message'] as String? ?? '',
        userName: map['userName'] as String? ?? '',
        userEmail: map['userEmail'] as String? ?? '',
        userPhone: map['userPhone'] as String? ?? '',
        appVersion: map['appVersion'] as String? ?? '',
        status: FeedbackStatus.fromKey(map['status'] as String?),
        adminNotes: map['adminNotes'] as String? ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'] as String)
            : null,
        syncedToServer: (map['syncedToServer'] as int? ?? 0) == 1,
      );

  UserFeedback copyWith({
    int? id,
    FeedbackCategory? category,
    String? subject,
    String? message,
    FeedbackStatus? status,
    String? adminNotes,
    DateTime? updatedAt,
    bool? syncedToServer,
  }) {
    return UserFeedback(
      id: id ?? this.id,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      appVersion: appVersion,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedToServer: syncedToServer ?? this.syncedToServer,
    );
  }
}
