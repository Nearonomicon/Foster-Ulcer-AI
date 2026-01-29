import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/review_treatment_plan_screen.dart';

/// ---------------- MOCK CASE (from your JSON) ----------------
final Map<String, dynamic> mockCase = {
  "patient_profile": {
    "patient_name": "PAWMAN",
    "phone_no": "0861948565",
    "dob": "03/02/2001",
    "gender": "male",
    "height_cm": "170",
    "weight_kg": "60",
    "occupation": "Data Analysis",
    "medical_history": "Diabetes",
    "created_at": "2026-01-28 11:33:20"
  },
  "selected_patient": null,
  "nurse_reviewed": {
    "location_primary": "toe",
    "location_detail": "plantar aspect of the great toe",
    "wound_type": "ulcer",
    "shape": "round",
    "size_width_cm": 1.5,
    "size_length_cm": 1.5,
    "depth_category": "full_thickness",
    "bed_slough_pct": 10,
    "bed_necrotic_pct": 5,
    "edge_description": "calloused",
    "periwound_status": "erythematous",
    "discharge_volume": "minimal",
    "discharge_type": "minimal",
    "odor_presence": "faint",
    "pain_score": 4,
    "has_infection": false,
    "skin_condition": "dry",
    "temperature": "37",
    "blood_pressure": "120/80",
    "heart_rate": "80"
  },
  "ai_analysis": {
    "AI_analysis": {
      "creator": "Gemini AI",
      "wound_stage": "STAGE 3",
      "description":
          "1. Patient & Clinical Overview: The patient is a 24-year-old male with a history of diabetes. Vitals are within normal limits (Temperature: 37°C, Blood Pressure: 120/80 mmHg, Heart Rate: 80 bpm). Risk factors include diabetes.\n\n"
          "2. Formal Wound Description: The wound is located on the plantar aspect of the great toe. It is a round ulcer, measuring 1.5 cm x 1.5 cm. The nurse reports full-thickness depth, 10% slough, 5% necrotic tissue, calloused edges, erythematous periwound, minimal discharge (volume and type), faint odor, and a pain score of 4.\n\n"
          "3. Image Analysis Insights: The image shows a deep ulcer with some slough present in the wound bed. There is surrounding erythema. The edges appear calloused as reported.\n\n"
          "4. Wound Staging: Based on the information provided and the image, the wound is staged as Wagner 2 (deep to tendon/capsule, no abscess/osteomyelitis). This could correspond to a University of Texas (UT) grade 2, stage A if there is no infection or ischemia.",
      "diagnosis":
          "Diabetic foot ulcer on the plantar aspect of the great toe, full-thickness, with surrounding erythema. Concern for possible deep tissue involvement. Further assessment needed to rule out osteomyelitis.",
      "confidence": 0.75,
      "treatment_plan":
          "The treatment plan should focus on offloading, debridement of non-viable tissue, maintaining a moist wound environment, assessing for infection, ensuring adequate vascular supply, managing blood glucose levels, controlling pain, and educating the patient. Given the depth of the ulcer, close monitoring is essential."
    },
    "treatment_plan": {
      "plan_text":
          "1. Offload the affected toe with appropriate footwear or padding.\n"
          "2. Debride non-viable tissue (slough and necrotic tissue) to promote healing.\n"
          "3. Apply a moist wound dressing to maintain a healthy wound environment.\n"
          "4. Monitor for signs of infection.\n"
          "5. Ensure adequate blood glucose control.\n"
          "6. Educate the patient on proper foot care.",
      "followup_days": 3,
      "status": "DRAFT",
      "plan_tasks": [
        {
          "task_text": "Apply appropriate offloading device/padding to the affected toe.",
          "status": "DRAFT",
          "task_due": "2026-01-28T16:00:00+07:00"
        },
        {
          "task_text": "Debride non-viable tissue from the wound bed.",
          "status": "DRAFT",
          "task_due": "2026-01-29T10:00:00+07:00"
        },
        {
          "task_text": "Apply a moist wound dressing (e.g., hydrogel or alginate).",
          "status": "DRAFT",
          "task_due": "2026-01-28T16:00:00+07:00"
        },
        {
          "task_text": "Assess wound for signs of infection at each dressing change.",
          "status": "DRAFT",
          "task_due": "2026-01-29T10:00:00+07:00"
        },
        {
          "task_text":
              "Check patient's blood glucose levels and coordinate with primary care provider for optimal control.",
          "status": "DRAFT",
          "task_due": "2026-01-29T10:00:00+07:00"
        },
        {
          "task_text": "Educate patient on proper foot care, offloading, and blood glucose management.",
          "status": "DRAFT",
          "task_due": "2026-01-29T10:00:00+07:00"
        }
      ]
    }
  },
  "urgency": "high_urgent",
  "meta": {"sent_at": "2026-01-28 11:34:56"}
};

class TreatmentPlanDispatchScreen extends StatelessWidget {
  const TreatmentPlanDispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF273449) : const Color(0xFFE6EBF2);

    const ai = Color(0xFF8B5CF6); // purple
    final subtle = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

    // -------- bind mock data --------
    final patient = (mockCase["patient_profile"] ?? {}) as Map<String, dynamic>;
    final nurseReviewed = (mockCase["nurse_reviewed"] ?? {}) as Map<String, dynamic>;
    final aiAnalysisRoot = (mockCase["ai_analysis"] ?? {}) as Map<String, dynamic>;
    final aiAnalysis = (aiAnalysisRoot["AI_analysis"] ?? {}) as Map<String, dynamic>;
    final plan = (aiAnalysisRoot["treatment_plan"] ?? {}) as Map<String, dynamic>;
    final tasks = (plan["plan_tasks"] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    final patientName = (patient["patient_name"] ?? "Unknown").toString();
    final medicalHistory = (patient["medical_history"] ?? "-").toString();

    const caseId = "#WC-8821";
    final stageRaw = (aiAnalysis["wound_stage"] ?? "STAGE -").toString();
    final stageText = _normalizeStage(stageRaw);
    final diagnosisText = (aiAnalysis["diagnosis"] ?? "Diagnosis not available").toString();
    final stagingDesc = (aiAnalysis["description"] ?? "").toString();

    final followupDays = _toInt(plan["followup_days"], fallback: 3);
    final urgency = (mockCase["urgency"] ?? "").toString();
    final isHighUrgent = urgency == "high_urgent";

    final urgencyBg = isHighUrgent
        ? (isDark ? const Color(0xFF7F1D1D).withOpacity(0.35) : const Color(0xFFFEE2E2))
        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05));
    final urgencyFg =
        isHighUrgent ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)) : (isDark ? Colors.white60 : Colors.black54);
    final urgencyLabel = isHighUrgent ? "HIGH URGENCY" : "NORMAL";

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _StatusBarMimic(isDark: isDark)),
            SliverToBoxAdapter(
              child: _TopBar(
                isDark: isDark,
                border: border,
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _PatientHeader(
                      isDark: isDark,
                      primary: cs.primary,
                      name: patientName,
                      caseId: caseId,
                      conditionTag: medicalHistory.toUpperCase(),
                      conditionBg: urgencyBg,
                      conditionFg: urgencyFg,
                      conditionLabel: urgencyLabel,
                    ),

                    const Gap(18),

                    _SectionTitle(
                      icon: Icons.analytics_outlined,
                      text: "Diagnosis & Staging",
                      isDark: isDark,
                      iconColor: cs.primary,
                    ),
                    const Gap(10),
                    _Card(
                      card: card,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stageText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isHighUrgent
                                      ? (isDark
                                          ? const Color(0xFF78350F).withOpacity(0.35)
                                          : const Color(0xFFFEF3C7))
                                      : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isHighUrgent ? "ACTION REQUIRED" : "STABLE",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                    color: isHighUrgent
                                        ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          Text(
                            diagnosisText,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(10),
                          Text(
                            stagingDesc.isEmpty ? _buildWoundSummary(nurseReviewed) : stagingDesc,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(
                          icon: Icons.list_alt_outlined,
                          text: "Treatment Schedule",
                          isDark: isDark,
                          iconColor: cs.primary,
                        ),
                        Text(
                          "${tasks.length} TASKS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),

                    ...List.generate(tasks.length, (i) {
                      final t = tasks[i];
                      final title = (t["task_text"] ?? "Task").toString();
                      final status = (t["status"] ?? "DRAFT").toString();
                      final due = (t["task_due"] ?? "").toString();

                      return Padding(
                        padding: EdgeInsets.only(bottom: i == tasks.length - 1 ? 0 : 12),
                        child: _TaskCard(
                          isDark: isDark,
                          card: card,
                          border: border,
                          num: "${i + 1}",
                          title: title,
                          desc: due.isEmpty ? "Status: $status" : "Due: ${_fmtDue(due)} • Status: $status",
                          badgeText: "AI Suggested",
                          badgeColor: ai,
                          badgeIcon: Icons.auto_awesome,
                          glow: true,
                        ),
                      );
                    }),

                    const Gap(12),

                    Center(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Add Task (mock)")),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black26,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 20, color: isDark ? Colors.white60 : Colors.black54),
                              const Gap(8),
                              Text(
                                "Add Task",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Gap(18),

                    _SectionTitle(
                      icon: Icons.speed,
                      text: "Clinical Cadence",
                      isDark: isDark,
                      iconColor: cs.primary,
                    ),
                    const Gap(10),
                    
                    // Simplified to show only Frequency
                    _Card(
                      card: card,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.event_repeat, color: cs.primary),
                          const Gap(10),
                          Text(
                            "FREQUENCY",
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.9,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            "Every $followupDays Days",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(18),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReviewTreatmentPlanScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 10),
                          Text(
                            "Finalize and send plan to nurse",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF172554).withOpacity(0.35) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cs.primary.withOpacity(0.18)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: isDark ? Colors.lightBlueAccent : const Color(0xFF2563EB)),
                          const Gap(10),
                          const Expanded(
                            child: Text(
                              "Confirming this action will finalize the clinical pathway and update case status to PLAN_SENT. "
                              "The nurse will receive a priority notification on their handset immediately.",
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(18),

                    Center(
                      child: Container(
                        width: 120,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const Gap(10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- helpers ---------------- */

String _normalizeStage(String raw) {
  final up = raw.trim().toUpperCase();
  if (up.startsWith("STAGE")) {
    final num = raw.replaceAll(RegExp(r"[^0-9]"), "");
    if (num.isNotEmpty) return "Stage $num";
    return "Stage -";
  }
  return raw;
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _fmtDue(String iso) {
  final s = iso.replaceAll("T", " ");
  final noTz = s.split("+").first;
  final parts = noTz.split(":");
  if (parts.length >= 2) {
    return "${parts[0]}:${parts[1]}";
  }
  return noTz;
}

String _buildWoundSummary(Map<String, dynamic> nurse) {
  final loc = (nurse["location_detail"] ?? nurse["location_primary"] ?? "-").toString();
  final type = (nurse["wound_type"] ?? "-").toString();
  final w = nurse["size_width_cm"];
  final l = nurse["size_length_cm"];
  final depth = (nurse["depth_category"] ?? "-").toString();
  final slough = (nurse["bed_slough_pct"] ?? "-").toString();
  final nec = (nurse["bed_necrotic_pct"] ?? "-").toString();
  final peri = (nurse["periwound_status"] ?? "-").toString();
  return "Wound: $type • Location: $loc • Size: ${w ?? "-"} x ${l ?? "-"} cm • Depth: $depth • Slough: $slough% • Necrotic: $nec% • Periwound: $peri";
}

/* ---------------- common widgets (private) ---------------- */

class _StatusBarMimic extends StatelessWidget {
  const _StatusBarMimic({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("9:41", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: fg)),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 18, color: fg),
              const SizedBox(width: 6),
              Icon(Icons.wifi, size: 18, color: fg),
              const SizedBox(width: 6),
              Icon(Icons.battery_full, size: 18, color: fg),
            ],
          )
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isDark,
    required this.border,
    required this.onBack,
  });

  final bool isDark;
  final Color border;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xCC0F172A)
        : const Color(0xCCF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border.withOpacity(0.65))),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: Icon(Icons.chevron_left, color: cs.primary),
            label: Text(
              "Back",
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
            ),
          ),
          const Spacer(),
          const Text("Dispatch Plan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const Spacer(),
          const SizedBox(width: 64),
        ],
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({
    required this.isDark,
    required this.primary,
    required this.name,
    required this.caseId,
    required this.conditionTag,
    required this.conditionBg,
    required this.conditionFg,
    required this.conditionLabel,
  });

  final bool isDark;
  final Color primary;
  final String name;
  final String caseId;
  final String conditionTag;
  final Color conditionBg;
  final Color conditionFg;
  final String conditionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, size: 52, color: isDark ? Colors.white38 : Colors.black38),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    width: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const Gap(6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _TinyTag(
              text: "CASE $caseId",
              bg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              fg: isDark ? Colors.white60 : Colors.black54,
            ),
            _TinyTag(
              text: conditionTag.isEmpty ? "CONDITION" : conditionTag,
              bg: conditionBg,
              fg: conditionFg,
            ),
            _TinyTag(
              text: conditionLabel,
              bg: conditionBg,
              fg: conditionFg,
            ),
          ],
        ),
      ],
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: fg)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.text,
    required this.isDark,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final bool isDark;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const Gap(8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.card,
    required this.border,
    required this.child,
  });

  final Color card;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.isDark,
    required this.card,
    required this.border,
    required this.num,
    required this.title,
    required this.desc,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeIcon,
    required this.glow,
  });

  final bool isDark;
  final Color card;
  final Color border;
  final String num;
  final String title;
  final String desc;
  final String badgeText;
  final Color badgeColor;
  final IconData badgeIcon;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.10),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(isDark ? 0.18 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 14, color: badgeColor),
                          const Gap(6),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  desc,
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
        ],
      ),
    );
  }
}