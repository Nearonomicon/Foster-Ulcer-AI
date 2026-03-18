import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/ai_analysis_screen.dart';
import 'package:flutter_application/features/auth/services/case_service.dart';
import 'package:flutter_application/shared/app_localizations.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;

  const CaseDetailScreen({
    super.key,
    required this.caseId,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  int selectedTimelineIndex = 0;

  final CaseService _caseService = CaseService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _caseResponse;

  @override
  void initState() {
    super.initState();
    _loadCaseDetail();
  }

  Future<void> _loadCaseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _caseService.getCaseDetail(widget.caseId);

      if (!mounted) return;

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

  int _calcAgeFromDob(String dob) {
    final birth = DateTime.tryParse(dob);
    if (birth != null) {
      final now = DateTime.now();
      int age = now.year - birth.year;
      final hadBirthday =
          (now.month > birth.month) ||
          (now.month == birth.month && now.day >= birth.day);
      if (!hadBirthday) age -= 1;
      return age;
    }

    final parts = dob.split("/");
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final m = int.tryParse(parts[1]) ?? 1;
      final y = int.tryParse(parts[2]) ?? 2000;
      final birth2 = DateTime(y, m, d);
      final now = DateTime.now();
      int age = now.year - birth2.year;
      final hadBirthday =
          (now.month > birth2.month) ||
          (now.month == birth2.month && now.day >= birth2.day);
      if (!hadBirthday) age -= 1;
      return age;
    }

    return 0;
  }

  String _formatStage(String raw) {
    final up = raw.toUpperCase().trim();
    if (up.startsWith("STAGE")) {
      final num = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (num.isNotEmpty) return "Stage $num";
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF273449) : const Color(0xFFE6EBF2);

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
        appBar: AppBar(title: const Text("Case Detail")),
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

    final response = _caseResponse ?? <String, dynamic>{};
    final data = _asMap(response["data"]);
    final caseBundle = _asMap(data["case_bundle"]);

    final summary = _asMap(caseBundle["case_summary"]);
    final rootPatient = _asMap(caseBundle["patient_profile"]);
    final rootNurse = _asMap(caseBundle["nurse_reviewed"]);
    final rootAi = _asMap(caseBundle["ai_analysis"]);

    final images = _asMapList(caseBundle["wound_images"]);
    final permissions = _asMap(caseBundle["permissions"]);

    final sortedImages = [...images];
    if (sortedImages.isEmpty) {
      sortedImages.add(<String, dynamic>{});
    }

    final safeSelectedIndex =
        selectedTimelineIndex >= sortedImages.length ? 0 : selectedTimelineIndex;

    final selectedImage = sortedImages[safeSelectedIndex];

    final patient = selectedImage["patient_snapshot"] != null
        ? _asMap(selectedImage["patient_snapshot"])
        : rootPatient;

    final nurse = selectedImage["wound_snapshot"] != null
        ? _asMap(selectedImage["wound_snapshot"])
        : rootNurse;

    final ai = selectedImage["ai_snapshot"] != null
        ? _asMap(selectedImage["ai_snapshot"])
        : rootAi;

    final patientName = (patient["patient_name"] ?? "Unknown").toString();
    final genderRaw = (patient["gender"] ?? "").toString().toLowerCase();
    final genderText = genderRaw == "male"
        ? context.tr('common.gender.male')
        : genderRaw == "female"
            ? context.tr('common.gender.female')
            : context.tr('common.na');

    final dob = (patient["dob"] ?? "").toString();
    final age = (patient["age"] is int)
        ? patient["age"] as int
        : _calcAgeFromDob(dob);

    final diabetesFlag = patient["diabetes_flag"] == true;

    final medicalHistory =
        (patient["medical_history"] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];

    final comorbidities =
        (patient["comorbidities"] as List?)?.map((e) => e.toString()).toList() ??
            medicalHistory;

    final urgencyRaw = (summary["urgency"] ?? "").toString().toUpperCase();
    final isHighUrgency = urgencyRaw == "HIGH" || urgencyRaw == "HIGH_URGENT";

    final aiConfidence = (ai["confidence"] is num)
        ? (ai["confidence"] as num).toDouble()
        : 0.0;
    final aiConfidencePct = (aiConfidence * 100).round();
    final aiDiagnosis = (ai["diagnosis"] ?? "").toString();
    final aiDescription = (ai["description"] ?? "").toString();
    final aiDraftStatus = (ai["draft_status"] ?? "READY").toString();

    final selectedImageUrl = _safeImageUrl(selectedImage["image_url"]);

    final canEditAiReview = permissions["can_edit_ai_review"] == true;

    final vitalsTemp = _displayValue(nurse["temperature_c"] ?? nurse["temperature"]);
    final vitalsBp = _displayValue(nurse["blood_pressure"]);
    final vitalsHr = _displayValue(nurse["heart_rate"]);
    final vitalsRr = _displayValue(nurse["respiratory_rate"]);
    final vitalsSugar = _displayValue(nurse["blood_glucose_mg_dl"]);

    final sinbadSite =
        _displayValue(nurse["sinbad_site"] ?? nurse["location_primary"]);
    final sinbadIschemia =
        _yesNo(nurse["sinbad_ischemia"] ?? nurse["wifi_pulse_check"]);
    final sinbadNeuropathy = _yesNo(nurse["sinbad_neuropathy"]);
    final sinbadInfection =
        _yesNo(nurse["sinbad_infection"] ?? nurse["has_infection"]);
    final sinbadArea = _displayValue(nurse["sinbad_area"] ?? nurse["area_cm2"]);
    final sinbadDepth =
        _displayValue(nurse["sinbad_depth"] ?? nurse["depth_category"]);
    final sinbadTotal = _displayValue(nurse["sinbad_total_score"]);

    final woundLocationPrimary = _displayValue(nurse["location_primary"]);
    final woundLocationDetail = _displayValue(nurse["location_detail"]);
    final woundTypeText = _displayValue(nurse["wound_type"]);
    final woundShapeText = _displayValue(nurse["shape"]);

    final woundSizePair =
        _sizePair(nurse["size_width_cm"], nurse["size_length_cm"]);
    final woundDepthCategory = _displayValue(nurse["depth_category"]);

    final woundSlough = _percentText(nurse["bed_slough_pct"]);
    final woundNecrotic = _percentText(nurse["bed_necrotic_pct"]);
    final woundEdge = _displayValue(nurse["edge_description"]);
    final woundPeriwound = _displayValue(nurse["periwound_status"]);

    final woundDischargeVolume = _displayValue(nurse["discharge_volume"]);
    final woundDischargeType = _displayValue(nurse["discharge_type"]);
    final woundOdor = _displayValue(nurse["odor_presence"]);
    final woundPain = _painText(nurse["pain_score"]);
    final woundHasInfection = _yesNo(nurse["has_infection"]);
    final woundSkinCondition = _displayValue(nurse["skin_condition"]);

    final wifiPulseCheck = _yesNo(nurse["wifi_pulse_check"]);
    final wifiIschemiaChecklist = _joinList(nurse["wifi_ischemia_checklist"]);
    final wifiIschemiaPoints = _joinList(nurse["wifi_ischemia_points"]);
    final wifiAbi = _displayValue(nurse["wifi_abi"]);
    final wifiAnklePressure = _displayValue(nurse["wifi_ankle_pressure"]);
    final wifiToePressure = _displayValue(nurse["wifi_toe_pressure"]);
    final wifiTcpo2 = _displayValue(nurse["wifi_tcpo2"]);

    final wifiGangreneExtent = _displayValue(nurse["wifi_gangrene_extent"]);
    final wifiWoundDepth =
        _displayValue(nurse["wifi_wound_depth"] ?? nurse["depth_category"]);
    final wifiWoundLocation =
        _displayValue(nurse["wifi_wound_location"] ?? nurse["location_primary"]);

    final idsaChecklist = _joinList(nurse["idsa_infection_checklist"]);
    final idsaErythemaExtent = _displayValue(nurse["idsa_erythema_extent"]);
    final idsaProbeToBone = _displayValue(nurse["idsa_probe_to_bone"]);
    final idsaDeepAbscess = _yesNo(nurse["idsa_deep_abscess_fasciitis"]);

    final neuropathyPoints = _joinList(nurse["neuropathy_points"]);

    final labWbc = _displayValue(nurse["lab_wbc"]);
    final labCrp = _displayValue(nurse["lab_crp"]);
    final labEsr = _displayValue(nurse["lab_esr"]);
    final labProcalcitonin = _displayValue(nurse["lab_procalcitonin"]);

    final advancedErythemaExtent = _displayValue(
      nurse["advanced_erythema_extent"] ?? nurse["idsa_erythema_extent"],
    );
    final advancedProbeToBone = _displayValue(
      nurse["advanced_probe_to_bone"] ?? nurse["idsa_probe_to_bone"],
    );
    final advancedDeepAbscess = _yesNo(
      nurse["advanced_deep_abscess_fasciitis"] ??
          nurse["idsa_deep_abscess_fasciitis"],
    );
    final advancedGangreneExtent = _displayValue(
      nurse["advanced_gangrene_extent"] ?? nurse["wifi_gangrene_extent"],
    );

    final aiNarrative = _displayValue(ai["description"] ?? ai["narrative"]);
    final aiIdsaStage = _displayValue(ai["idsa_stage"]);
    final aiWifiWound = _displayValue(ai["wifi_wound"]);
    final aiWifiIschemia = _displayValue(ai["wifi_ischemia"]);
    final aiWifiFootInfection = _displayValue(ai["wifi_foot_infection"]);
    final aiWifiClinicalStage = _displayValue(ai["wifi_stage"]);
    final aiSinbadTotal = _displayValue(ai["sinbad_total"]);
    final aiSinbadSite = _displayValue(ai["sinbad_site"]);
    final aiSinbadIschemia = _yesNo(ai["sinbad_ischemia"]);
    final aiSinbadNeuropathy = _yesNo(ai["sinbad_neuropathy"]);
    final aiSinbadInfection = _yesNo(ai["sinbad_infection"]);
    final aiSinbadArea = _displayValue(ai["sinbad_area"]);
    final aiSinbadDepth = _displayValue(ai["sinbad_depth"]);

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
                title: context.tr('case_detail.header.title'),
                caseIdText: "${context.tr('common.id')}: #${widget.caseId}",
                tag1: diabetesFlag
                    ? "${context.tr('case_detail.header.medical')}: Diabetes"
                    : "${context.tr('case_detail.header.medical')}: ${context.tr('common.na')}",
                tag2: isHighUrgency
                    ? context.tr('common.urgency.high')
                    : context.tr('common.urgency.routine'),
                tag2IsHigh: isHighUrgency,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _SectionCard(
                      titleIcon: Icons.person_search,
                      title: context.tr('case_detail.section.patient_profile'),
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
                                  title: context.tr('case_detail.field.age_gender'),
                                  value: "${age == 0 ? "-" : age}, $genderText",
                                  isDark: isDark,
                                ),
                              ),
                              Expanded(
                                child: _KeyVal(
                                  title: context.tr('case_detail.field.vitals'),
                                  value:
                                      "$vitalsBp • ${context.tr('case_detail.field.hr')} $vitalsHr",
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const Gap(14),
                          Row(
                            children: [
                              Expanded(
                                child: _KeyVal(
                                  title: "Temperature",
                                  value: vitalsTemp == "-" ? "-" : "$vitalsTemp °C",
                                  isDark: isDark,
                                ),
                              ),
                              Expanded(
                                child: _KeyVal(
                                  title: "Blood Glucose",
                                  value: vitalsSugar == "-" ? "-" : "$vitalsSugar mg/dL",
                                  isDark: isDark,
                                ),
                              ),
                              Expanded(
                                child: _KeyVal(
                                  title: "RR",
                                  value: vitalsRr,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const Gap(14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.tr('case_detail.field.comorbidities').toUpperCase(),
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
                            children: comorbidities.isEmpty
                                ? [_Pill(text: context.tr('common.none'))]
                                : comorbidities.map((e) => _Pill(text: e)).toList(),
                          ),
                        ],
                      ),
                    ),
                    const Gap(18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(
                          icon: Icons.history,
                          text: context.tr('case_detail.section.wound_timeline'),
                          isDark: isDark,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            context.tr('common.view_all'),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),

                    SizedBox(
                      height: 380,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sortedImages.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (context, index) {
                          final img = sortedImages[index];
                          final imgSnapshot = img["wound_snapshot"] != null
                              ? _asMap(img["wound_snapshot"])
                              : rootNurse;
                          final imgAi = img["ai_snapshot"] != null
                              ? _asMap(img["ai_snapshot"])
                              : rootAi;

                          final imgUrl = _safeImageUrl(img["image_url"]).isNotEmpty
                              ? _safeImageUrl(img["image_url"])
                              : _safeImageUrl(selectedImageUrl);

                          final visitLabel =
                              (img["visit_day_label"] ?? "Visit").toString();
                          final isLatest = img["is_latest"] == true;
                          final isSelected = index == safeSelectedIndex;

                          final imgWidth = imgSnapshot["size_width_cm"];
                          final imgLength = imgSnapshot["size_length_cm"];
                          final imgArea = imgSnapshot["area_cm2"] ??
                              ((imgWidth is num && imgLength is num)
                                  ? (imgWidth * imgLength)
                                  : null);

                          final imgNote =
                              (imgSnapshot["nurse_note"] ??
                                      img["nurse_note"] ??
                                      "")
                                  .toString();

                          final imgAiStage =
                              _formatStage((imgAi["wound_stage"] ?? "").toString());
                          final imgAiConfidence = (imgAi["confidence"] is num)
                              ? ((imgAi["confidence"] as num).toDouble() * 100)
                                  .round()
                              : 0;

                          return _TimelineCard(
                            isDark: isDark,
                            card: card,
                            border: border,
                            primary: cs.primary,
                            latest: isLatest,
                            selected: isSelected,
                            date: visitLabel,
                            subtitle: "AI: $imgAiStage • $imgAiConfidence%",
                            imageUrl: imgUrl,
                            area: imgArea == null ? "-" : "${imgArea.toString()} cm²",
                            note: imgNote.isEmpty ? "-" : imgNote,
                            areaIsBad: isSelected ? isHighUrgency : false,
                            latestLabel: context.tr('common.latest'),
                            areaLabel: context.tr('case_detail.field.area_est'),
                            onTap: () {
                              setState(() {
                                selectedTimelineIndex = index;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const Gap(18),

                    _AiAnalysisCard(
                      isDark: isDark,
                      primary: cs.primary,
                      aiText: aiDescription.isEmpty ? aiDiagnosis : aiDescription,
                      confidenceText: "$aiConfidencePct%",
                      onReviewAi: canEditAiReview
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AiAnalysisScreen(
                                    caseId: widget.caseId,
                                    selectedTimelineIndex: safeSelectedIndex,
                                  ),
                                ),
                              );
                            }
                          : () {},
                      title: context.tr('case_detail.section.ai_analysis'),
                      metricConfidence: context.tr('case_detail.metric.confidence'),
                      metricAiDraft: context.tr('case_detail.metric.ai_draft'),
                      aiDraftValue: aiDraftStatus,
                      cta: context.tr('case_detail.cta.review_ai'),
                    ),
                    const Gap(18),

                    _SectionCard(
                      titleIcon: Icons.description,
                      title: "Wound Details",
                      cs: cs,
                      isDark: isDark,
                      card: card,
                      border: border,
                      child: Column(
                        children: [
                          _DataGroupCard(
                            title: "Assessment Inputs",
                            isDark: isDark,
                            children: [
                              _SubGroupTitle(text: "Vitals", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Temperature", vitalsTemp),
                                  _DetailRowData("Blood Pressure", vitalsBp),
                                  _DetailRowData("Heart Rate", vitalsHr),
                                  _DetailRowData("Respiratory Rate", vitalsRr),
                                  _DetailRowData("Blood Sugar", vitalsSugar),
                                ],
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "SINBAD", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Site", sinbadSite),
                                  _DetailRowData("Ischemia", sinbadIschemia),
                                  _DetailRowData("Neuropathy", sinbadNeuropathy),
                                  _DetailRowData("Infection", sinbadInfection),
                                  _DetailRowData("Area", sinbadArea),
                                  _DetailRowData("Depth", sinbadDepth),
                                  _DetailRowData("Total Score", sinbadTotal),
                                ],
                              ),
                            ],
                          ),
                          const Gap(14),

                          _DataGroupCard(
                            title: "Wound Basics",
                            isDark: isDark,
                            children: [
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Location Primary", woundLocationPrimary),
                                  _DetailRowData("Location Detail", woundLocationDetail),
                                  _DetailRowData("Wound Type", woundTypeText),
                                  _DetailRowData("Shape", woundShapeText),
                                ],
                              ),
                            ],
                          ),
                          const Gap(14),

                          _DataGroupCard(
                            title: "Size & Depth",
                            isDark: isDark,
                            children: [
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Width / Length", woundSizePair),
                                  _DetailRowData("Depth Category", woundDepthCategory),
                                ],
                              ),
                            ],
                          ),
                          const Gap(14),

                          _DataGroupCard(
                            title: "Tissue & Edge",
                            isDark: isDark,
                            children: [
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Bed Slough %", woundSlough),
                                  _DetailRowData("Bed Necrotic %", woundNecrotic),
                                  _DetailRowData("Edge Description", woundEdge),
                                  _DetailRowData("Periwound Status", woundPeriwound),
                                ],
                              ),
                            ],
                          ),
                          const Gap(14),

                          _DataGroupCard(
                            title: "Discharge & Symptoms",
                            isDark: isDark,
                            children: [
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Discharge Volume", woundDischargeVolume),
                                  _DetailRowData("Discharge Type", woundDischargeType),
                                  _DetailRowData("Odor Presence", woundOdor),
                                  _DetailRowData("Pain Score", woundPain),
                                  _DetailRowData("Has Infection", woundHasInfection),
                                  _DetailRowData("Skin Condition", woundSkinCondition),
                                ],
                              ),
                            ],
                          ),
                          const Gap(14),

                          _DataGroupCard(
                            title: "Advanced Inputs (WIfI / IDSA)",
                            isDark: isDark,
                            children: [
                              _SubGroupTitle(text: "WIfI: Ischemia", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Pulse Check", wifiPulseCheck),
                                  _DetailRowData("Ischemia Checklist", wifiIschemiaChecklist),
                                  _DetailRowData("Ischemia Points", wifiIschemiaPoints),
                                  _DetailRowData("ABI", wifiAbi),
                                  _DetailRowData("Ankle Pressure", wifiAnklePressure),
                                  _DetailRowData("Toe Pressure", wifiToePressure),
                                  _DetailRowData("TcPO2", wifiTcpo2),
                                ],
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "WIfI: Wound", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Gangrene Extent", wifiGangreneExtent),
                                  _DetailRowData("Depth Category", wifiWoundDepth),
                                  _DetailRowData("Location Primary", wifiWoundLocation),
                                ],
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "IDSA: Infection", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Infection Checklist", idsaChecklist),
                                  _DetailRowData("Erythema Extent", idsaErythemaExtent),
                                  _DetailRowData("Probe-to-Bone", idsaProbeToBone),
                                  _DetailRowData(
                                    "Deep Abscess/Fasciitis",
                                    idsaDeepAbscess,
                                  ),
                                ],
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "Neuropathy", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Neuropathy Points", neuropathyPoints),
                                ],
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "Labs", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("WBC Count", labWbc),
                                  _DetailRowData("CRP", labCrp),
                                  _DetailRowData("ESR", labEsr),
                                  _DetailRowData("Procalcitonin", labProcalcitonin),
                                ],
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "Advanced Inputs", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Erythema Extent", advancedErythemaExtent),
                                  _DetailRowData("Probe-to-Bone", advancedProbeToBone),
                                  _DetailRowData(
                                    "Deep Abscess/Fasciitis",
                                    advancedDeepAbscess,
                                  ),
                                  _DetailRowData("Gangrene Extent", advancedGangreneExtent),
                                ],
                              ),
                            ],
                          ),
                          const Gap(14),

                          _DataGroupCard(
                            title: "AI Results",
                            isDark: isDark,
                            children: [
                              _SubGroupTitle(text: "AI Narrative", isDark: isDark),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0B1220)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  aiNarrative,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "AI Classifications", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("IDSA Stage", aiIdsaStage),
                                  _DetailRowData("WIfI Wound", aiWifiWound),
                                  _DetailRowData("WIfI Ischemia", aiWifiIschemia),
                                  _DetailRowData(
                                    "WIfI Foot Infection",
                                    aiWifiFootInfection,
                                  ),
                                  _DetailRowData(
                                    "WIfI Clinical Stage",
                                    aiWifiClinicalStage,
                                  ),
                                  _DetailRowData("SINBAD Total", aiSinbadTotal),
                                ],
                              ),
                              const Gap(16),
                              _SubGroupTitle(text: "SINBAD Breakdown", isDark: isDark),
                              _DetailPairTable(
                                isDark: isDark,
                                rows: [
                                  _DetailRowData("Site", aiSinbadSite),
                                  _DetailRowData("Ischemia", aiSinbadIschemia),
                                  _DetailRowData("Neuropathy", aiSinbadNeuropathy),
                                  _DetailRowData("Infection", aiSinbadInfection),
                                  _DetailRowData("Area", aiSinbadArea),
                                  _DetailRowData("Depth", aiSinbadDepth),
                                ],
                              ),
                            ],
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
    );
  }
}

/* ---------------- helpers ---------------- */

String _displayValue(dynamic v) {
  if (v == null) return "-";
  final s = v.toString().trim();
  if (s.isEmpty) return "-";
  return s;
}

String _yesNo(dynamic v) {
  if (v == true) return "Yes";
  if (v == false) return "No";

  final s = v?.toString().toLowerCase().trim() ?? "";
  if (s == "true" || s == "yes" || s == "y" || s == "1") return "Yes";
  if (s == "false" || s == "no" || s == "n" || s == "0") return "No";
  return s.isEmpty ? "-" : s;
}

String _joinList(dynamic v) {
  if (v is List) {
    final list =
        v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    return list.isEmpty ? "-" : list.join(", ");
  }
  return _displayValue(v);
}

String _sizePair(dynamic width, dynamic length) {
  final w = _displayValue(width);
  final l = _displayValue(length);
  if (w == "-" && l == "-") return "-";
  return "$w cm / $l cm";
}

String _percentText(dynamic v) {
  if (v == null) return "-";
  return "${v.toString()}%";
}

String _painText(dynamic v) {
  if (v == null) return "-";
  return "${v.toString()}/10";
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
        children: const [
          Text(
            "9:41",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 18),
              SizedBox(width: 6),
              Icon(Icons.wifi, size: 18),
              SizedBox(width: 6),
              Icon(Icons.battery_full, size: 18),
            ],
          ),
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
    required this.title,
    required this.caseIdText,
    required this.tag1,
    required this.tag2,
    required this.tag2IsHigh,
  });

  final ColorScheme cs;
  final bool isDark;
  final Color card;
  final Color border;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final String patientName;
  final String title;
  final String caseIdText;
  final String tag1;
  final String tag2;
  final bool tag2IsHigh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.chevron_left,
                onTap: onBack,
                card: card,
                border: border,
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              _CircleIconButton(
                icon: Icons.more_horiz,
                onTap: onMore,
                card: card,
                border: border,
                iconColor: cs.primary,
              ),
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
                child: Icon(
                  Icons.person,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
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
                        _Tag(
                          text: tag2,
                          tone: tag2IsHigh ? TagTone.red : TagTone.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
  const _SectionTitle({
    required this.icon,
    required this.text,
    required this.isDark,
  });

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
                Icon(
                  titleIcon,
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
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
  const _KeyVal({
    required this.title,
    required this.value,
    required this.isDark,
  });

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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
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
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
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
    required this.selected,
    required this.date,
    required this.imageUrl,
    required this.area,
    required this.note,
    required this.areaIsBad,
    required this.latestLabel,
    required this.areaLabel,
    required this.onTap,
    this.subtitle,
  });

  final bool isDark;
  final Color card;
  final Color border;
  final Color primary;
  final bool latest;
  final bool selected;
  final String date;
  final String imageUrl;
  final String? subtitle;
  final String area;
  final String note;
  final bool areaIsBad;
  final String latestLabel;
  final String areaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = selected ? primary : (latest ? primary : border);
    final effectiveBorderWidth = selected ? 3.0 : (latest ? 2.0 : 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: latest ? 280 : 240,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: effectiveBorderColor,
              width: effectiveBorderWidth,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.18),
                      blurRadius: 18,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: imageUrl.isEmpty
                            ? Container(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.06),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 44,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                ),
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withOpacity(0.06),
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 44,
                                    color: isDark ? Colors.white30 : Colors.black26,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(latest ? 0.60 : 0.40),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: latest ? 18 : 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const Gap(4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (latest)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            latestLabel.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        top: latest ? 44 : 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "SELECTED",
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
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
                        Text(
                          areaLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              area,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: areaIsBad
                                    ? const Color(0xFFEF4444)
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                              ),
                            ),
                            if (areaIsBad) ...[
                              const Gap(4),
                              const Icon(
                                Icons.trending_up,
                                size: 16,
                                color: Color(0xFFEF4444),
                              ),
                            ],
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          areaIsBad ? const Color(0xFFEF4444) : primary,
                        ),
                      ),
                    ),
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? primary.withOpacity(0.12)
                            : primary.withOpacity(0.08),
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
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: isDark ? Colors.white70 : Colors.black54,
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
            ],
          ),
        ),
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
    required this.title,
    required this.metricConfidence,
    required this.metricAiDraft,
    required this.aiDraftValue,
    required this.cta,
  });

  final bool isDark;
  final Color primary;
  final VoidCallback onReviewAi;
  final String aiText;
  final String confidenceText;
  final String title;
  final String metricConfidence;
  final String metricAiDraft;
  final String aiDraftValue;
  final String cta;

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
              Icon(
                Icons.insights,
                color: isDark
                    ? Colors.lightBlueAccent
                    : const Color(0xFF1D4ED8),
              ),
              const Gap(8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? Colors.lightBlueAccent
                      : const Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            aiText,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  title: metricConfidence,
                  value: confidenceText,
                  isDark: isDark,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _MetricBox(
                  title: metricAiDraft,
                  value: aiDraftValue,
                  isDark: isDark,
                ),
              ),
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
                  Text(
                    cta,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Gap(6),
                  Icon(
                    Icons.chevron_right,
                    color: primary.withOpacity(0.5),
                  ),
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
  const _MetricBox({
    required this.title,
    required this.value,
    required this.isDark,
  });

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
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          const Gap(6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DetailRowData {
  final String label;
  final String value;

  const _DetailRowData(this.label, this.value);
}

class _DataGroupCard extends StatelessWidget {
  const _DataGroupCard({
    required this.title,
    required this.isDark,
    required this.children,
  });

  final String title;
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF273449) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F9D8A),
            ),
          ),
          const Gap(14),
          ...children,
        ],
      ),
    );
  }
}

class _SubGroupTitle extends StatelessWidget {
  const _SubGroupTitle({
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F9D8A),
        ),
      ),
    );
  }
}

class _DetailPairTable extends StatelessWidget {
  const _DetailPairTable({
    required this.rows,
    required this.isDark,
  });

  final List<_DetailRowData> rows;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      r.label,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    flex: 7,
                    child: Text(
                      r.value,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

enum TagTone { blue, orange, red }

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.tone,
  });

  final String text;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bg, fg) = switch (tone) {
      TagTone.blue => (
          isDark ? const Color(0x332563EB) : const Color(0xFFDBEAFE),
          isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB)
        ),
      TagTone.orange => (
          isDark ? const Color(0x334F2A0B) : const Color(0xFFFFEDD5),
          isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C)
        ),
      TagTone.red => (
          isDark ? const Color(0x337F1D1D) : const Color(0xFFFEE2E2),
          isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}