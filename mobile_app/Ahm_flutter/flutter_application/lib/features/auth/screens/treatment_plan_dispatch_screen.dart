import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_application/features/auth/screens/review_treatment_plan_screen.dart';
import 'package:flutter_application/features/auth/services/case_service.dart';
import 'package:flutter_application/shared/app_localizations.dart';

class TreatmentPlanDispatchScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? doctorReviewDraft;
  final bool aiResultEditFlag;

  const TreatmentPlanDispatchScreen({
    super.key,
    required this.caseId,
    this.doctorReviewDraft,
    this.aiResultEditFlag = false,
  });

  @override
  State<TreatmentPlanDispatchScreen> createState() =>
      _TreatmentPlanDispatchScreenState();
}

class _TreatmentPlanDispatchScreenState
    extends State<TreatmentPlanDispatchScreen> {
  final CaseService _caseService = CaseService();

  bool _isLoading = true;
  bool _isSavingDraft = false;
  String? _error;
  Map<String, dynamic>? _caseResponse;

  late final TextEditingController planCtrl;
  late List<Map<String, dynamic>> tasks;

  String? aiAccuracySelection; // "accurate" | "needs_correction"
  String _planId = "";
  int _followupDays = 3;

  void _changeFollowupDays(int delta) {
    setState(() {
      final next = _followupDays + delta;
      _followupDays = next < 1 ? 1 : next;
    });
  }

  @override
  void initState() {
    super.initState();
    planCtrl = TextEditingController();
    tasks = [];
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

  @override
  void dispose() {
    planCtrl.dispose();
    for (final t in tasks) {
      final ctrl = t["controller"];
      if (ctrl is TextEditingController) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadCaseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _caseService.getCaseDetail(widget.caseId);

      final data = _asMap(response["data"]);
      final caseBundle = _asMap(data["case_bundle"]);
      final aiAnalysis = _asMap(caseBundle["ai_analysis"]);
      final currentPlan = _asMap(caseBundle["current_treatment_plan"]);

      Map<String, dynamic> taskDetailResponse = <String, dynamic>{};
      Map<String, dynamic> taskDetailTreatment = <String, dynamic>{};
      Map<String, dynamic> firstTaskDetail = <String, dynamic>{};

      try {
        taskDetailResponse = await _caseService.getTaskDetail(
          caseId: widget.caseId,
          taskIndex: 0,
        );
        taskDetailTreatment = _asMap(taskDetailResponse["current_treatment"]);
        firstTaskDetail = _asMap(taskDetailResponse["task"]);
      } catch (e) {
        debugPrint("getTaskDetail failed but skipped: $e");
      }

      final effectivePlan = taskDetailTreatment.isNotEmpty
          ? taskDetailTreatment
          : currentPlan;

      final apiPlanText = (effectivePlan["plan_text"] ?? "").toString().trim();
      final aiPlanText =
          (aiAnalysis["treatment_suggestion"] ?? "").toString().trim();

      final apiPlanId = (effectivePlan["plan_id"] ?? "").toString();

      final apiFollowupDays = effectivePlan["followup_days"] is int
          ? effectivePlan["followup_days"] as int
          : int.tryParse("${effectivePlan["followup_days"] ?? 3}") ?? 3;

      final apiTasks = _asMapList(effectivePlan["plan_tasks"]);

      if (apiTasks.isNotEmpty && firstTaskDetail.isNotEmpty) {
        apiTasks[0] = {
          ...apiTasks[0],
          ...firstTaskDetail,
        };
      }

      for (final t in tasks) {
        final ctrl = t["controller"];
        if (ctrl is TextEditingController) {
          ctrl.dispose();
        }
      }
      tasks.clear();

      planCtrl.text = apiPlanText.isNotEmpty ? apiPlanText : aiPlanText;

      if (apiTasks.isNotEmpty) {
        tasks.addAll(
          apiTasks.map(
            (t) => {
              "controller": TextEditingController(
                text: (t["task_text"] ?? "").toString(),
              ),
              "source": (t["source"] ?? "ai").toString(),
              "status": (t["status"] ?? "DRAFT").toString(),
              "task_due": t["task_due"],
              "task_id": t["task_id"],
              "task_photo_url": t["task_photo_url"],
              "completed_at": t["completed_at"],
            },
          ),
        );
      } else {
        tasks.addAll([
          {
            "controller": TextEditingController(
              text: "Apply appropriate offloading device/padding.",
            ),
            "source": "ai",
            "status": "DRAFT",
            "task_due": null,
            "task_id": null,
            "task_photo_url": null,
            "completed_at": null,
          },
          {
            "controller": TextEditingController(
              text: "Debride non-viable tissue from wound bed.",
            ),
            "source": "ai",
            "status": "DRAFT",
            "task_due": null,
            "task_id": null,
            "task_photo_url": null,
            "completed_at": null,
          },
          {
            "controller": TextEditingController(
              text: "Apply moist wound dressing.",
            ),
            "source": "ai",
            "status": "DRAFT",
            "task_due": null,
            "task_id": null,
            "task_photo_url": null,
            "completed_at": null,
          },
          {
            "controller": TextEditingController(
              text: "Monitor for signs of infection.",
            ),
            "source": "ai",
            "status": "DRAFT",
            "task_due": null,
            "task_id": null,
            "task_photo_url": null,
            "completed_at": null,
          },
        ]);
      }

      if (!mounted) return;

      setState(() {
        _caseResponse = response;
        _planId = apiPlanId;
        _followupDays = apiFollowupDays;
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

  void _addTask() {
    setState(() {
      tasks.add({
        "controller": TextEditingController(text: ""),
        "source": "doctor",
        "status": "DRAFT",
        "task_due": null,
        "task_id": null,
        "task_photo_url": null,
        "completed_at": null,
      });
    });
  }

  void _removeTask(int index) {
    if (tasks.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one task is required.")),
      );
      return;
    }

    final controller = tasks[index]["controller"] as TextEditingController;

    setState(() {
      tasks.removeAt(index);
    });

    controller.dispose();
  }

  Future<void> _pickTaskDueDate(int index) async {
    final current = tasks[index]["task_due"]?.toString();
    final initialDate = DateTime.tryParse(current ?? "") ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      tasks[index]["task_due"] = picked.toIso8601String().split('T').first;
    });
  }

  Future<void> _saveDraftAndContinue() async {
    if (aiAccuracySelection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please evaluate AI accuracy before sending."),
        ),
      );
      return;
    }

    final cleanedTasks = tasks
        .map(
          (e) => {
            "task_text": (e["controller"] as TextEditingController).text.trim(),
            "source": (e["source"] ?? "ai").toString(),
            "status": (e["status"] ?? "DRAFT").toString(),
            "task_due": e["task_due"],
          },
        )
        .where((e) => (e["task_text"] ?? "").toString().isNotEmpty)
        .toList();

    if (planCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter treatment plan text."),
        ),
      );
      return;
    }

    if (cleanedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please keep at least one valid task."),
        ),
      );
      return;
    }

    setState(() {
      _isSavingDraft = true;
    });

    try {
      final response = _caseResponse ?? <String, dynamic>{};
      final data = _asMap(response["data"]);
      final caseBundle = _asMap(data["case_bundle"]);
      final aiAnalysis = _asMap(caseBundle["ai_analysis"]);
      final confidence = (aiAnalysis["confidence"] is num)
          ? (aiAnalysis["confidence"] as num).toDouble()
          : 0.0;
      final diagnosis = (aiAnalysis["diagnosis"] ?? "").toString();
      final planId = _planId;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewTreatmentPlanScreen(
            caseId: widget.caseId,
            planId: planId,
            planText: planCtrl.text.trim(),
            tasks: cleanedTasks,
            followupDays: _followupDays,
            aiConfidence: confidence,
            diagnosis: diagnosis,
            doctorReviewDraft: widget.doctorReviewDraft,
            aiResultEditFlag: widget.aiResultEditFlag,
            treatmentPlanEditFlag:
                aiAccuracySelection == "needs_correction",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Save draft failed: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF273449) : const Color(0xFFE6EBF2);

    const ai = Color(0xFF8B5CF6);

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
        appBar: AppBar(title: const Text("Treatment Plan")),
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

    final patient = _asMap(caseBundle["patient_profile"]);
    final nurseReviewed = _asMap(caseBundle["nurse_reviewed"]);
    final aiAnalysis = _asMap(caseBundle["ai_analysis"]);
    final summary = _asMap(caseBundle["case_summary"]);

    final patientName =
        (patient["patient_name"] ?? context.tr("common.na")).toString();

    final medicalHistoryList =
        (patient["medical_history"] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];
    final medicalHistoryText = medicalHistoryList.isEmpty
        ? context.tr("common.na")
        : medicalHistoryList.join(", ");

    final stageRaw = (aiAnalysis["wound_stage"] ?? "STAGE -").toString();
    final stageText = _normalizeStage(stageRaw);
    final diagnosisText =
        (aiAnalysis["diagnosis"] ?? context.tr("tp_dispatch.na_diagnosis"))
            .toString();
    final stagingDesc = (aiAnalysis["description"] ?? "").toString();

    final urgency = (summary["urgency"] ?? "").toString();
    final isHighUrgent =
        urgency.toUpperCase() == "HIGH" || urgency == "high_urgent";

    final urgencyBg = isHighUrgent
        ? (isDark
            ? const Color(0xFF7F1D1D).withOpacity(0.35)
            : const Color(0xFFFEE2E2))
        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05));

    final urgencyFg = isHighUrgent
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
        : (isDark ? Colors.white60 : Colors.black54);

    final urgencyLabel = isHighUrgent
        ? context.tr("common.urgency.high")
        : context.tr("tp_dispatch.urgency.normal");

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
                title: context.tr("tp_dispatch.title"),
                backLabel: context.tr("tp_dispatch.back"),
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
                      caseId: "#${widget.caseId}",
                      conditionTag: medicalHistoryText.toUpperCase(),
                      conditionBg: urgencyBg,
                      conditionFg: urgencyFg,
                      conditionLabel: urgencyLabel,
                      casePrefix: context.tr("tp_dispatch.case_prefix"),
                    ),
                    const Gap(18),
                    _SectionTitle(
                      icon: Icons.analytics_outlined,
                      text: context.tr("tp_dispatch.section.diagnosis_staging"),
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
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isHighUrgent
                                      ? (isDark
                                          ? const Color(0xFF78350F)
                                              .withOpacity(0.35)
                                          : const Color(0xFFFEF3C7))
                                      : (isDark
                                          ? Colors.white10
                                          : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isHighUrgent
                                      ? context.tr(
                                          "tp_dispatch.badge.action_required",
                                        )
                                      : context.tr("tp_dispatch.badge.stable"),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                    color: isHighUrgent
                                        ? (isDark
                                            ? const Color(0xFFFCD34D)
                                            : const Color(0xFFB45309))
                                        : (isDark
                                            ? Colors.white60
                                            : Colors.black54),
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
                            stagingDesc.isEmpty
                                ? _buildWoundSummary(nurseReviewed)
                                : stagingDesc,
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
                          text: context.tr(
                            "tp_dispatch.section.treatment_schedule",
                          ),
                          isDark: isDark,
                          iconColor: cs.primary,
                        ),
                        Text(
                          "${tasks.length} ${context.tr("tp_dispatch.tasks")}",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    _Card(
                      card: card,
                      border: border,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("Treatment Plan").toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const Gap(10),
                          _PlanTextarea(
                            controller: planCtrl,
                            isDark: isDark,
                            border: border,
                          ),
                          const Gap(14),
                          Text(
                            "FOLLOW-UP DAYS",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0B1220)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => _changeFollowupDays(-1),
                                  icon: const Icon(Icons.remove),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        "$_followupDays",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        _followupDays == 1 ? "day" : "days",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _changeFollowupDays(1),
                                  icon: const Icon(Icons.add),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    ...List.generate(tasks.length, (i) {
                      final controller =
                          tasks[i]["controller"] as TextEditingController;
                      final source = (tasks[i]["source"] ?? "ai").toString();
                      final isDoctor = source == "doctor";
                      final dueText =
                          _formatTaskDueText(tasks[i]["task_due"]);

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == tasks.length - 1 ? 0 : 12,
                        ),
                        child: _EditableTaskCard(
                          isDark: isDark,
                          card: card,
                          border: border,
                          num: "${i + 1}",
                          badgeText: isDoctor
                              ? "DOCTOR ADDED"
                              : context.tr("tp_dispatch.badge.ai_suggested"),
                          badgeColor: isDoctor ? cs.primary : ai,
                          badgeIcon: isDoctor
                              ? Icons.medical_services_outlined
                              : Icons.auto_awesome,
                          controller: controller,
                          dueText: dueText,
                          onPickDate: () => _pickTaskDueDate(i),
                          onDelete: () => _removeTask(i),
                        ),
                      );
                    }),
                    const Gap(12),
                    Center(
                      child: InkWell(
                        onTap: _addTask,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
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
                              Icon(
                                Icons.add,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const Gap(8),
                              Text(
                                context.tr("tp_dispatch.add_task"),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(18),
                    _AiAccuracySection(
                      isDark: isDark,
                      selectedValue: aiAccuracySelection,
                      onChanged: (value) {
                        setState(() {
                          aiAccuracySelection = value;
                        });
                      },
                    ),
                    const Gap(18),
                    ElevatedButton(
                      onPressed: _isSavingDraft ? null : _saveDraftAndContinue,
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
                          if (_isSavingDraft)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(Icons.send),
                          const SizedBox(width: 10),
                          Text(
                            _isSavingDraft
                                ? "Saving Draft..."
                                : context.tr("tp_dispatch.finalize_send"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF172554).withOpacity(0.35)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cs.primary.withOpacity(0.18)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info,
                            color: isDark
                                ? Colors.lightBlueAccent
                                : const Color(0xFF2563EB),
                          ),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              context.tr("tp_dispatch.info"),
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
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

String _formatTaskDueText(dynamic value) {
  final raw = (value ?? "").toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == "null") return "TBD";

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;

  final yyyy = parsed.year.toString().padLeft(4, '0');
  final mm = parsed.month.toString().padLeft(2, '0');
  final dd = parsed.day.toString().padLeft(2, '0');
  return "$yyyy-$mm-$dd";
}

String _buildWoundSummary(Map<String, dynamic> nurse) {
  final loc =
      (nurse["location_detail"] ?? nurse["location_primary"] ?? "-").toString();
  final type = (nurse["wound_type"] ?? "-").toString();
  final w = nurse["size_width_cm"];
  final l = nurse["size_length_cm"];
  final depth = (nurse["depth_category"] ?? "-").toString();
  final slough = (nurse["bed_slough_pct"] ?? "-").toString();
  final nec = (nurse["bed_necrotic_pct"] ?? "-").toString();
  final peri = (nurse["periwound_status"] ?? "-").toString();
  return "Wound: $type • Location: $loc • Size: ${w ?? "-"} x ${l ?? "-"} cm • Depth: $depth • Slough: $slough% • Necrotic: $nec% • Periwound: $peri";
}

/* ---------------- small widgets ---------------- */

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
          Text(
            "9:41",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: fg,
            ),
          ),
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
    required this.title,
    required this.backLabel,
  });

  final bool isDark;
  final Color border;
  final VoidCallback onBack;
  final String title;
  final String backLabel;

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
              backLabel,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
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
    required this.casePrefix,
  });

  final bool isDark;
  final Color primary;
  final String name;
  final String caseId;
  final String conditionTag;
  final Color conditionBg;
  final Color conditionFg;
  final String conditionLabel;
  final String casePrefix;

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
              child: Icon(
                Icons.person,
                size: 52,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
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
              text: "$casePrefix $caseId",
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
  const _TinyTag({
    required this.text,
    required this.bg,
    required this.fg,
  });

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
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

class _PlanTextarea extends StatelessWidget {
  const _PlanTextarea({
    required this.controller,
    required this.isDark,
    required this.border,
  });

  final TextEditingController controller;
  final bool isDark;
  final Color border;

  @override
  Widget build(BuildContext context) {
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
          hintText: "Add treatment plan...",
        ),
      ),
    );
  }
}

class _EditableTaskCard extends StatelessWidget {
  const _EditableTaskCard({
    required this.isDark,
    required this.card,
    required this.border,
    required this.num,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeIcon,
    required this.controller,
    required this.dueText,
    required this.onPickDate,
    required this.onDelete,
  });

  final bool isDark;
  final Color card;
  final Color border;
  final String num;
  final String badgeText;
  final Color badgeColor;
  final IconData badgeIcon;
  final TextEditingController controller;
  final String dueText;
  final VoidCallback onPickDate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          )
        ],
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(isDark ? 0.18 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, size: 14, color: badgeColor),
                            const Gap(6),
                            Flexible(
                              child: Text(
                                badgeText,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(8),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const Gap(10),
                TextField(
                  controller: controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter task...",
                    isCollapsed: true,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const Gap(12),
                InkWell(
                  onTap: onPickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0B1220)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            "Due: $dueText",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          "Pick date",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
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

class _AiAccuracySection extends StatelessWidget {
  const _AiAccuracySection({
    required this.isDark,
    required this.selectedValue,
    required this.onChanged,
  });

  final bool isDark;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF273449) : const Color(0xFFE6EBF2),
        ),
      ),
      child: Column(
        children: [
          Text(
            "AI ACCURACY EVALUATION",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: "Accurate",
                  icon: Icons.check_circle,
                  active: selectedValue == "accurate",
                  activeColor: cs.primary,
                  isDark: isDark,
                  onTap: () => onChanged("accurate"),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _ChoiceCard(
                  label: "Needs Correction",
                  icon: Icons.report,
                  active: selectedValue == "needs_correction",
                  activeColor: const Color(0xFFF43F5E),
                  isDark: isDark,
                  onTap: () => onChanged("needs_correction"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
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
    final bg = active
        ? activeColor.withOpacity(isDark ? 0.18 : 0.10)
        : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC));
    final border = active
        ? activeColor
        : (isDark ? const Color(0xFF273449) : const Color(0xFFE6EBF2));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: active ? 1.6 : 1),
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
