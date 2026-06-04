import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:flutter_application/features/auth/services/case_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final CaseService _caseService = CaseService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _caseService.listDoctorNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const Gap(12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: _loadNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              const Gap(16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Gap(8),
              Text(
                'Doctor review notifications will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Gap(12),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return _NotificationCard(
            notification: item,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isDark,
  });

  final Map<String, dynamic> notification;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final title = (notification['title'] ?? 'Notification').toString();
    final message = (notification['message'] ?? '').toString();
    final patientName = (notification['patient_name'] ?? '').toString().trim();
    final caseId = (notification['case_id'] ?? '').toString().trim();
    final urgency = (notification['urgency'] ?? '').toString().trim().toUpperCase();
    final status = (notification['status'] ?? 'UNREAD').toString().trim().toUpperCase();
    final createdAt = _formatTimestamp(notification['created_at']);

    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF273449) : const Color(0xFFE5E7EB);
    final unread = status == 'UNREAD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: unread
                      ? const Color(0xFFDBEAFE)
                      : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: unread
                      ? const Color(0xFF2563EB)
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              _NotificationStatusBadge(
                text: status,
                isDark: isDark,
                unread: unread,
              ),
            ],
          ),
          const Gap(14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (patientName.isNotEmpty)
                _MetaPill(
                  icon: Icons.person_outline,
                  text: patientName,
                  isDark: isDark,
                ),
              if (caseId.isNotEmpty)
                _MetaPill(
                  icon: Icons.badge_outlined,
                  text: caseId,
                  isDark: isDark,
                ),
              if (urgency.isNotEmpty)
                _MetaPill(
                  icon: Icons.priority_high_rounded,
                  text: urgency,
                  isDark: isDark,
                  emphasis: urgency == 'HIGH' || urgency == 'HIGH_URGENT',
                ),
            ],
          ),
          const Gap(12),
          Text(
            createdAt,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
    required this.isDark,
    this.emphasis = false,
  });

  final IconData icon;
  final String text;
  final bool isDark;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final bg = emphasis
        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
        : (isDark ? Colors.white10 : const Color(0xFFF3F4F6));
    final fg = emphasis
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
        : (isDark ? Colors.white70 : const Color(0xFF334155));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const Gap(6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationStatusBadge extends StatelessWidget {
  const _NotificationStatusBadge({
    required this.text,
    required this.isDark,
    required this.unread,
  });

  final String text;
  final bool isDark;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final bg = unread
        ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE))
        : (isDark ? Colors.white10 : const Color(0xFFF3F4F6));
    final fg = unread
        ? (isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8))
        : (isDark ? Colors.white54 : Colors.black45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: fg,
        ),
      ),
    );
  }
}

String _formatTimestamp(dynamic value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return '-';

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  final now = DateTime.now().toUtc();
  final diff = now.difference(parsed.toUtc());

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} day ago${diff.inDays == 1 ? '' : 's'}';

  final local = parsed.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$mm-$dd $hh:$min';
}
