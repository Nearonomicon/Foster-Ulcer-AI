import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/treatment_plan_dispatch_screen.dart';
import 'package:flutter_application/features/auth/services/case_service.dart';
import 'package:flutter_application/shared/app_localizations.dart';

const String kSinbadAreaSmall = "< 1 cm²";
const String kSinbadAreaLarge = ">= 1 cm²";

class AiAnalysisScreen extends StatefulWidget {
  final String caseId;
  final int selectedTimelineIndex;

  const AiAnalysisScreen({
    super.key,
    required this.caseId,
    required this.selectedTimelineIndex,
  });

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  bool aiAccurate = true;

  String woundStageKey = "stage_2";
  String sinbadSiteKey = "Forefoot";
  String sinbadIschemiaKey = "NO";
  String sinbadNeuropathyKey = "NO";
  String sinbadBacterialKey = "NO";
  String sinbadAreaKey = kSinbadAreaSmall;
  String sinbadDepthKey = "Skin only";
  String wifiWoundKey = "wifi_na";
  String wifiIschemiaKey = "wifi_na";
  String wifiFootInfectionKey = "wifi_na";
  String idsaKey = "idsa_na";
  late TextEditingController descCtrl;
  late TextEditingController planCtrl;
  late TextEditingController healingProgressCtrl;

  double aiConfidence = 0.0;

  String patientName = "Unknown";
  String genderText = "na";
  int age = 0;
  String caseIdText = "";
  String diagnosisText = "";
  String analysisId = "";
  String recordId = "";
  bool redFlag = false;
  int? wifiClinicalStage;

  String selectedImageUrl = "";
  bool isLatestEditable = false;
  String visitLabel = "Selected Visit";
  String selectedImageId = "";

  final CaseService _caseService = CaseService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Map<String, dynamic>? _caseResponse;

  @override
  void initState() {
    super.initState();
    caseIdText = "#${widget.caseId}";
    descCtrl = TextEditingController();
    planCtrl = TextEditingController();
    healingProgressCtrl = TextEditingController();
    _loadCaseDetail();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  String _safeImageUrl(dynamic value) {
    final s = (value ?? "").toString().trim();
    if (s.isEmpty || s.toLowerCase() == "null") return "";
    return s;
  }

  int? _tryParseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "").toString());
  }

  int? _wifiGradeFromKey(String key) {
    switch (key) {
      case "wifi_0":
        return 0;
      case "wifi_1":
        return 1;
      case "wifi_2":
        return 2;
      case "wifi_3":
        return 3;
      default:
        return null;
    }
  }

  int? _idsaStageFromKey(String key) {
    switch (key) {
      case "idsa_1":
        return 1;
      case "idsa_2":
        return 2;
      case "idsa_3":
        return 3;
      case "idsa_4":
        return 4;
      default:
        return null;
    }
  }

  Map<String, dynamic> _buildDoctorReviewDraft() {
    return {
      "analysis_id": analysisId,
      "case_id": widget.caseId,
      "record_id": recordId,
      "payload": {
        "AI_analysis": {
          "creator": "Doctor",
          "description": descCtrl.text.trim(),
          "diagnosis": diagnosisText,
          "confidence": aiConfidence,
          "red_flag": redFlag,
          "treatment_plan": planCtrl.text.trim(),
          "classifications": {
            "IDSA_infection_stage": _idsaStageFromKey(idsaKey),
            "WIfI": {
              "wound_grade": _wifiGradeFromKey(wifiWoundKey),
              "ischemia_grade": _wifiGradeFromKey(wifiIschemiaKey),
              "foot_infection_grade":
                  _wifiGradeFromKey(wifiFootInfectionKey),
              "clinical_stage": wifiClinicalStage,
            },
          },
        },
        "healing_progress": healingProgressCtrl.text.trim(),
      },
    };
  }

  Future<void> _loadCaseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _caseService.getCaseDetail(widget.caseId);

      if (!mounted) return;

      final data = _asMap(res["data"]);
      final caseBundle = _asMap(data["case_bundle"]);

      final rootPatient = _asMap(caseBundle["patient_profile"]);
      final rootAi = _asMap(caseBundle["ai_analysis"]);
      final permissions = _asMap(caseBundle["permissions"]);
      final images = _asMapList(caseBundle["wound_images"]);

      final safeIndex = images.isEmpty
          ? 0
          : (widget.selectedTimelineIndex >= 0 &&
                  widget.selectedTimelineIndex < images.length)
              ? widget.selectedTimelineIndex
              : 0;

      final selectedImage =
          images.isNotEmpty ? images[safeIndex] : <String, dynamic>{};

      final patient = selectedImage["patient_snapshot"] != null
          ? _asMap(selectedImage["patient_snapshot"])
          : rootPatient;

      final ai = selectedImage["ai_snapshot"] != null
          ? _asMap(selectedImage["ai_snapshot"])
          : rootAi;

      patientName = (patient["patient_name"] ?? "Unknown").toString();

      final genderRaw = (patient["gender"] ?? "").toString().toLowerCase();
      genderText = (genderRaw == "male")
          ? "male"
          : (genderRaw == "female")
              ? "female"
              : "na";

      age = (patient["age"] is int)
          ? patient["age"] as int
          : _calcAgeFromIsoDob((patient["dob"] ?? "").toString());

      caseIdText = "#${widget.caseId}";

      woundStageKey = _stageKeyFromAi(
        (ai["wound_stage"] ?? ai["stage"] ?? "STAGE 2").toString(),
      );

      sinbadSiteKey = _sinbadSiteValueFromAi(ai["sinbad_site"]);
      sinbadIschemiaKey = _yesNoValueFromAi(ai["sinbad_ischemia"]);
      sinbadNeuropathyKey = _yesNoValueFromAi(ai["sinbad_neuropathy"]);
      sinbadBacterialKey = _yesNoValueFromAi(ai["sinbad_infection"]);
      sinbadAreaKey = _sinbadAreaDisplayValueFromAi(ai["sinbad_area"]);
      sinbadDepthKey = _sinbadDepthDisplayValueFromAi(ai["sinbad_depth"]);
      wifiWoundKey = _wifiComponentKeyFromAi(ai["wifi_wound"]);
      wifiIschemiaKey = _wifiComponentKeyFromAi(ai["wifi_ischemia"]);
      wifiFootInfectionKey = _wifiComponentKeyFromAi(ai["wifi_foot_infection"]);
      idsaKey = _idsaKeyFromAi(ai["idsa_stage"]);

      aiConfidence =
          (ai["confidence"] is num) ? (ai["confidence"] as num).toDouble() : 0.0;
      diagnosisText = (ai["diagnosis"] ?? "").toString();
      redFlag = ai["red_flag"] == true;
      analysisId = (selectedImage["analysis_id"] ?? "").toString();
      recordId = (selectedImage["record_id"] ?? "").toString();
      wifiClinicalStage = _tryParseInt(ai["wifi_stage"]);

      descCtrl.text = (ai["description"] ?? ai["narrative"] ?? "").toString();
      planCtrl.text =
          (ai["treatment_suggestion"] ?? ai["treatment_plan"] ?? "").toString();
      healingProgressCtrl.text =
          (selectedImage["nurse_note"] ?? "").toString();

      selectedImageUrl = _safeImageUrl(selectedImage["image_url"]);
      if (selectedImageUrl.isEmpty) {
        selectedImageUrl =
            "https://blog.wcei.net/wp-content/uploads/2019/03/diabetic_foot_ulcer.jpg";
      }

      final latestImageId = (permissions["latest_image_id"] ?? "").toString();
      selectedImageId = (selectedImage["image_id"] ?? "").toString();

      isLatestEditable = selectedImage["is_latest"] == true ||
          (latestImageId.isNotEmpty && latestImageId == selectedImageId);

      visitLabel =
          (selectedImage["visit_day_label"] ?? "Selected Visit").toString();

      setState(() {
        _caseResponse = res;
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

  Future<void> _proceedToTreatmentPlan() async {
    if (!isLatestEditable) return;

    if (selectedImageId.trim().isEmpty || recordId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Missing record data for doctor review."),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreatmentPlanDispatchScreen(
          caseId: widget.caseId,
          doctorReviewDraft: _buildDoctorReviewDraft(),
          aiResultEditFlag: !aiAccurate,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    descCtrl.dispose();
    planCtrl.dispose();
    healingProgressCtrl.dispose();
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text("AI Analysis")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const Gap(12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(16),
                ElevatedButton(
                  onPressed: _loadCaseDetail,
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final genderUi = switch (genderText) {
      "male" => context.tr('common.gender.male'),
      "female" => context.tr('common.gender.female'),
      _ => context.tr('common.na'),
    };

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TopBar(
                border: border,
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const Gap(4),
                              Text(
                                "${context.tr('common.id')}: $caseIdText • $genderUi, ${age}y",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                              const Gap(6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoBadge(
                                    text: visitLabel,
                                    fg: cs.primary,
                                    bg: cs.primary.withOpacity(
                                      isDark ? 0.18 : 0.10,
                                    ),
                                  ),
                                  _InfoBadge(
                                    text: isLatestEditable
                                        ? "LATEST - EDITABLE"
                                        : "PROGRESS REVIEW ONLY",
                                    fg: isLatestEditable
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    bg: isLatestEditable
                                        ? const Color(0xFF10B981).withOpacity(0.12)
                                        : const Color(0xFFF59E0B).withOpacity(0.12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            context
                                .tr('ai_review.badge.specialist_review')
                                .toUpperCase(),
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

                    if (!isLatestEditable)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(
                            isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.history_toggle_off,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const Gap(10),
                            Expanded(
                              child: Text(
                                "This is a previous wound timeline entry for progress review only. Treatment plan can be created only from the latest wound update.",
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.28 : 0.12),
                            blurRadius: 20,
                            spreadRadius: -10,
                            offset: const Offset(0, 16),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(isDark ? 0.10 : 0.30),
                        ),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                selectedImageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.primary.withOpacity(0.5),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 54,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.2),
                                      Colors.transparent,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 16,
                                      spreadRadius: -10,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const Gap(6),
                                    Text(
                                      context
                                          .tr('ai_review.tag.ai_suggested')
                                          .toUpperCase(),
                                      style: const TextStyle(
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
                              Expanded(
                                child: Text(
                                  isLatestEditable
                                      ? context
                                          .tr('ai_review.section.modify_findings')
                                          .toUpperCase()
                                      : "REVIEW FINDINGS",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const Gap(12),
                              _AiConfidenceBadge(
                                confidence: aiConfidence,
                                isDark: isDark,
                                primary: cs.primary,
                              ),
                            ],
                          ),
                          const Gap(18),

                          _Labeled(
                            label: "SINBAD",
                            isDark: isDark,
                            child: Column(
                              children: [
                                _SinbadChoiceField(
                                  label: "Site",
                                  value: sinbadSiteKey,
                                  options: const [
                                    "Forefoot",
                                    "Midfoot / Hindfoot",
                                  ],
                                  isDark: isDark,
                                  enabled: false,
                                  onChanged: (v) =>
                                      setState(() => sinbadSiteKey = v),
                                ),
                                const Gap(10),
                                _SinbadChoiceField(
                                  label: "Ischemia",
                                  value: sinbadIschemiaKey,
                                  options: const ["NO", "YES"],
                                  isDark: isDark,
                                  enabled: false,
                                  onChanged: (v) =>
                                      setState(() => sinbadIschemiaKey = v),
                                ),
                                const Gap(10),
                                _SinbadChoiceField(
                                  label: "Neuropathy",
                                  value: sinbadNeuropathyKey,
                                  options: const ["NO", "YES"],
                                  isDark: isDark,
                                  enabled: false,
                                  onChanged: (v) =>
                                      setState(() => sinbadNeuropathyKey = v),
                                ),
                                const Gap(10),
                                _SinbadChoiceField(
                                  label: "Bacterial",
                                  value: sinbadBacterialKey,
                                  options: const ["NO", "YES"],
                                  isDark: isDark,
                              enabled: false,
                                  onChanged: (v) =>
                                      setState(() => sinbadBacterialKey = v),
                                ),
                                const Gap(10),
                                _SinbadChoiceField(
                                  label: "Area",
                                  value: sinbadAreaKey,
                                  options: const [
                                    "< 1 cm²",
                                    ">= 1 cm²",
                                  ],
                                  isDark: isDark,
                              enabled: false,
                                  onChanged: (v) =>
                                      setState(() => sinbadAreaKey = v),
                                ),
                                const Gap(10),
                                _SinbadChoiceField(
                                  label: "Depth",
                                  value: sinbadDepthKey,
                                  options: const [
                                    "Skin only",
                                    "Deep/Bone",
                                  ],
                                  isDark: isDark,
                              enabled: false,
                                  onChanged: (v) =>
                                      setState(() => sinbadDepthKey = v),
                                ),
                                const Gap(12),
                                _SinbadScoreLine(
                                  score: _calcSinbadScoreFromValues(
                                    site: sinbadSiteKey,
                                    ischemia: sinbadIschemiaKey,
                                    neuropathy: sinbadNeuropathyKey,
                                    bacterial: sinbadBacterialKey,
                                    area: sinbadAreaKey,
                                    depth: sinbadDepthKey,
                                  ),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),

                          const Gap(14),

                          _Labeled(
                            label: "WIfI",
                            isDark: isDark,
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.start,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _WifiComponentField(
                                  prefix: "W",
                                  value: wifiWoundKey,
                                  isDark: isDark,
                                  enabled: true,
                                  cs: cs,
                                  onChanged: (v) =>
                                      setState(() => wifiWoundKey = v),
                                ),
                                _WifiSeparator(isDark: isDark),
                                _WifiComponentField(
                                  prefix: "I",
                                  value: wifiIschemiaKey,
                                  isDark: isDark,
                                  enabled: true,
                                  cs: cs,
                                  onChanged: (v) =>
                                      setState(() => wifiIschemiaKey = v),
                                ),
                                _WifiSeparator(isDark: isDark),
                                _WifiComponentField(
                                  prefix: "fI",
                                  value: wifiFootInfectionKey,
                                  isDark: isDark,
                                  enabled: true,
                                  cs: cs,
                                  onChanged: (v) => setState(
                                    () => wifiFootInfectionKey = v,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Gap(14),

                          _Labeled(
                            label: "IDSA",
                            isDark: isDark,
                            child: _DropdownBox(
                              value: idsaKey,
                              items: const [
                                "idsa_na",
                                "idsa_1",
                                "idsa_2",
                                "idsa_3",
                                "idsa_4",
                              ],
                              itemLabel: _idsaLabel,
                              onChanged: (v) => setState(() => idsaKey = v),
                              cs: cs,
                              isDark: isDark,
                              bold: true,
                                  enabled: true,
                            ),
                          ),

                          const Gap(14),

                          _Labeled(
                            label: context
                                .tr('ai_review.field.clinical_description')
                                .toUpperCase(),
                            isDark: isDark,
                            child: _Textarea(
                              controller: descCtrl,
                              isDark: isDark,
                                  enabled: true,
                            ),
                          ),

                          const Gap(14),

                          _Labeled(
                            label: context
                                .tr('ai_review.field.healing_progress')
                                .toUpperCase(),
                            isDark: isDark,
                            child: _Textarea(
                              controller: healingProgressCtrl,
                              isDark: isDark,
                              enabled: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),

                    _Card(
                      card: card,
                      border: border,
                      child: Column(
                        children: [
                          Text(
                            context
                                .tr('ai_review.section.evaluate_ai_accuracy')
                                .toUpperCase(),
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
                                  label: context.tr('ai_review.quality.accurate'),
                                  icon: Icons.check_circle,
                                  active: aiAccurate,
                                  activeColor: cs.primary,
                                  isDark: isDark,
                                  onTap: isLatestEditable
                                      ? () => setState(() => aiAccurate = true)
                                      : null,
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _QualityCard(
                                  label: context
                                      .tr('ai_review.quality.needs_correction'),
                                  icon: Icons.report,
                                  active: !aiAccurate,
                                  activeColor: const Color(0xFFF43F5E),
                                  isDark: isDark,
                                  onTap: isLatestEditable
                                      ? () => setState(() => aiAccurate = false)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(18),

                    if (isLatestEditable)
                      _PrimaryButton(
                        text: _isSaving
                            ? "Saving..."
                            : context.tr('ai_review.cta.proceed_treatment_plan'),
                        icon: _isSaving ? null : Icons.arrow_forward,
                        onPressed: _isSaving ? null : _proceedToTreatmentPlan,
                        cs: cs,
                      ),

                    if (isLatestEditable) const Gap(12),

                    _SecondaryButton(
                      text: isLatestEditable
                          ? context.tr('ai_review.cta.discard_edits')
                          : "Back to Case Detail",
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
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

/* ---------------- helpers ---------------- */

int _calcAgeFromIsoDob(String dob) {
  final birth = DateTime.tryParse(dob);
  if (birth == null) return 0;

  final now = DateTime.now();
  int age = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age < 0 ? 0 : age;
}

String _stageKeyFromAi(String raw) {
  final up = raw.toUpperCase().trim();
  if (up.contains("UNSTAGE")) return "unstageable";
  final n = raw.replaceAll(RegExp(r"[^0-9]"), "");
  switch (n) {
    case "1":
      return "stage_1";
    case "2":
      return "stage_2";
    case "3":
      return "stage_3";
    case "4":
      return "stage_4";
    default:
      return "stage_2";
  }
}

String _stageApiValue(String key) {
  switch (key) {
    case "stage_1":
      return "STAGE 1";
    case "stage_2":
      return "STAGE 2";
    case "stage_3":
      return "STAGE 3";
    case "stage_4":
      return "STAGE 4";
    case "unstageable":
      return "UNSTAGEABLE";
    default:
      return "STAGE 2";
  }
}

String _yesNoValueFromAi(dynamic value) {
  final s = (value ?? '').toString().trim().toLowerCase();
  if (s == 'yes' || s == 'true' || s == '1') return 'YES';
  if (s == 'no' || s == 'false' || s == '0') return 'NO';
  return 'NO';
}

String _sinbadSiteValueFromAi(dynamic value) {
  final s = (value ?? '').toString().trim().toLowerCase();
  return s.contains('midfoot') || s.contains('hindfoot')
      ? 'Midfoot / Hindfoot'
      : 'Forefoot';
}

String _sinbadAreaValueFromAi(dynamic value) {
  final s = (value ?? '').toString().trim().toLowerCase();
  return s.contains('>=') || s.contains('≥') ? 'yes' : 'no';
}

String _sinbadDepthKeyFromAi(dynamic value) {
  final s = (value ?? '').toString().trim().toLowerCase();
  return s.contains('deep') ? 'yes' : 'no';
}

String _sinbadAreaDisplayValueFromAi(dynamic value) {
  final s = (value ?? '').toString().trim().toLowerCase();
  return s.contains('>=') || s.contains('≥') || s.contains('â‰¥')
      ? '>= 1 cm²'
      : '< 1 cm²';
}

String _sinbadDepthDisplayValueFromAi(dynamic value) {
  final s = (value ?? '').toString().trim().toLowerCase();
  return s.contains('deep') ? 'Deep/Bone' : 'Skin only';
}

String _wifiComponentKeyFromAi(dynamic value) {
  final s = (value ?? '').toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return 'wifi_na';
  return 'wifi_$s';
}

String _idsaKeyFromAi(dynamic value) {
  final s = (value ?? '').toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return 'idsa_na';
  return 'idsa_$s';
}

String _idsaLabel(String key) {
  switch (key) {
    case 'idsa_1':
      return 'Stage 1';
    case 'idsa_2':
      return 'Stage 2';
    case 'idsa_3':
      return 'Stage 3';
    case 'idsa_4':
      return 'Stage 4';
    default:
      return 'N/A';
  }
}

String _buildSinbadSummaryFromKeys({
  required String site,
  required String ischemia,
  required String neuropathy,
  required String bacterial,
  required String area,
  required String depth,
}) {
  return 'SINBAD: Site $site, '
      'Ischemia $ischemia, '
      'Neuropathy $neuropathy, '
      'Bacterial $bacterial, '
      'Area $area, '
      'Depth $depth';
}

int _calcSinbadScoreFromValues({
  required String site,
  required String ischemia,
  required String neuropathy,
  required String bacterial,
  required String area,
  required String depth,
}) {
  var score = 0;
  if (site == "Midfoot / Hindfoot") score++;
  if (ischemia == "YES") score++;
  if (neuropathy == "YES") score++;
  if (bacterial == "YES") score++;
  if (area == ">= 1 cm²") score++;
  if (depth == "Deep/Bone") score++;
  return score;
}

Color _sinbadScoreColor(int score) {
  if (score >= 3) return Colors.red;
  if (score == 2) return Colors.amber;
  return const Color(0xFF0D9488);
}

extension on _AiAnalysisScreenState {
  String _buildDiagnosisOverride() {
    final sinbadSummary = _buildSinbadSummaryFromKeys(
      site: sinbadSiteKey,
      ischemia: sinbadIschemiaKey,
      neuropathy: sinbadNeuropathyKey,
      bacterial: sinbadBacterialKey,
      area: sinbadAreaKey,
      depth: sinbadDepthKey,
    );

    return [
      sinbadSummary,
      'WIfI: ${_wifiComponentLabel("W", wifiWoundKey)}, ${_wifiComponentLabel("I", wifiIschemiaKey)}, ${_wifiComponentLabel("fI", wifiFootInfectionKey)}',
      'IDSA: ${_idsaLabel(idsaKey)}',
    ].join(' | ');
  }
}

/* ---------------- widgets ---------------- */

class _TopBar extends StatelessWidget {
  const _TopBar({required this.border, required this.onBack});
  final Color border;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xCC0F172A) : const Color(0xCCF8FAFC);

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
            label: Text(
              context.tr('ai_review.nav.back'),
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Text(
            context.tr('ai_review.nav.title'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    required this.card,
    required this.border,
  });

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
              Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.06,
            ),
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
  const _Labeled({
    required this.label,
    required this.child,
    required this.isDark,
  });

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

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.text,
    required this.fg,
    required this.bg,
  });

  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

class _AiConfidenceBadge extends StatelessWidget {
  const _AiConfidenceBadge({
    required this.confidence,
    required this.isDark,
    required this.primary,
  });

  final double confidence;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "AI CONFIDENCE",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const Gap(2),
            Text(
              "${(confidence * 100).toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.cs,
    required this.isDark,
    this.bold = false,
    this.tint,
    this.enabled = true,
    this.compact = false,
  });

  final String value;
  final List<String> items;
  final String Function(String key) itemLabel;
  final ValueChanged<String> onChanged;
  final ColorScheme cs;
  final bool isDark;
  final bool bold;
  final Color? tint;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFE2E8F0);
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);

    final effectiveTint =
        tint ?? (bold ? cs.primary : (isDark ? Colors.white70 : Colors.black87));
    final height = compact ? 36.0 : 44.0;
    final horizontalPadding = compact ? 8.0 : 10.0;
    final fontSize = compact ? 12.0 : 13.0;
    final radius = compact ? 12.0 : 14.0;

    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(
              Icons.expand_more,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: effectiveTint,
            ),
            dropdownColor: isDark ? const Color(0xFF0B1220) : Colors.white,
            items: items
                .map(
                  (k) => DropdownMenuItem(
                    value: k,
                    child: Text(itemLabel(k)),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (v) {
                    if (v != null) onChanged(v);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class _Textarea extends StatelessWidget {
  const _Textarea({
    required this.controller,
    required this.isDark,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool isDark;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF1F2A3A) : const Color(0xFFE2E8F0);
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);

    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: TextField(
          controller: controller,
          enabled: enabled,
          maxLines: 4,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _SinbadChoiceField extends StatelessWidget {
  const _SinbadChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.isDark,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final bool isDark;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  "$label:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: options.asMap().entries.expand((entry) sync* {
                  final option = entry.value;
                  yield _SinbadOptionChip(
                    text: option,
                    selected: value == option,
                    isDark: isDark,
                    enabled: enabled,
                    isRisk: _isRiskSinbadOption(label, option),
                    onTap: () => onChanged(option),
                  );
                  if (entry.key != options.length - 1) {
                    yield Text(
                      "|",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    );
                  }
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _wifiComponentLabel(String prefix, String key) {
  switch (key) {
    case 'wifi_0':
      return '$prefix: 0';
    case 'wifi_1':
      return '$prefix: 1';
    case 'wifi_2':
      return '$prefix: 2';
    case 'wifi_3':
      return '$prefix: 3';
    default:
      return '$prefix: -';
  }
}

String _wifiComponentValueLabel(String key) {
  switch (key) {
    case 'wifi_0':
      return '0';
    case 'wifi_1':
      return '1';
    case 'wifi_2':
      return '2';
    case 'wifi_3':
      return '3';
    default:
      return '-';
  }
}

class _WifiComponentField extends StatelessWidget {
  const _WifiComponentField({
    required this.prefix,
    required this.value,
    required this.isDark,
    required this.enabled,
    required this.cs,
    required this.onChanged,
  });

  final String prefix;
  final String value;
  final bool isDark;
  final bool enabled;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$prefix:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const Gap(6),
        SizedBox(
          width: 68,
          child: _DropdownBox(
            value: value,
            items: const [
              'wifi_na',
              'wifi_0',
              'wifi_1',
              'wifi_2',
              'wifi_3',
            ],
            itemLabel: _wifiComponentValueLabel,
            onChanged: onChanged,
            cs: cs,
            isDark: isDark,
            enabled: enabled,
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _WifiSeparator extends StatelessWidget {
  const _WifiSeparator({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      '|',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }
}

class _SinbadOptionChip extends StatelessWidget {
  const _SinbadOptionChip({
    required this.text,
    required this.selected,
    required this.isDark,
    required this.enabled,
    required this.isRisk,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool isDark;
  final bool enabled;
  final bool isRisk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isRisk
        ? Colors.red
        : Theme.of(context).colorScheme.primary;
    final disabledColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final fg = !enabled
        ? disabledColor
        : selected
            ? selectedColor
            : (isDark ? Colors.white70 : const Color(0xFF334155));

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 15,
              color: fg,
            ),
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
      ),
    );
  }
}

class _SinbadScoreLine extends StatelessWidget {
  const _SinbadScoreLine({
    required this.score,
    required this.isDark,
  });

  final int score;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _sinbadScoreColor(score);

    return Text(
      "SINBAD SCORE $score/6",
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: scoreColor,
      ),
    );
  }
}

bool _isRiskSinbadOption(String label, String option) {
  switch (label) {
    case "Site":
      return option == "Midfoot / Hindfoot";
    case "Ischemia":
    case "Neuropathy":
    case "Bacterial":
      return option == "YES";
    case "Area":
      return option == ">= 1 cm²";
    case "Depth":
      return option == "Deep/Bone";
    default:
      return false;
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = active
        ? activeColor
        : (isDark ? const Color(0xFF1F2A3A) : const Color(0xFFE2E8F0));
    final bg = active
        ? activeColor.withOpacity(isDark ? 0.16 : 0.08)
        : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: active ? 1.6 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: activeColor),
            const Gap(8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
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
    this.icon,
    required this.onPressed,
    required this.cs,
  });

  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
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
  final VoidCallback? onPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? Colors.white24 : Colors.black26;
    final fg = isDark ? Colors.white70 : Colors.black87;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
