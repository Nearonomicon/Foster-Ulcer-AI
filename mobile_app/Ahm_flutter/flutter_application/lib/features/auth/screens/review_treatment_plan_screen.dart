import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:signature/signature.dart';

class ReviewTreatmentPlanScreen extends StatefulWidget {
  const ReviewTreatmentPlanScreen({super.key});

  @override
  State<ReviewTreatmentPlanScreen> createState() => _ReviewTreatmentPlanScreenState();
}

class _ReviewTreatmentPlanScreenState extends State<ReviewTreatmentPlanScreen> {
  // ----------------------------
  // MOCK CASE DATA (from your JSON)
  // ----------------------------
  final Map<String, dynamic> mock = const {
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
            "1. Patient & Clinical Overview: The patient is a 24-year-old male with a history of diabetes. Vitals are within normal limits (Temperature: 37°C, Blood Pressure: 120/80 mmHg, Heart Rate: 80 bpm). Risk factors include diabetes.\n"
                "2. Formal Wound Description: The wound is located on the plantar aspect of the great toe. It is a round ulcer, measuring 1.5 cm x 1.5 cm. The nurse reports full-thickness depth, 10% slough, 5% necrotic tissue, calloused edges, erythematous periwound, minimal discharge (volume and type), faint odor, and a pain score of 4.\n"
                "3. Image Analysis Insights: The image shows a deep ulcer with some slough present in the wound bed. There is surrounding erythema. The edges appear calloused as reported.\n"
                "4. Wound Staging: Based on the information provided and the image, the wound is staged as Wagner 2 (deep to tendon/capsule, no abscess/osteomyelitis).",
        "diagnosis":
            "Diabetic foot ulcer on the plantar aspect of the great toe, full-thickness, with surrounding erythema. Concern for possible deep tissue involvement. Further assessment needed to rule out osteomyelitis.",
        "confidence": 0.75,
        "treatment_plan":
            "The treatment plan should focus on offloading, debridement of non-viable tissue, maintaining a moist wound environment, assessing for infection, ensuring adequate vascular supply, managing blood glucose levels, controlling pain, and educating the patient."
      },
      "treatment_plan": {
        "plan_text":
            "1. Offload the affected toe with appropriate footwear or padding.\n"
                "2. Debride non-viable tissue (slough and necrotic tissue) to promote healing.\n"
                "3. Apply a moist wound dressing to maintain a healthy wound environment.\n"
                "4. Monitor for signs of infection (increased pain, redness, swelling, purulent discharge).\n"
                "5. Ensure adequate blood glucose control.\n"
                "6. Educate the patient on proper foot care, offloading, and blood glucose management.",
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
            "task_text": "Check patient's blood glucose levels and coordinate with primary care provider for optimal control.",
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
    "urgency": "high_urgent"
  };

  late final SignatureController _sigCtrl;

  @override
  void initState() {
    super.initState();
    _sigCtrl = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black, // ไม่ fix theme สี (ถ้าจะทำ dark ให้เปลี่ยนทีหลัง)
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _sigCtrl.dispose();
    super.dispose();
  }

  // ----------------------------
  // Helpers to read data
  // ----------------------------
  Map<String, dynamic> get p => (mock["patient_profile"] as Map<String, dynamic>);
  Map<String, dynamic> get ai => ((mock["ai_analysis"] as Map<String, dynamic>)["AI_analysis"] as Map<String, dynamic>);
  Map<String, dynamic> get tp => ((mock["ai_analysis"] as Map<String, dynamic>)["treatment_plan"] as Map<String, dynamic>);
  List<dynamic> get tasks => (tp["plan_tasks"] as List<dynamic>);

  String _safeStr(dynamic v) => (v == null) ? "-" : v.toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final pageBg = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFEFF2F7);
    final subtle = isDark ? Colors.white10 : Colors.black.withOpacity(0.04);

    final stage = _safeStr(ai["wound_stage"]); // "STAGE 3"
    final patientName = _safeStr(p["patient_name"]);
    final gender = _safeStr(p["gender"]).toUpperCase();
    final dob = _safeStr(p["dob"]);
    final medical = _safeStr(p["medical_history"]);
    final confidence = (ai["confidence"] is num) ? (ai["confidence"] as num).toDouble() : null;
    final followupDays = tp["followup_days"];

    // ✅ fix “ไม่เต็มหน้า”: bottom padding dynamic (ตาม safe area + CTA)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 150;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              decoration: BoxDecoration(
                color: pageBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 28,
                    spreadRadius: -8,
                    offset: const Offset(0, 18),
                  )
                ],
              ),
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: const Gap(12)),

                      // Top header
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: border)),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 18,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Review Treatment Plan",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 36),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(18, 18, 18, bottomPadding),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              // Patient card (mock)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: subtle,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.account_circle, size: 34, color: cs.primary),
                                    ),
                                    const Gap(12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patientName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const Gap(4),
                                          Text(
                                            "DOB: $dob • $gender • Hx: $medical • $stage",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                              color: isDark ? Colors.white54 : Colors.black45,
                                            ),
                                          ),
                                          if (confidence != null) ...[
                                            const Gap(8),
                                            Row(
                                              children: [
                                                Text(
                                                  "AI Confidence ${(confidence * 100).toStringAsFixed(0)}%",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                    color: cs.primary,
                                                  ),
                                                ),
                                                const Gap(10),
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(999),
                                                    child: LinearProgressIndicator(
                                                      value: confidence,
                                                      minHeight: 5,
                                                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Gap(18),

                              _SectionHeader(
                                icon: Icons.auto_awesome,
                                title: "Clinical Diagnosis",
                                color: cs.primary,
                                isDark: isDark,
                              ),
                              const Gap(10),
                              _Card(
                                border: border,
                                bg: isDark ? const Color(0xFF111B2C) : Colors.white,
                                child: Text(
                                  _safeStr(ai["diagnosis"]),
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const Gap(18),

                              _SectionHeader(
                                icon: Icons.assignment_outlined,
                                title: "Active Plan",
                                color: cs.primary,
                                isDark: isDark,
                              ),
                              const Gap(10),
                              _InfoRow(
                                border: border,
                                bg: subtle,
                                icon: Icons.event_repeat,
                                label: "Follow-up",
                                value: "Every ${_safeStr(followupDays)} Days",
                                valueColor: cs.primary,
                                isDark: isDark,
                              ),
                              const Gap(10),
                              _InfoRow(
                                border: border,
                                bg: subtle,
                                icon: Icons.description_outlined,
                                label: "Status",
                                value: _safeStr(tp["status"]),
                                valueColor: cs.primary,
                                isDark: isDark,
                              ),

                              const Gap(18),

                              _SectionHeader(
                                icon: Icons.notes_outlined,
                                title: "Plan Notes",
                                color: cs.primary,
                                isDark: isDark,
                              ),
                              const Gap(10),
                              _Card(
                                border: border,
                                bg: isDark ? const Color(0xFF111B2C) : Colors.white,
                                child: Text(
                                  _safeStr(tp["plan_text"]),
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const Gap(18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _SectionHeaderInline(
                                    icon: Icons.checklist,
                                    title: "Tasks for Nurse",
                                    color: cs.primary,
                                    isDark: isDark,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "${tasks.length} TASKS",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: cs.primary,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const Gap(10),

                              // ✅ build tasks from mock JSON
                              ...List.generate(tasks.length, (i) {
                                final t = tasks[i] as Map<String, dynamic>;
                                final title = _safeStr(t["task_text"]);
                                final due = _safeStr(t["task_due"]);
                                final status = _safeStr(t["status"]);
                                return Padding(
                                  padding: EdgeInsets.only(bottom: i == tasks.length - 1 ? 0 : 10),
                                  child: _TaskRow(
                                    border: border,
                                    isDark: isDark,
                                    title: title,
                                    desc: "Due: $due • Status: $status",
                                  ),
                                );
                              }),

                              const Gap(18),

                              // Signature section (REAL draw)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _SectionHeaderInline(
                                    icon: Icons.draw_outlined,
                                    title: "Physician Digital Signature",
                                    color: cs.primary,
                                    isDark: isDark,
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _sigCtrl.clear(),
                                    icon: Icon(Icons.delete_sweep, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                                    label: Text(
                                      "Clear Signature",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const Gap(10),

                              Container(
                                height: 170,
                                decoration: BoxDecoration(
                                  color: subtle,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? Colors.white24 : Colors.black12,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Signature(
                                    controller: _sigCtrl,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ),

                              const Gap(10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Draw signature inside box".toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                  Text(
                                    "Auth: MD-88219-X",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),

                              const Gap(14),

                              // Warning note
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF78350F).withOpacity(0.25) : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF92400E).withOpacity(0.25) : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info, color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B)),
                                    const Gap(10),
                                    Expanded(
                                      child: Text(
                                        "By signing and sending this plan, you provide legal and clinical authorization for the frontline nursing team to execute these tasks. The case status will be updated to PLAN_SENT.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.45,
                                          color: isDark ? const Color(0xFFFFE7A3) : const Color(0xFF92400E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom CTA bar (fixed)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: BoxDecoration(
                        color: pageBg.withOpacity(0.92),
                        border: Border(top: BorderSide(color: border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final signed = _sigCtrl.isNotEmpty;
                                  if (!signed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please sign before sending.")),
                                    );
                                    return;
                                  }

                                  // (Optional) export signature bytes (PNG)
                                  // final pngBytes = await _sigCtrl.toPngBytes();

                                  // TODO: send plan + update status PLAN_SENT
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Plan sent (mock) ✅")),
                                  );
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.send),
                                label: const Text(
                                  "Authorize & Send Plan",
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                            ),
                            const Gap(14),
                            Center(
                              child: Container(
                                width: 120,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- helpers ---------------- */

class _Card extends StatelessWidget {
  const _Card({required this.border, required this.bg, required this.child});
  final Color border;
  final Color bg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const Gap(8),
        Text(
          title.toUpperCase(),
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

class _SectionHeaderInline extends StatelessWidget {
  const _SectionHeaderInline({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const Gap(8),
        Text(
          title.toUpperCase(),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.border,
    required this.bg,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
  });

  final Color border;
  final Color bg;
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white54 : Colors.black45),
          const Gap(10),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.border,
    required this.isDark,
    required this.title,
    required this.desc,
  });

  final Color border;
  final bool isDark;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF111B2C) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.radio_button_checked, color: Color(0xFF10B981)),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Gap(4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
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
