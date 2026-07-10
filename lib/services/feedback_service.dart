import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../config/feedback_config.dart';
import '../database/database_helper.dart';
import '../models/user_feedback.dart';
import 'feedback_email_service.dart';
import 'feedback_sync_service.dart';

class FeedbackService {
  FeedbackService._();

  static final FeedbackService instance = FeedbackService._();

  final _db = DatabaseHelper.instance;
  final _sync = FeedbackSyncService.instance;

  Future<({int id, bool emailOpened})> submitAndEmail({
    required FeedbackCategory category,
    required String subject,
    required String message,
    String userName = '',
    String userEmail = '',
    String userPhone = '',
  }) async {
    final feedback = UserFeedback(
      category: category,
      subject: subject.trim(),
      message: message.trim(),
      userName: userName.trim(),
      userEmail: userEmail.trim(),
      userPhone: userPhone.trim(),
      appVersion: FeedbackConfig.appVersion,
      createdAt: DateTime.now(),
    );

    final id = await _db.insertFeedback(feedback);
    final saved = feedback.copyWith(id: id);

    final synced = await _sync.upload(saved);
    if (synced) {
      await _db.updateFeedback(saved.copyWith(syncedToServer: true));
    }

    final emailOpened = await FeedbackEmailService.instance.sendFeedbackEmail(
      saved,
    );
    return (id: id, emailOpened: emailOpened);
  }

  Future<int> submit({
    required FeedbackCategory category,
    required String subject,
    required String message,
    String userName = '',
    String userEmail = '',
    String userPhone = '',
  }) async {
    final feedback = UserFeedback(
      category: category,
      subject: subject.trim(),
      message: message.trim(),
      userName: userName.trim(),
      userEmail: userEmail.trim(),
      userPhone: userPhone.trim(),
      appVersion: FeedbackConfig.appVersion,
      createdAt: DateTime.now(),
    );

    final id = await _db.insertFeedback(feedback);
    final saved = feedback.copyWith(id: id);

    final synced = await _sync.upload(saved);
    if (synced) {
      await _db.updateFeedback(saved.copyWith(syncedToServer: true));
    }

    return id;
  }

  Future<List<UserFeedback>> getAll({FeedbackStatus? status}) =>
      _db.getAllFeedback(status: status);

  Future<void> updateStatus(int id, FeedbackStatus status, {String? adminNotes}) =>
      _db.updateFeedbackStatus(id, status, adminNotes: adminNotes);

  Future<void> deleteFeedback(int id) => _db.deleteFeedback(id);

  Future<int> importFromJson(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! List) return 0;

    var count = 0;
    for (final item in decoded) {
      if (item is! Map) continue;
      final feedback = UserFeedback.fromMap(Map<String, dynamic>.from(item));
      await _db.insertFeedback(feedback);
      count++;
    }
    return count;
  }

  Future<void> shareFeedback(UserFeedback feedback) async {
    final text = '''
Household Expense Feedback
Category: ${feedback.category.label}
Subject: ${feedback.subject}
From: ${feedback.userName} (${feedback.userEmail})
Date: ${feedback.createdAt.toIso8601String()}

${feedback.message}
''';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'App feedback: ${feedback.subject}',
      ),
    );
  }

  Future<String> exportAllAsJson() async {
    final all = await getAll();
    return const JsonEncoder.withIndent('  ').convert(
      all.map((f) => f.toMap()).toList(),
    );
  }

  Future<void> syncFromServer() async {
    if (!_sync.isConfigured) return;

    final remote = await _sync.fetchAll();
    for (final item in remote) {
      if (item.id == null) continue;
      final existing = await _db.getFeedbackById(item.id!);
      if (existing == null) {
        await _db.insertFeedback(item);
      }
    }
  }

  Future<Map<FeedbackStatus, int>> countByStatus() async {
    final all = await getAll();
    final counts = <FeedbackStatus, int>{};
    for (final s in FeedbackStatus.values) {
      counts[s] = all.where((f) => f.status == s).length;
    }
    return counts;
  }
}
