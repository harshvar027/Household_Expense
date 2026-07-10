import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_feature_flags.dart';
import '../models/parsed_sms_transaction.dart';
import 'sms_transaction_parser.dart';

const smsQuickEntryPrefKey = 'sms_quick_entry_enabled';

/// Play-safe SMS capture using Google's SMS User Consent API (no READ_SMS).
class SmsListenerService {
  SmsListenerService._();

  static final SmsListenerService instance = SmsListenerService._();

  static const _eventChannel = EventChannel('com.householdexpense.app/sms_consent');
  static const _controlChannel =
      MethodChannel('com.householdexpense.app/sms_consent_control');

  final _transactionController =
      StreamController<ParsedSmsTransaction>.broadcast();

  Stream<ParsedSmsTransaction> get transactions => _transactionController.stream;

  StreamSubscription<dynamic>? _smsSubscription;
  bool _started = false;
  final Set<String> _recentFingerprints = {};

  bool get isSupported =>
      AppFeatureFlags.smsQuickEntryEnabled && !kIsWeb && Platform.isAndroid;

  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(smsQuickEntryPrefKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    if (!isSupported) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(smsQuickEntryPrefKey, enabled);
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }

  Future<void> start() async {
    if (!isSupported || _started) return;

    final enabled = await isEnabled();
    if (!enabled) return;

    await _smsSubscription?.cancel();
    _smsSubscription = _eventChannel.receiveBroadcastStream().listen(
      _handleConsentMessage,
      onError: (_) {},
    );

    await _controlChannel.invokeMethod<void>('startListening');
    _started = true;
  }

  Future<void> stop() async {
    await _smsSubscription?.cancel();
    _smsSubscription = null;

    if (isSupported) {
      try {
        await _controlChannel.invokeMethod<void>('stopListening');
      } catch (_) {}
    }
    _started = false;
  }

  Future<void> resumeIfEnabled() async {
    if (!await isEnabled()) return;
    _started = false;
    await start();
  }

  void _handleConsentMessage(dynamic event) {
    if (event is! String || event.trim().isEmpty) return;

    final parsed = SmsTransactionParser.parse(
      event,
      receivedAt: DateTime.now(),
    );
    if (parsed == null) return;
    if (!_rememberFingerprint(parsed.fingerprint)) return;

    _transactionController.add(parsed);
  }

  bool _rememberFingerprint(String fingerprint) {
    if (_recentFingerprints.contains(fingerprint)) return false;
    _recentFingerprints.add(fingerprint);
    if (_recentFingerprints.length > 50) {
      _recentFingerprints.remove(_recentFingerprints.first);
    }
    return true;
  }

  void dispose() {
    unawaited(stop());
    _transactionController.close();
  }
}
