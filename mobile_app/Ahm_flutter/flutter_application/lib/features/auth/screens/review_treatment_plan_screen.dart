import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:signature/signature.dart';

import 'package:flutter_application/shared/app_localizations.dart';
import 'package:flutter_application/features/auth/services/case_service.dart';
import 'package:flutter_application/features/auth/screens/case_inbox_screen.dart';

class ReviewTreatmentPlanScreen extends StatefulWidget {
  final String caseId;
  final String planId;
  final String planText;
  final List<Map<String, dynamic>> tasks;
  final int followupDays;
  final double aiConfidence;
  final String diagnosis;
  final Map<String, dynamic>? doctorReviewDraft;
  final bool aiResultEditFlag;
  final bool treatmentPlanEditFlag;

  const ReviewTreatmentPlanScreen({
    super.key,
    required this.caseId,
    required this.planId,
    required this.planText,
    required this.tasks,
    required this.followupDays,
    required this.aiConfidence,
    required this.diagnosis,
    this.doctorReviewDraft,
    this.aiResultEditFlag = false,
    this.treatmentPlanEditFlag = false,
  });

  @override
  State<ReviewTreatmentPlanScreen> createState() =>
      _ReviewTreatmentPlanScreenState();
}

class _ReviewTreatmentPlanScreenState extends State<ReviewTreatmentPlanScreen> {
  late final SignatureController _sigCtrl;

  final CaseService _caseService = CaseService();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _sigCtrl = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _sigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  String _safeStr(dynamic v) => v == null ? "-" : v.toString();

  String _formatDue(String? iso) {
    if (iso == null || iso.isEmpty) return "-";

    try {
      final dt = DateTime.parse(iso);
      return "${dt.year}-${dt.month}-${dt.day}";
    } catch (_) {
      return iso;
    }
  }

  Future<void> _sendPlan() async {
    if (_sigCtrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign before sending")),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final Uint8List? signature = await _sigCtrl.toPngBytes();

      if (signature == null) {
        throw Exception("Signature export failed");
      }

      if (widget.doctorReviewDraft != null) {
        final payload = Map<String, dynamic>.from(widget.doctorReviewDraft!);
        final payloadBody = _asMap(payload["payload"]);
        final aiAnalysis = _asMap(payloadBody["AI_analysis"]);
        final signatureBase64 = base64Encode(signature);
        payload["status"] = "SENT";
        payload["source"] = "Doctor";
        payload["created_at"] = DateTime.now().toUtc().toIso8601String();
        payload["signature_base64"] = "data:image/png;base64,$signatureBase64";
        payload["payload"] = {
          ...payloadBody,
          "analysis": aiAnalysis,
          "treatment_plan": {
            "plan_text": widget.planText,
            "followup_days": widget.followupDays,
            "status": "SENT",
            "plan_tasks": widget.tasks
                .map(
                  (task) => {
                    "task_text": (task["task_text"] ?? "").toString(),
                    "status": (task["status"] ?? "DRAFT").toString(),
                    "task_due": task["task_due"],
                  },
                )
                .toList(),
          },
          "ai_result_edit_flag": widget.aiResultEditFlag,
          "treatment_plan_edit_flag": widget.treatmentPlanEditFlag,
        };
        await _caseService.submitDoctorReview(payload: payload);
      }

      final message = "Doctor review sent successfully";

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CaseInboxScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Send plan failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confidence = widget.aiConfidence;
    final diagnosis = _safeStr(widget.diagnosis);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Treatment Plan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "AI Confidence ${(confidence * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Gap(10),

            LinearProgressIndicator(value: confidence),

            const Gap(20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Diagnosis",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const Gap(6),

            Text(diagnosis),

            const Gap(20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Plan Notes",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const Gap(6),

            Text(widget.planText),

            const Gap(20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Tasks",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const Gap(10),

            Expanded(
              child: ListView.builder(
                itemCount: widget.tasks.length,
                itemBuilder: (context, i) {
                  final t = widget.tasks[i];

                  final due = t["task_due"] ?? t["due_date"];

                  return ListTile(
                    leading: const Icon(Icons.task_alt),
                    title: Text(_safeStr(t["task_text"])),
                    subtitle: Text(
                        "Status: ${_safeStr(t["status"])} • Due: ${_formatDue(due)}"),
                  );
                },
              ),
            ),

            const Gap(20),

            Container(
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Signature(
                controller: _sigCtrl,
                backgroundColor: Colors.white,
              ),
            ),

            const Gap(10),

            TextButton(
              onPressed: () => _sigCtrl.clear(),
              child: const Text("Clear Signature"),
            ),

            const Gap(10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendPlan,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? "Sending..." : "Send Treatment Plan"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
