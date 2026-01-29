import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/ai_analysis_screen.dart';
import 'package:flutter_application/features/auth/screens/treatment_plan_dispatch_screen.dart';

/// ✅ MOCK CASE (hard-coded)
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
      "diagnosis":
          "Diabetic foot ulcer on the plantar aspect of the great toe, full-thickness, with surrounding erythema.",
      "confidence": 0.75,
      "description":
          "Patient is a 24-year-old male with diabetes. Vitals stable. Wound: plantar aspect of great toe, round ulcer 1.5 x 1.5 cm, full-thickness, 10% slough, 5% necrotic, calloused edges, erythematous periwound, minimal discharge, faint odor, pain score 4. AI suggests Wagner 2 (deep to tendon/capsule, no abscess/osteomyelitis) and recommends review.",
      "treatment_plan":
          "Focus on offloading, debridement, moist wound environment, assess infection, vascular supply, glucose control, pain control, patient education."
    }
  },
  "urgency": "high_urgent"
};

int _calcAgeFromDob(String dob) {
  // dob: "03/02/2001" (dd/MM/yyyy)
  final parts = dob.split("/");
  if (parts.length != 3) return 0;
  final d = int.tryParse(parts[0]) ?? 1;
  final m = int.tryParse(parts[1]) ?? 1;
  final y = int.tryParse(parts[2]) ?? 2000;
  final birth = DateTime(y, m, d);
  final now = DateTime.now();
  int age = now.year - birth.year;
  final hadBirthday = (now.month > birth.month) || (now.month == birth.month && now.day >= birth.day);
  if (!hadBirthday) age -= 1;
  return age;
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  String diagnosis = "Accept AI: Wagner Grade 2";
  final notesCtrl = TextEditingController();

  @override
  void dispose() {
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF273449) : const Color(0xFFE6EBF2);

    // ✅ bind mock data
    final p = mockCase["patient_profile"] as Map<String, dynamic>;
    final n = mockCase["nurse_reviewed"] as Map<String, dynamic>;
    final a = (mockCase["ai_analysis"] as Map<String, dynamic>)["AI_analysis"] as Map<String, dynamic>;

    final patientName = (p["patient_name"] ?? "Unknown").toString();
    final gender = _capitalize((p["gender"] ?? "").toString());
    final age = _calcAgeFromDob((p["dob"] ?? "").toString());

    final medicalHistory = (p["medical_history"] ?? "").toString();
    final comorbidities = medicalHistory.isEmpty
        ? const <String>[]
        : medicalHistory.split(RegExp(r"[,;/]")).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final locationPrimary = _capitalize((n["location_primary"] ?? "").toString());
    final locationDetail = (n["location_detail"] ?? "").toString();
    final width = n["size_width_cm"];
    final length = n["size_length_cm"];
    final area = (width is num && length is num) ? (width * length) : null;

    final slough = n["bed_slough_pct"];
    final necrotic = n["bed_necrotic_pct"];
    final pain = n["pain_score"];
    final odor = (n["odor_presence"] ?? "").toString();

    final aiStageRaw = (a["wound_stage"] ?? "").toString();
    final aiConfidence = (a["confidence"] is num) ? (a["confidence"] as num).toDouble() : 0.0;
    final aiConfidencePct = (aiConfidence * 100).round();
    final aiDesc = (a["description"] ?? "").toString();
    final aiDx = (a["diagnosis"] ?? "").toString();

    final urgency = (mockCase["urgency"] ?? "").toString();
    final urgencyBadge = urgency == "high_urgent" ? "HIGH URGENCY" : "ROUTINE";

    final nurseNote =
        "Site: $locationPrimary (${locationDetail.isEmpty ? "-" : locationDetail}). "
        "Slough: ${slough ?? "-"}%, Necrotic: ${necrotic ?? "-"}%, Pain: ${pain ?? "-"}, Odor: ${odor.isEmpty ? "-" : odor}.";

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _StatusBarMimic(isDark: isDark)),
            SliverToBoxAdapter(
              child: _Header(
                cs: cs,
                isDark: isDark,
                card: card,
                border: border,
                onBack: () => Navigator.pop(context),
                onMore: () {},
                patientName: patientName,
                caseIdText: "ID: #ULC-9283",
                tag1: "Medical: ${medicalHistory.isEmpty ? "N/A" : medicalHistory}",
                tag2: urgencyBadge,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // Patient Profile
                    _SectionCard(
                      titleIcon: Icons.person_search,
                      title: "Patient Profile",
                      cs: cs,
                      isDark: isDark,
                      card: card,
                      border: border,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _KeyVal(
                                  title: "Age / Gender",
                                  value: "${age == 0 ? "-" : age}, $gender",
                                  isDark: isDark,
                                ),
                              ),
                              Expanded(
                                child: _KeyVal(
                                  title: "Vitals",
                                  value: "${n["blood_pressure"] ?? "-"} • HR ${n["heart_rate"] ?? "-"}",
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const Gap(14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "COMORBIDITIES",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: comorbidities.isEmpty ? const [_Pill(text: "None")] : comorbidities.map((e) => _Pill(text: e)).toList(),
                          ),
                        ],
                      ),
                    ),

                    const Gap(18),

                    // Wound timeline (ยังเป็น placeholder รูป)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(icon: Icons.history, text: "Wound Timeline", isDark: isDark),
                        TextButton(
                          onPressed: () {},
                          child: Text("View All", style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const Gap(10),
                    SizedBox(
                      height: 360,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 4, right: 4),
                        children: [
                          _TimelineCard(
                            isDark: isDark,
                            card: card,
                            border: border,
                            primary: cs.primary,
                            latest: true,
                            date: "Today",
                            subtitle: "AI: $aiStageRaw • $aiConfidencePct%",
                            area: area == null ? "-" : "${area.toStringAsFixed(2)} cm²",
                            note: nurseNote,
                            areaIsBad: urgency == "high_urgent",
                          ),
                        ],
                      ),
                    ),

                    const Gap(18),

                    // AI Analysis
                    _AiAnalysisCard(
                      isDark: isDark,
                      primary: cs.primary,
                      aiText: aiDesc.isEmpty ? aiDx : aiDesc,
                      confidenceText: "$aiConfidencePct%",
                      onReviewAi: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAnalysisScreen()));
                      },
                    ),

                    const Gap(18),

                    _SectionTitle(icon: Icons.edit_note, text: "Clinical Evaluation", isDark: isDark),
                    const Gap(10),

                    _SectionCard(
                      title: null,
                      titleIcon: null,
                      cs: cs,
                      isDark: isDark,
                      card: card,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DIAGNOSIS OVERRIDE (OPTIONAL)",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                          const Gap(10),
                          DropdownButtonFormField<String>(
                            value: diagnosis,
                            items: const [
                              DropdownMenuItem(value: "Accept AI: Wagner Grade 2", child: Text("Accept AI: Wagner Grade 2")),
                              DropdownMenuItem(value: "Override: Wagner Grade 3", child: Text("Override: Wagner Grade 3")),
                              DropdownMenuItem(value: "Override: Wagner Grade 1", child: Text("Override: Wagner Grade 1")),
                            ],
                            onChanged: (v) => setState(() => diagnosis = v ?? diagnosis),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                            icon: const Icon(Icons.expand_more),
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    _SectionCard(
                      title: null,
                      titleIcon: null,
                      cs: cs,
                      isDark: isDark,
                      card: card,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CLINICAL NOTES",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                          const Gap(10),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Add specific observation for the nurse...",
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          color: bg.withOpacity(0.95),
          border: Border(top: BorderSide(color: border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: const Text("Save Draft", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const Gap(12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TreatmentPlanDispatchScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Create Treatment Plan", style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- UI building blocks ---------------- */

class _StatusBarMimic extends StatelessWidget {
  const _StatusBarMimic({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("9:41", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Row(
            children: const [
              Icon(Icons.signal_cellular_alt, size: 18),
              SizedBox(width: 6),
              Icon(Icons.wifi, size: 18),
              SizedBox(width: 6),
              Icon(Icons.battery_full, size: 18),
            ],
          )
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cs,
    required this.isDark,
    required this.card,
    required this.border,
    required this.onBack,
    required this.onMore,
    required this.patientName,
    required this.caseIdText,
    required this.tag1,
    required this.tag2,
  });

  final ColorScheme cs;
  final bool isDark;
  final Color card;
  final Color border;
  final VoidCallback onBack;
  final VoidCallback onMore;

  final String patientName;
  final String caseIdText;
  final String tag1;
  final String tag2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _CircleIconButton(icon: Icons.chevron_left, onTap: onBack, card: card, border: border),
              const Spacer(),
              const Text("Case Review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              _CircleIconButton(icon: Icons.more_horiz, onTap: onMore, card: card, border: border, iconColor: cs.primary),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.person, color: isDark ? Colors.white38 : Colors.black38),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag(text: caseIdText, tone: TagTone.blue),
                        _Tag(text: tag1, tone: TagTone.orange),
                        _Tag(text: tag2, tone: tag2.toUpperCase().contains("HIGH") ? TagTone.red : TagTone.orange),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.card,
    required this.border,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color card;
  final Color border;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: card,
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text, required this.isDark});
  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white54 : Colors.black45),
        const Gap(8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.cs,
    required this.isDark,
    required this.card,
    required this.border,
    required this.child,
    this.title,
    this.titleIcon,
  });

  final ColorScheme cs;
  final bool isDark;
  final Color card;
  final Color border;
  final Widget child;
  final String? title;
  final IconData? titleIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && titleIcon != null) ...[
            Row(
              children: [
                Icon(titleIcon, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                const Gap(8),
                Text(
                  title!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
            const Gap(14),
          ],
          child,
        ],
      ),
    );
  }
}

class _KeyVal extends StatelessWidget {
  const _KeyVal({required this.title, required this.value, required this.isDark});
  final String title;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45),
        ),
        const Gap(4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.isDark,
    required this.card,
    required this.border,
    required this.primary,
    required this.latest,
    required this.date,
    required this.area,
    required this.note,
    required this.areaIsBad,
    this.subtitle,
  });

  final bool isDark;
  final Color card;
  final Color border;
  final Color primary;
  final bool latest;
  final String date;
  final String? subtitle;
  final String area;
  final String note;
  final bool areaIsBad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: latest ? 280 : 240,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: latest ? primary : border, width: latest ? 2 : 1),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      'https://blog.wcei.net/wp-content/uploads/2019/03/diabetic_foot_ulcer.jpg',
                      fit: BoxFit.cover, // Ensures the image fills the space properly
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                        child: Icon(Icons.broken_image, size: 44, color: isDark ? Colors.white30 : Colors.black26),
                      ),
                    ),
                  ),
                ),// ✅ placeholder image block
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Center(child: Icon(Icons.image, size: 44, color: isDark ? Colors.white30 : Colors.black26)),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: TextStyle(color: Colors.white, fontSize: latest ? 18 : 14, fontWeight: FontWeight.w900)),
                      if (subtitle != null) ...[
                        const Gap(4),
                        Text(subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.10), Colors.black.withOpacity(latest ? 0.60 : 0.40)],
                    ),
                  ),
                ),
                if (latest)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(999)),
                      child: const Text("LATEST", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.7)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Area (Est.)", style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Text(
                          area,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: areaIsBad ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        if (areaIsBad) ...[
                          const Gap(4),
                          const Icon(Icons.trending_up, size: 16, color: Color(0xFFEF4444)),
                        ]
                      ],
                    ),
                  ],
                ),
                const Gap(10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: latest ? 0.75 : 0.45,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(areaIsBad ? const Color(0xFFEF4444) : primary),
                  ),
                ),
                const Gap(10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? primary.withOpacity(0.12) : primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withOpacity(0.20)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: primary),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          note,
                          style: TextStyle(fontSize: 12, height: 1.35, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
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

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({
    required this.isDark,
    required this.primary,
    required this.onReviewAi,
    required this.aiText,
    required this.confidenceText,
  });

  final bool isDark;
  final Color primary;
  final VoidCallback onReviewAi;
  final String aiText;
  final String confidenceText;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0x331E3A8A) : const Color(0xFFEFF6FF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: isDark ? Colors.lightBlueAccent : const Color(0xFF1D4ED8)),
              const Gap(8),
              Text(
                "AI Analysis",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.lightBlueAccent : const Color(0xFF1D4ED8)),
              ),
            ],
          ),
          const Gap(10),
          Text(
            aiText,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(child: _MetricBox(title: "Confidence", value: confidenceText, isDark: isDark)),
              const Gap(12),
              Expanded(child: _MetricBox(title: "AI Draft", value: "Ready", isDark: isDark)),
            ],
          ),
          const Gap(12),
          InkWell(
            onTap: onReviewAi,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1220) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primary.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.biotech, color: primary),
                  const Gap(8),
                  Text("Review AI Analysis", style: TextStyle(color: primary, fontWeight: FontWeight.w900)),
                  const Gap(6),
                  Icon(Icons.chevron_right, color: primary.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.title, required this.value, required this.isDark});
  final String title;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white60 : Colors.black45)),
          const Gap(6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

enum TagTone { blue, orange, red }

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.tone});
  final String text;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bg, fg) = switch (tone) {
      TagTone.blue => (isDark ? const Color(0x332563EB) : const Color(0xFFDBEAFE), isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB)),
      TagTone.orange => (isDark ? const Color(0x334F2A0B) : const Color(0xFFFFEDD5), isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C)),
      TagTone.red => (isDark ? const Color(0x337F1D1D) : const Color(0xFFFEE2E2), isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}
