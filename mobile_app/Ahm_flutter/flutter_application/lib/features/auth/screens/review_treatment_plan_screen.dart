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

  const ReviewTreatmentPlanScreen({
    super.key,
    required this.caseId,
    required this.planId,
    required this.planText,
    required this.tasks,
  });

  @override
  State<ReviewTreatmentPlanScreen> createState() =>
      _ReviewTreatmentPlanScreenState();
}

class _ReviewTreatmentPlanScreenState extends State<ReviewTreatmentPlanScreen> {
  late final SignatureController _sigCtrl;

  final CaseService _caseService = CaseService();

  bool _isLoading = true;
  bool _isSending = false;

  String? _error;

  Map<String, dynamic>? _caseResponse;

  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();

    _sigCtrl = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    _loadData();
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

  Future<void> _loadData() async {
    try {
      final res = await _caseService.getCaseDetail(widget.caseId);

      final caseMap = _asMap(res["case"]);

      final plan = _asMap(caseMap["current_treatment_plan"]);

      final tasks = (plan["plan_tasks"] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];

      setState(() {
        _caseResponse = res;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

      final res = await _caseService.sendTreatmentPlan(
        planId: widget.planId,
        sentBy: "USR-DOCTOR-001",
        signatureBytes: signature,
      );

      final message =
          (res["message"] ?? "Treatment plan sent successfully").toString();

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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Review Treatment Plan")),
        body: Center(child: Text(_error!)),
      );
    }

    final caseMap = _asMap(_caseResponse!["case"]);

    final ai = _asMap(caseMap["current_analysis"]);

    final confidence =
        (ai["confidence"] is num) ? (ai["confidence"] as num).toDouble() : 0.0;

    final diagnosis = _safeStr(ai["diagnosis"]);

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
                itemCount: _tasks.length,
                itemBuilder: (context, i) {
                  final t = _tasks[i];

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