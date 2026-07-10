import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/feedback_config.dart';
import '../models/user_feedback.dart';

/// Optional HTTP sync when [FeedbackConfig.syncBaseUrl] is configured.
class FeedbackSyncService {
  FeedbackSyncService._();

  static final FeedbackSyncService instance = FeedbackSyncService._();

  bool get isConfigured => FeedbackConfig.syncBaseUrl.isNotEmpty;

  Future<bool> upload(UserFeedback feedback) async {
    if (!isConfigured) return false;

    try {
      final client = HttpClient();
      final uri = Uri.parse('${FeedbackConfig.syncBaseUrl}/feedback');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(_toPayload(feedback)));
      final response = await request.close();
      client.close();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Feedback upload failed: $e');
      return false;
    }
  }

  Future<List<UserFeedback>> fetchAll() async {
    if (!isConfigured) return [];

    try {
      final client = HttpClient();
      final uri = Uri.parse('${FeedbackConfig.syncBaseUrl}/feedback');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(body);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((m) => UserFeedback.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('Feedback fetch failed: $e');
      return [];
    }
  }

  Map<String, dynamic> _toPayload(UserFeedback f) => {
        'id': f.id,
        'category': f.category.name,
        'subject': f.subject,
        'message': f.message,
        'userName': f.userName,
        'userEmail': f.userEmail,
        'userPhone': f.userPhone,
        'appVersion': f.appVersion,
        'status': f.status.storageKey,
        'createdAt': f.createdAt.toIso8601String(),
      };
}
