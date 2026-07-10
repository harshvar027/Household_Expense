import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/user_feedback.dart';
import '../../services/admin_auth_service.dart';
import '../../services/feedback_service.dart';
import '../../services/feedback_sync_service.dart';
import '../../theme/app_theme.dart';
import 'admin_login_screen.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<UserFeedback> _items = [];
  FeedbackStatus? _filter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _load();
  }

  Future<void> _checkAuth() async {
    if (!await AdminAuthService.instance.isAdminLoggedIn()) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await FeedbackService.instance.getAll(status: _filter);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _syncFromServer() async {
    if (!FeedbackSyncService.instance.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set FeedbackConfig.syncBaseUrl to enable remote sync'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await FeedbackService.instance.syncFromServer();
    await _load();
  }

  Future<void> _exportAll() async {
    final json = await FeedbackService.instance.exportAllAsJson();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/feedback_export.json');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Feedback export',
      ),
    );
  }

  Future<void> _importFile() async {
    const typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final content = await File(file.path).readAsString();
    final count = await FeedbackService.instance.importFromJson(content);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $count feedback entries')),
    );
    await _load();
  }

  Future<void> _logout() async {
    await AdminAuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  Future<void> _openDetail(UserFeedback feedback) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FeedbackDetailSheet(
        feedback: feedback,
        onUpdated: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Feedback inbox'),
        actions: [
          IconButton(
            tooltip: 'Sync from server',
            onPressed: _syncFromServer,
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'export':
                  await _exportAll();
                case 'import':
                  await _importFile();
                case 'logout':
                  await _logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export all JSON')),
              PopupMenuItem(value: 'import', child: Text('Import JSON file')),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) {
                    setState(() => _filter = null);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ...FeedbackStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.label),
                      selected: _filter == s,
                      onSelected: (_) {
                        setState(() => _filter = s);
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          'No feedback yet.\nUsers can submit from Menu → Help & About.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _FeedbackTile(
                            feedback: item,
                            onTap: () => _openDetail(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final UserFeedback feedback;
  final VoidCallback onTap;

  const _FeedbackTile({required this.feedback, required this.onTap});

  Color _statusColor(FeedbackStatus s) => switch (s) {
        FeedbackStatus.newFeedback => AppColors.warning,
        FeedbackStatus.inProgress => AppColors.primary,
        FeedbackStatus.resolved => AppColors.income,
        FeedbackStatus.closed => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _statusColor(feedback.status).withValues(alpha: 0.15),
          child: Icon(
            feedback.category == FeedbackCategory.bug
                ? Icons.bug_report_outlined
                : feedback.category == FeedbackCategory.feature
                    ? Icons.lightbulb_outline
                    : Icons.chat_bubble_outline,
            color: _statusColor(feedback.status),
            size: 20,
          ),
        ),
        title: Text(
          feedback.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${feedback.category.label} · ${feedback.userName.isNotEmpty ? feedback.userName : 'Anonymous'}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              feedback.status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _statusColor(feedback.status),
              ),
            ),
            Text(
              _formatDate(feedback.createdAt),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _FeedbackDetailSheet extends StatefulWidget {
  final UserFeedback feedback;
  final VoidCallback onUpdated;

  const _FeedbackDetailSheet({
    required this.feedback,
    required this.onUpdated,
  });

  @override
  State<_FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends State<_FeedbackDetailSheet> {
  late FeedbackStatus _status = widget.feedback.status;
  late final TextEditingController _notesController =
      TextEditingController(text: widget.feedback.adminNotes);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await FeedbackService.instance.updateStatus(
      widget.feedback.id!,
      _status,
      adminNotes: _notesController.text.trim(),
    );
    widget.onUpdated();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete feedback?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (ok != true || widget.feedback.id == null) return;
    await FeedbackService.instance.deleteFeedback(widget.feedback.id!);
    widget.onUpdated();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feedback;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              f.subject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${f.category.label} · v${f.appVersion} · ${_formatDate(f.createdAt)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (f.userName.isNotEmpty || f.userEmail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${f.userName} · ${f.userEmail}${f.userPhone.isNotEmpty ? ' · ${f.userPhone}' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Text(f.message),
            const SizedBox(height: 20),
            DropdownButtonFormField<FeedbackStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: FeedbackStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Developer notes',
                hintText: 'Plan, priority, release version…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => FeedbackService.instance.shareFeedback(f),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share via email/apps'),
            ),
            TextButton(
              onPressed: _delete,
              child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
