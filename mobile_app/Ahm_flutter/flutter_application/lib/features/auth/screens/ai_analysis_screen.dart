import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/treatment_plan_dispatch_screen.dart';

/// ---------------- MOCK CASE (hard-coded) ----------------
final Map<String, dynamic> mockCase = {
  "patient_profile": {
    "patient_name": "PAWMAN",
    "phone_no": "0861948565",
    "dob": "03/02/2001", // dd/MM/yyyy
    "gender": "male",
    "height_cm": "170",
    "weight_kg": "60",
    "occupation": "Data Analysis",
    "medical_history": "Diabetes",
    "created_at": "2026-01-28 11:33:20"
  },
  "ai_analysis": {
    "AI_analysis": {
      "creator": "Gemini AI",
      "wound_stage": "STAGE 3",
      "description":
          "1. Patient & Clinical Overview: The patient is a 24-year-old male with a history of diabetes. Vitals are within normal limits (Temperature: 37°C, Blood Pressure: 120/80 mmHg, Heart Rate: 80 bpm). Risk factors include diabetes. \n"
              "2. Formal Wound Description: The wound is located on the plantar aspect of the great toe. It is a round ulcer, measuring 1.5 cm x 1.5 cm. The nurse reports full-thickness depth, 10% slough, 5% necrotic tissue, calloused edges, erythematous periwound, minimal discharge (volume and type), faint odor, and a pain score of 4. \n"
              "3. Image Analysis Insights: The image shows a deep ulcer with some slough present in the wound bed. There is surrounding erythema. The edges appear calloused as reported. \n"
              "4. Wound Staging: Based on the information provided and the image, the wound is staged as Wagner 2 (deep to tendon/capsule, no abscess/osteomyelitis). This could correspond to a University of Texas (UT) grade 2, stage A if there is no infection or ischemia. This is an AI-generated draft for clinical documentation support only and must be reviewed and verified by a licensed medical professional before use. Seek urgent medical care if there are signs of severe infection, rapidly worsening redness/swelling, fever, severe pain, or gangrene.",
      "diagnosis":
          "Diabetic foot ulcer on the plantar aspect of the great toe, full-thickness, with surrounding erythema. Concern for possible deep tissue involvement. Further assessment needed to rule out osteomyelitis.",
      "confidence": 0.75,
      "treatment_plan":
          "The treatment plan should focus on offloading, debridement of non-viable tissue, maintaining a moist wound environment, assessing for infection, ensuring adequate vascular supply, managing blood glucose levels, controlling pain, and educating the patient. Given the depth of the ulcer, close monitoring is essential. This is an AI-generated draft for clinical documentation support only and must be reviewed and verified by a licensed medical professional before use. Seek urgent medical care if there are signs of severe infection, rapidly worsening redness/swelling, fever, severe pain, or gangrene."
    }
  }
};

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  // ----- state -----
  bool aiAccurate = true;

  // dropdowns
  late String woundStage;
  late String diagnosis;
  String healingProgress = "Improving (Reduction in erythema)";

  // textareas
  late TextEditingController descCtrl;
  late TextEditingController planCtrl;

  // mock
  late double aiConfidence;

  // header
  late String patientName;
  late String gender;
  late int age;
  late String caseId;

  @override
  void initState() {
    super.initState();

    // --- pull data from mockCase (hard-coded) ---
    final patient = (mockCase["patient_profile"] as Map<String, dynamic>);
    final ai = (mockCase["ai_analysis"]["AI_analysis"] as Map<String, dynamic>);

    patientName = (patient["patient_name"] ?? "Unknown").toString();
    gender = _capitalize((patient["gender"] ?? "-").toString());
    age = _calcAge((patient["dob"] ?? "").toString());

    // mock case id (คุณจะ map กับของจริงทีหลังได้)
    caseId = "#ULC-9283";

    woundStage = _normalizeStage((ai["wound_stage"] ?? "Stage 2").toString());

    // NOTE: UI เดิมเป็น dropdown ที่ value ต้อง match items list
    // เราจะ map diagnosis ให้เข้ากับ list (ถ้าไม่ match ให้ fallback)
    diagnosis = _pickDiagnosis((ai["diagnosis"] ?? "").toString());

    aiConfidence = (ai["confidence"] is num)
        ? (ai["confidence"] as num).toDouble()
        : 0.0;

    descCtrl = TextEditingController(
      text: (ai["description"] ?? "").toString(),
    );

    planCtrl = TextEditingController(
      text: (ai["treatment_plan"] ?? "").toString(),
    );
  }

  @override
  void dispose() {
    descCtrl.dispose();
    planCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFE2E8F0);
    final subtle = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // status bar mimic (9:41...)
            SliverToBoxAdapter(child: _StatusBarMimic(isDark: isDark)),

            // top nav
            SliverToBoxAdapter(
              child: _TopBar(
                border: border,
                onBack: () => Navigator.pop(context),
              ),
            ),

            // content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // patient header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const Gap(4),
                            Text(
                              "ID: $caseId • $gender, ${age}y",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "SPECIALIST REVIEW",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Gap(14),

                    // image block (16:9, rounded 32, top-left tag)
                    // image block (16:9, rounded 32, top-left tag)
Container(
  clipBehavior: Clip.antiAlias,
  decoration: BoxDecoration(
    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
        blurRadius: 20,
        spreadRadius: -10,
        offset: const Offset(0, 16),
      )
    ],
    border: Border.all(color: Colors.white.withOpacity(isDark ? 0.10 : 0.30)),
  ),
  child: AspectRatio(
    aspectRatio: 16 / 9,
    child: Stack(
      children: [
        // 1. The actual Image (Background)
        Positioned.fill(
          child: Image.network(
            'https://blog.wcei.net/wp-content/uploads/2019/03/diabetic_foot_ulcer.jpg',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary.withOpacity(0.5),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(Icons.broken_image, size: 54, color: isDark ? Colors.white10 : Colors.black12),
            ),
          ),
        ),

        // 2. Subtle Dark Overlay (Optional: helps the AI Tag pop more)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2), // Darker at top to highlight tag
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. The Tag (Foreground)
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                Gap(6),
                Text(
                  "AI SUGGESTED",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),

                    const Gap(18),

                    // ---- Modify Findings card ----
                    _Card(
                      card: card,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.edit_square, color: cs.primary),
                              ),
                              const Gap(10),
                              Text(
                                "MODIFY FINDINGS",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),

                          const Gap(18),

                          // grid 2 columns: stage + confidence
                          Row(
                            children: [
                              Expanded(
                                child: _Labeled(
                                  label: "WOUND STAGE",
                                  isDark: isDark,
                                  child: _DropdownBox(
                                    value: woundStage,
                                    items: const [
                                      "Stage 1",
                                      "Stage 2",
                                      "Stage 3",
                                      "Stage 4",
                                      "Unstageable",
                                    ],
                                    onChanged: (v) => setState(() => woundStage = v),
                                    cs: cs,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Opacity(
                                  opacity: 0.65,
                                  child: _Labeled(
                                    label: "AI CONFIDENCE",
                                    isDark: isDark,
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: subtle,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: border.withOpacity(0.85)),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            "${(aiConfidence * 100).toStringAsFixed(1)}%",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: cs.primary,
                                            ),
                                          ),
                                          const Gap(10),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(999),
                                              child: LinearProgressIndicator(
                                                value: aiConfidence.clamp(0.0, 1.0),
                                                minHeight: 5,
                                                backgroundColor:
                                                    isDark ? Colors.white10 : Colors.black12,
                                                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Gap(14),

                          _Labeled(
                            label: "DIAGNOSTIC CLASSIFICATION",
                            isDark: isDark,
                            child: _DropdownBox(
                              value: diagnosis,
                              items: const [
                                "Diabetic Foot Ulcer (Wagner Grade 2)",
                                "Venous Leg Ulcer",
                                "Pressure Injury",
                                "Arterial Ulcer",
                                "Mixed Etiology",
                              ],
                              onChanged: (v) => setState(() => diagnosis = v),
                              cs: cs,
                              isDark: isDark,
                              bold: true,
                            ),
                          ),

                          const Gap(14),

                          _Labeled(
                            label: "CLINICAL DESCRIPTION",
                            isDark: isDark,
                            child: _Textarea(
                              controller: descCtrl,
                              isDark: isDark,
                            ),
                          ),

                          const Gap(14),

                          _Labeled(
                            label: "PROPOSED TREATMENT PLAN",
                            isDark: isDark,
                            child: _Textarea(
                              controller: planCtrl,
                              isDark: isDark,
                            ),
                          ),

                          const Gap(14),

                          _Labeled(
                            label: "HEALING PROGRESS",
                            isDark: isDark,
                            child: _DropdownBox(
                              value: healingProgress,
                              items: const [
                                "Improving (Reduction in erythema)",
                                "Stable (No significant change)",
                                "Declining (Increased size/exudate)",
                                "Critical (Infection suspected)",
                              ],
                              onChanged: (v) => setState(() => healingProgress = v),
                              cs: cs,
                              isDark: isDark,
                              tint: const Color(0xFF10B981), // emerald-ish
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),

                    // ---- Evaluate AI Accuracy card ----
                    _Card(
                      card: card,
                      border: border,
                      child: Column(
                        children: [
                          Text(
                            "EVALUATE AI ACCURACY",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const Gap(16),
                          Row(
                            children: [
                              Expanded(
                                child: _QualityCard(
                                  label: "Accurate",
                                  icon: Icons.check_circle,
                                  active: aiAccurate,
                                  activeColor: cs.primary,
                                  isDark: isDark,
                                  onTap: () => setState(() => aiAccurate = true),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _QualityCard(
                                  label: "Needs Correction",
                                  icon: Icons.report,
                                  active: !aiAccurate,
                                  activeColor: const Color(0xFFF43F5E), // rose
                                  isDark: isDark,
                                  onTap: () => setState(() => aiAccurate = false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(18),

                    // bottom buttons in content (เหมือน HTML)
                    _PrimaryButton(
                      text: "Proceed to Treatment Plan",
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TreatmentPlanDispatchScreen()),
                        );
                      },
                      cs: cs,
                    ),
                    const Gap(12),
                    _SecondaryButton(
                      text: "Discard Edits",
                      onPressed: () => Navigator.pop(context),
                      isDark: isDark,
                    ),
                    const Gap(22),

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

/// ---------------- helpers (hard-coded mapping) ----------------

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

int _calcAge(String dob) {
  // expected dd/MM/yyyy
  final parts = dob.split("/");
  if (parts.length != 3) return 0;

  final d = int.tryParse(parts[0]) ?? 1;
  final m = int.tryParse(parts[1]) ?? 1;
  final y = int.tryParse(parts[2]) ?? 2000;

  final birth = DateTime(y, m, d);
  final now = DateTime.now();

  int age = now.year - birth.year;
  if (now.month < m || (now.month == m && now.day < d)) age--;
  return age < 0 ? 0 : age;
}

String _normalizeStage(String raw) {
  final up = raw.toUpperCase().trim();
  if (up.startsWith("STAGE")) {
    final n = raw.replaceAll(RegExp(r"[^0-9]"), "");
    if (n.isNotEmpty) return "Stage $n";
  }
  // already "Stage 2" etc
  if (raw.startsWith("Stage")) return raw;
  return "Stage 2";
}

/// UI dropdown diagnosis ต้อง match items; ถ้า AI ส่งมาเป็นประโยคยาว ให้ fallback
String _pickDiagnosis(String aiText) {
  final items = const [
    "Diabetic Foot Ulcer (Wagner Grade 2)",
    "Venous Leg Ulcer",
    "Pressure Injury",
    "Arterial Ulcer",
    "Mixed Etiology",
  ];

  final t = aiText.toLowerCase();
  if (t.contains("diabetic") || t.contains("foot ulcer")) {
    return items[0];
  }
  if (t.contains("venous")) return items[1];
  if (t.contains("pressure")) return items[2];
  if (t.contains("arterial")) return items[3];
  if (t.contains("mixed")) return items[4];

  return items[0];
}

/* ---------------- widgets ---------------- */

class _StatusBarMimic extends StatelessWidget {
  const _StatusBarMimic({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      color: Colors.transparent,
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
  const _TopBar({required this.border, required this.onBack});
  final Color border;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = (isDark ? const Color(0xCC0F172A) : const Color(0xCCF8FAFC));

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: Icon(Icons.chevron_left, color: cs.primary),
            label: Text("Case Detail",
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
          ),
          const Spacer(),
          const Text("AI Review & Edit", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const Spacer(),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.card, required this.border});
  final Widget child;
  final Color card;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.06),
            blurRadius: 14,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child, required this.isDark});
  final String label;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        const Gap(8),
        child,
      ],
    );
  }
}

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.cs,
    required this.isDark,
    this.bold = false,
    this.tint,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final ColorScheme cs;
  final bool isDark;
  final bool bold;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFE2E8F0);
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);

    final effectiveTint =
        tint ?? (bold ? cs.primary : (isDark ? Colors.white70 : Colors.black87));

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: isDark ? Colors.white54 : Colors.black45),
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: effectiveTint,
          ),
          dropdownColor: isDark ? const Color(0xFF0B1220) : Colors.white,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _Textarea extends StatelessWidget {
  const _Textarea({required this.controller, required this.isDark});
  final TextEditingController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFE2E8F0);
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: TextStyle(
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: "",
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        ),
      ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFE2E8F0);
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);

    final cardBorder = active ? activeColor : border;
    final cardBg = active ? activeColor.withOpacity(isDark ? 0.14 : 0.10) : bg;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder, width: 2),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: active ? activeColor : (isDark ? Colors.white38 : Colors.black38),
            ),
            const Gap(10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: active ? activeColor : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.cs,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const Gap(10),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.text,
    required this.onPressed,
    required this.isDark,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final fg = isDark ? Colors.white70 : Colors.black87;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
