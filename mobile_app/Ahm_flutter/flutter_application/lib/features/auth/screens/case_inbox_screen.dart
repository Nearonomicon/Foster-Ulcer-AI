import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/case_detail_screen.dart';

enum InboxTab { needsReview, aiProcessed, recent }

class CaseInboxScreen extends StatefulWidget {
  const CaseInboxScreen({super.key});

  @override
  State<CaseInboxScreen> createState() => _CaseInboxScreenState();
}

class _CaseInboxScreenState extends State<CaseInboxScreen> {
  InboxTab tab = InboxTab.needsReview;

  // ✅ mock data (เหมือนเดิม)
  final List<CaseItem> items = const [
    CaseItem(
      patientName: "PAWMAN",
      caseId: "#ULC-9283",
      urgency: Urgency.high,
      aiStage: "Stage 3 Ulcer",
      confidencePct: 75,
      timeAgo: "1 mins ago",
      statusTag: "IMAGE_UPLOADED",
      hasAvatars: true,
      actionStyle: ActionStyle.primary,
    ),
    CaseItem(
      patientName: "Robert Miller",
      caseId: "#ULC-8812",
      urgency: Urgency.medium,
      aiStage: "Stage 2 Ulcer",
      confidencePct: 88,
      timeAgo: "2 hours ago",
      statusTag: "AI_DONE",
      metaIcon: Icons.image_outlined,
      metaText: "3 Images",
      actionStyle: ActionStyle.tonal,
    ),
    CaseItem(
      patientName: "Maria Garcia",
      caseId: "#ULC-7721",
      urgency: Urgency.routine,
      aiStage: "Stage 1 Ulcer",
      confidencePct: 91,
      timeAgo: "4 hours ago",
      statusTag: "AI_DONE",
      metaIcon: Icons.description_outlined,
      metaText: "Nurse Notes",
      actionStyle: ActionStyle.tonal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFEFF2F7);

    final filtered = _filterByTab(items, tab);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // top status bar mimic
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("9:41", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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

            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Case Inbox",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                ],
              ),
            ),

            // segmented chips
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _Chip(
                    selected: tab == InboxTab.needsReview,
                    label: "Needs Review",
                    icon: Icons.pending_actions,
                    primary: cs.primary,
                    onTap: () => setState(() => tab = InboxTab.needsReview),
                  ),
                  const Gap(10),
                  _Chip(
                    selected: tab == InboxTab.aiProcessed,
                    label: "AI Processed",
                    icon: Icons.auto_awesome,
                    primary: cs.primary,
                    onTap: () => setState(() => tab = InboxTab.aiProcessed),
                  ),
                  const Gap(10),
                  _Chip(
                    selected: tab == InboxTab.recent,
                    label: "Recent",
                    icon: Icons.history,
                    primary: cs.primary,
                    onTap: () => setState(() => tab = InboxTab.recent),
                  ),
                ],
              ),
            ),
            const Gap(14),

            // section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Pending Review (${filtered.length})",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                  Icon(Icons.filter_list, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                ],
              ),
            ),
            const Gap(10),

            // list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Gap(14),
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  return _CaseCard(
                    item: c,
                    primary: cs.primary,
                    cardColor: card,
                    borderColor: cardBorder,
                    isDark: isDark,
                    onReview: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CaseDetailScreen()),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // bottom nav (single item)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF0B1220) : Colors.white).withOpacity(0.92),
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
                  "INBOX",
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: cs.primary,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

List<CaseItem> _filterByTab(List<CaseItem> items, InboxTab tab) {
  // mock: ตอนนี้ยังไม่ filter จริง
  return items;
}

/* ---------------- Models ---------------- */

enum Urgency { high, medium, routine }
enum ActionStyle { primary, tonal }

class CaseItem {
  final String patientName;
  final String caseId;
  final Urgency urgency;
  final String aiStage;
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
    required this.urgency,
    required this.aiStage,
    required this.confidencePct,
    required this.timeAgo,
    required this.statusTag,
    this.hasAvatars = false,
    this.metaIcon,
    this.metaText,
    this.actionStyle = ActionStyle.primary,
  });
}

/* ---------------- UI pieces ---------------- */

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
    final bg = selected ? primary : (isDark ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.06));
    final fg = selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const Gap(6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
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
    final urgencyColor = switch (item.urgency) {
      Urgency.high => const Color(0xFFEF4444),
      Urgency.medium => const Color(0xFFF59E0B),
      Urgency.routine => (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
    };

    final badgeBg = switch (item.urgency) {
      Urgency.high => (isDark ? const Color(0xFF7F1D1D).withOpacity(0.35) : const Color(0xFFFEE2E2)),
      Urgency.medium => (isDark ? const Color(0xFF78350F).withOpacity(0.35) : const Color(0xFFFEF3C7)),
      Urgency.routine => (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
    };

    final badgeFg = switch (item.urgency) {
      Urgency.high => (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
      Urgency.medium => (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
      Urgency.routine => (isDark ? Colors.white54 : Colors.black45),
    };

    final badgeText = switch (item.urgency) {
      Urgency.high => "HIGH URGENCY",
      Urgency.medium => "MEDIUM",
      Urgency.routine => "ROUTINE",
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
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  ),
                ),
              ),
              Padding(
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
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const Gap(2),
                              Text(
                                "ID: ${item.caseId}",
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
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
                            title: "AI DETECTION",
                            line1: item.aiStage,
                            line2: "${item.confidencePct}% Confidence",
                            line2Color: primary,
                            isDark: isDark,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _MiniBox(
                            title: "TIME ELAPSED",
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
                        if (item.hasAvatars)
                          Row(
                            children: [
                              _AvatarBubble(isDark: isDark),
                              Transform.translate(offset: const Offset(-8, 0), child: _AvatarBubble(isDark: isDark)),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(item.metaIcon ?? Icons.info_outline, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                              const Gap(6),
                              Text(
                                item.metaText ?? "",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45),
                              ),
                            ],
                          ),
                        _ReviewButton(
                          style: item.actionStyle,
                          primary: primary,
                          isDark: isDark,
                          onTap: onReview,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
    this.line2Color,
    required this.isDark,
  });

  final String title;
  final String line1;
  final String line2;
  final Color? line2Color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF111B2C) : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38)),
          const Gap(6),
          Text(line1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const Gap(2),
          Text(line2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: line2Color ?? (isDark ? Colors.white54 : Colors.black45))),
        ],
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
  });

  final ActionStyle style;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = style == ActionStyle.primary ? primary : (isDark ? primary.withOpacity(0.18) : primary.withOpacity(0.12));
    final fg = style == ActionStyle.primary ? Colors.white : primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Text("Review Case", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg)),
            const Gap(6),
            Icon(Icons.chevron_right, size: 18, color: fg),
          ],
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.06),
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? const Color(0xFF0B1220) : Colors.white, width: 2),
      ),
      child: Icon(Icons.person, size: 18, color: isDark ? Colors.white38 : Colors.black38),
    );
  }
}
