import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/case_detail_screen.dart';
import 'package:flutter_application/features/auth/services/case_service.dart';
import 'package:flutter_application/shared/app_localizations.dart';
import 'dart:convert';

enum InboxTab { needsReview, sentToNurse }
enum Urgency { high, medium, routine }
enum ActionStyle { primary, tonal }

class CaseInboxScreen extends StatefulWidget {
  const CaseInboxScreen({super.key});

  @override
  State<CaseInboxScreen> createState() => _CaseInboxScreenState();
}

class _CaseInboxScreenState extends State<CaseInboxScreen> {
  InboxTab tab = InboxTab.needsReview;

  final CaseService _caseService = CaseService();

  bool _isLoading = true;
  String? _error;

  List<CaseItem> _needsReviewItems = [];
  List<CaseItem> _sentToNurseItems = [];

  @override
  void initState() {
    super.initState();
    _loadInboxData();
  }

  Future<void> _loadInboxData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final needsReviewRes =
          await _caseService.getCasesByStatus("DOCTOR_REVIEW");
      final sentToNurseRes =
          await _caseService.getCasesByStatus("TREATMENT_SENT");

      print(
        'CaseInboxScreen DOCTOR_REVIEW payload: ${jsonEncode(needsReviewRes)}',
      );
      print(
        'CaseInboxScreen TREATMENT_SENT payload: ${jsonEncode(sentToNurseRes)}',
      );

      final needsItems = _mapItemsFromResponse(needsReviewRes);
      final sentItems = _mapItemsFromResponse(sentToNurseRes);

      if (!mounted) return;

      setState(() {
        _needsReviewItems = needsItems;
        _sentToNurseItems = sentItems;
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

  List<CaseItem> _mapItemsFromResponse(Map<String, dynamic> response) {
    final data =
        (response["data"] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final items = (data["items"] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return items.map((item) {
      final patientName = (item["patient_name"] ?? "Unknown").toString();
      final rawCaseId = (item["case_id"] ?? "").toString();
      final displayCaseId =
          rawCaseId.startsWith("#") ? rawCaseId : "#$rawCaseId";
      final urgencyRaw = (item["urgency"] ?? "").toString().toUpperCase();
      final aiStage = (item["ai_stage"] ?? "Unknown Stage").toString();
      final aiMetricPills = _buildAiMetricPills(aiStage);

      final aiConfidence = item["ai_confidence"];
      final confidencePct =
          aiConfidence is num ? (aiConfidence * 100).round() : 0;

      final statusTag = (item["status"] ?? "UNKNOWN").toString();
      final timeAgo = (item["time_elapsed_text"] ?? "-").toString();

      final imageCount = item["image_count"];
      final metaText = imageCount != null ? "$imageCount Images" : "No Images";

      return CaseItem(
        patientName: patientName,
        caseId: displayCaseId,
        rawCaseId: rawCaseId,
        urgency: _mapUrgency(urgencyRaw),
        aiStage: aiStage,
        aiMetricPills: aiMetricPills,
        confidencePct: confidencePct,
        timeAgo: timeAgo,
        statusTag: statusTag,
        hasAvatars: false,
        metaIcon: Icons.image_outlined,
        metaText: metaText,
        actionStyle: statusTag == "DOCTOR_REVIEW"
            ? ActionStyle.primary
            : ActionStyle.tonal,
      );
    }).toList();
  }

  List<CaseItem> _getItemsForCurrentTab() {
    switch (tab) {
      case InboxTab.needsReview:
        return _needsReviewItems;
      case InboxTab.sentToNurse:
        return _sentToNurseItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF1F2A3A) : const Color(0xFFEFF2F7);

    final filtered = _getItemsForCurrentTab();

    final tabNeedsReview = context.tr('inbox.tab.needs_review');
    final tabSentToNurse = "Sent to Nurse";

    final sectionTitle = switch (tab) {
      InboxTab.needsReview => context.tr('inbox.section.pending_review'),
      InboxTab.sentToNurse => "Sent to Nurse",
    };

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "9:41",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.signal_cellular_alt, size: 18),
                      SizedBox(width: 6),
                      Icon(Icons.wifi, size: 18),
                      SizedBox(width: 6),
                      Icon(Icons.battery_full, size: 18),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('inbox.title'),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadInboxData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _Chip(
                    selected: tab == InboxTab.needsReview,
                    label: tabNeedsReview,
                    icon: Icons.pending_actions,
                    primary: cs.primary,
                    onTap: () => setState(() => tab = InboxTab.needsReview),
                  ),
                  const Gap(10),
                  _Chip(
                    selected: tab == InboxTab.sentToNurse,
                    label: tabSentToNurse,
                    icon: Icons.send_outlined,
                    primary: cs.primary,
                    onTap: () => setState(() => tab = InboxTab.sentToNurse),
                  ),
                ],
              ),
            ),
            const Gap(14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "$sectionTitle (${filtered.length})",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
            const Gap(10),
            Expanded(
              child: _buildBody(
                isDark: isDark,
                cs: cs,
                card: card,
                cardBorder: cardBorder,
                items: filtered,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        decoration: BoxDecoration(
          color:
              (isDark ? const Color(0xFF0B1220) : Colors.white).withOpacity(0.92),
          border: Border(top: BorderSide(color: cardBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, color: cs.primary),
                const Gap(4),
                Text(
                  context.tr('inbox.nav.inbox'),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required ColorScheme cs,
    required Color card,
    required Color cardBorder,
    required List<CaseItem> items,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const Gap(12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: _loadInboxData,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No cases found",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Gap(14),
      itemBuilder: (context, i) {
        final c = items[i];
        return _CaseCard(
          item: c,
          primary: cs.primary,
          cardColor: card,
          borderColor: cardBorder,
          isDark: isDark,
          onReview: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CaseDetailScreen(caseId: c.rawCaseId),
              ),
            );

            if (!mounted) return;
            _loadInboxData();
          },
        );
      },
    );
  }
}

Urgency _mapUrgency(String urgencyRaw) {
  switch (urgencyRaw) {
    case "HIGH":
    case "HIGH_URGENT":
      return Urgency.high;
    case "MEDIUM":
      return Urgency.medium;
    default:
      return Urgency.routine;
  }
}

List<String> _buildAiMetricPills(String aiStage) {
  final metrics = <String, String>{};

  for (final line in aiStage.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final parts = trimmed.split(':');
    if (parts.length < 2) continue;

    final key = parts.first.trim();
    final value = parts.sublist(1).join(':').trim();
    metrics[key] = value;
  }

  final pills = <String>[];

  if (metrics.containsKey('SINBAD')) {
    pills.add('SINBAD: ${metrics['SINBAD']}');
  }

  final wifiParts = <String>[];
  if (metrics.containsKey('W')) wifiParts.add('W: ${metrics['W']}');
  if (metrics.containsKey('I')) wifiParts.add('I: ${metrics['I']}');
  if (metrics.containsKey('fI')) wifiParts.add('fI: ${metrics['fI']}');
  if (wifiParts.isNotEmpty) {
    pills.add(wifiParts.join('  '));
  }

  if (metrics.containsKey('IDSA')) {
    pills.add('IDSA: ${metrics['IDSA']}');
  }

  if (pills.isEmpty && aiStage.trim().isNotEmpty) {
    pills.add(aiStage.trim());
  }

  return pills;
}

class CaseItem {
  final String patientName;
  final String caseId;
  final String rawCaseId;
  final Urgency urgency;
  final String aiStage;
  final List<String> aiMetricPills;
  final int confidencePct;
  final String timeAgo;
  final String statusTag;
  final bool hasAvatars;
  final IconData? metaIcon;
  final String? metaText;
  final ActionStyle actionStyle;

  const CaseItem({
    required this.patientName,
    required this.caseId,
    required this.rawCaseId,
    required this.urgency,
    required this.aiStage,
    required this.aiMetricPills,
    required this.confidencePct,
    required this.timeAgo,
    required this.statusTag,
    this.hasAvatars = false,
    this.metaIcon,
    this.metaText,
    this.actionStyle = ActionStyle.primary,
  });
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? primary
        : (isDark ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.06));
    final fg =
        selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.primary,
    required this.cardColor,
    required this.borderColor,
    required this.isDark,
    required this.onReview,
  });

  final CaseItem item;
  final Color primary;
  final Color cardColor;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final badgeBg = switch (item.urgency) {
      Urgency.high => (isDark
          ? const Color(0xFF7F1D1D).withOpacity(0.35)
          : const Color(0xFFFEE2E2)),
      Urgency.medium => (isDark
          ? const Color(0xFF78350F).withOpacity(0.35)
          : const Color(0xFFFEF3C7)),
      Urgency.routine =>
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
    };

    final badgeFg = switch (item.urgency) {
      Urgency.high =>
        (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
      Urgency.medium =>
        (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
      Urgency.routine => (isDark ? Colors.white54 : Colors.black45),
    };

    final badgeText = switch (item.urgency) {
      Urgency.high => context.tr('inbox.badge.high_urgency'),
      Urgency.medium => context.tr('inbox.badge.medium'),
      Urgency.routine => context.tr('inbox.badge.routine'),
    };

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.patientName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color:
                                  isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const Gap(2),
                          Text(
                            "${context.tr('inbox.id_label')}: ${item.caseId}",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniBox(
                        title: context.tr('inbox.box.ai_detection'),
                        line1: item.aiStage,
                        pills: item.aiMetricPills,
                        line2:
                            "${item.confidencePct}% ${context.tr('inbox.box.confidence')}",
                        line2Color: primary,
                        isDark: isDark,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _MiniBox(
                        title: context.tr('inbox.box.time_elapsed'),
                        line1: item.timeAgo,
                        line2: item.statusTag,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.metaIcon ?? Icons.info_outline,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const Gap(6),
                        Text(
                          item.metaText ?? "",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    _ReviewButton(
                      style: item.actionStyle,
                      primary: primary,
                      isDark: isDark,
                      onTap: onReview,
                      label: context.tr('inbox.review_case'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBox extends StatelessWidget {
  const _MiniBox({
    required this.title,
    required this.line1,
    required this.line2,
    this.pills = const [],
    this.line2Color,
    required this.isDark,
  });

  final String title;
  final String line1;
  final String line2;
  final List<String> pills;
  final Color? line2Color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF111B2C) : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const Gap(6),
          if (pills.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pills
                  .map((pill) => _MetricPill(text: pill, isDark: isDark))
                  .toList(),
            )
          else
            Text(
              line1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          const Gap(2),
          Text(
            line2,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: line2Color ?? (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.style,
    required this.primary,
    required this.isDark,
    required this.onTap,
    required this.label,
  });

  final ActionStyle style;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bg = style == ActionStyle.primary
        ? primary
        : (isDark ? primary.withOpacity(0.18) : primary.withOpacity(0.12));
    final fg = style == ActionStyle.primary ? Colors.white : primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
            const Gap(6),
            Icon(Icons.chevron_right, size: 18, color: fg),
          ],
        ),
      ),
    );
  }
}
