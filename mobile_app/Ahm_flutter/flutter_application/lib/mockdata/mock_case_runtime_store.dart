import 'package:flutter/foundation.dart';
import 'package:flutter_application/mockdata/mock_doctor_response.dart';
import 'package:flutter_application/mockdata/mock_nurse_case.dart';

class MockCaseRuntimeStore extends ChangeNotifier {
  MockCaseRuntimeStore._internal() {
    final nurseCaseId = (mockCaseDetailResponse["case_id"] ?? "").toString();
    final doctorCaseId = (mockDoctorResponse["case_id"] ?? "").toString();

    _doctorResponseByCaseId = {
      if (doctorCaseId.isNotEmpty) doctorCaseId: Map<String, dynamic>.from(mockDoctorResponse),
    };

    _lastSendPayloadByCaseId = {};

    _caseStatusByCaseId = {
      if (nurseCaseId.isNotEmpty)
        nurseCaseId: ((mockCaseDetailResponse["meta"]?["workflow_status"] ??
                    mockCaseDetailResponse["case_summary"]?["status"] ??
                    "DOCTOR_REVIEW"))
                .toString(),
    };
  }

  static final MockCaseRuntimeStore instance =
      MockCaseRuntimeStore._internal();

  late Map<String, Map<String, dynamic>> _doctorResponseByCaseId;
  late Map<String, Map<String, dynamic>> _lastSendPayloadByCaseId;
  late Map<String, String> _caseStatusByCaseId;

  Map<String, dynamic>? getDoctorResponse(String caseId) {
    return _doctorResponseByCaseId[caseId];
  }

  Map<String, dynamic>? getLastSendPayload(String caseId) {
    return _lastSendPayloadByCaseId[caseId];
  }

  String getCaseStatus(String caseId) {
    return _caseStatusByCaseId[caseId] ?? "DOCTOR_REVIEW";
  }

  bool hasSentPayload(String caseId) {
    return _lastSendPayloadByCaseId.containsKey(caseId);
  }

  void saveDoctorResponse({
    required String caseId,
    required Map<String, dynamic> responseJson,
  }) {
    _lastSendPayloadByCaseId[caseId] = Map<String, dynamic>.from(responseJson);

    final writes =
        (responseJson["writes"] ?? <String, dynamic>{}) as Map<String, dynamic>;

    final woundCases =
        (writes["wound_cases"] ?? <String, dynamic>{}) as Map<String, dynamic>;

    final treatmentPlans =
        (writes["treatment_plans"] ?? <String, dynamic>{}) as Map<String, dynamic>;

    final planTasks =
        (writes["plan_tasks"] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

    final notificationTrigger =
        (responseJson["notification_trigger"] ?? <String, dynamic>{})
            as Map<String, dynamic>;

    final normalizedDoctorResponse = <String, dynamic>{
      "case_id": caseId,
      "doctor_draft": {
        "exists": true,
        "doctor_stage_selected":
            (responseJson["doctor_stage_selected"] ?? "WAGNER_2").toString(),
        "diagnosis_override":
            (responseJson["diagnosis_override"] ??
                    treatmentPlans["diagnosis_override"] ??
                    "")
                .toString(),
        "clinical_notes":
            (responseJson["clinical_notes"] ?? "").toString(),
        "reviewed_by":
            (woundCases["updated_by"] ??
                    treatmentPlans["created_by"] ??
                    "doctor_001")
                .toString(),
        "reviewed_at":
            (woundCases["doctor_review_at"] ??
                    treatmentPlans["sent_at"] ??
                    DateTime.now().toIso8601String())
                .toString(),
        "draft_status": "SENT",
      },
      "treatment_plan": {
        "plan_id": (treatmentPlans["plan_id"] ?? "PLAN-001").toString(),
        "case_id": (treatmentPlans["case_id"] ?? caseId).toString(),
        "plan_text": (treatmentPlans["plan_text"] ?? "").toString(),
        "followup_days": treatmentPlans["followup_days"] ?? 3,
        "status": (treatmentPlans["status"] ?? "SENT_TO_NURSE").toString(),
        "created_by": (treatmentPlans["created_by"] ?? "doctor_001").toString(),
        "created_at":
            (treatmentPlans["created_at"] ?? DateTime.now().toIso8601String())
                .toString(),
        "sent_at":
            (treatmentPlans["sent_at"] ?? DateTime.now().toIso8601String())
                .toString(),
        "doctor_signature_url":
            (treatmentPlans["doctor_signature_url"] ?? "").toString(),
        "plan_tasks": planTasks
            .map(
              (t) => {
                "task_id": (t["task_id"] ?? "").toString(),
                "task_text": (t["task_text"] ?? "").toString(),
                "status": (t["status"] ?? "PENDING").toString(),
                "due_date": (t["due_date"] ?? "").toString(),
              },
            )
            .toList(),
      },
      "meta": {
        "workflow_status":
            (woundCases["status"] ?? "TREATMENT_SENT").toString(),
        "notification_needed_for":
            (notificationTrigger["target"] ?? "nurse").toString(),
        "nurse_notification_type":
            (notificationTrigger["type"] ?? "TREATMENT_PLAN_READY").toString(),
        "last_action_by":
            (woundCases["updated_by"] ??
                    treatmentPlans["created_by"] ??
                    "doctor_001")
                .toString(),
        "last_action_at":
            (woundCases["plan_issued_at"] ??
                    treatmentPlans["sent_at"] ??
                    DateTime.now().toIso8601String())
                .toString(),
      },
    };

    _doctorResponseByCaseId[caseId] = normalizedDoctorResponse;

    _caseStatusByCaseId[caseId] =
        (woundCases["status"] ?? "TREATMENT_SENT").toString();

    notifyListeners();
  }

  void updateCaseStatus({
    required String caseId,
    required String status,
  }) {
    _caseStatusByCaseId[caseId] = status;
    notifyListeners();
  }

  void resetCase(String caseId) {
    final nurseCaseId = (mockCaseDetailResponse["case_id"] ?? "").toString();
    final doctorCaseId = (mockDoctorResponse["case_id"] ?? "").toString();

    if (caseId == doctorCaseId) {
      _doctorResponseByCaseId[caseId] =
          Map<String, dynamic>.from(mockDoctorResponse);
    } else {
      _doctorResponseByCaseId.remove(caseId);
    }

    _lastSendPayloadByCaseId.remove(caseId);

    if (caseId == nurseCaseId) {
      _caseStatusByCaseId[caseId] =
          ((mockCaseDetailResponse["meta"]?["workflow_status"] ??
                  mockCaseDetailResponse["case_summary"]?["status"] ??
                  "DOCTOR_REVIEW"))
              .toString();
    } else {
      _caseStatusByCaseId.remove(caseId);
    }

    notifyListeners();
  }

  void resetAll() {
    final nurseCaseId = (mockCaseDetailResponse["case_id"] ?? "").toString();
    final doctorCaseId = (mockDoctorResponse["case_id"] ?? "").toString();

    _doctorResponseByCaseId = {
      if (doctorCaseId.isNotEmpty)
        doctorCaseId: Map<String, dynamic>.from(mockDoctorResponse),
    };

    _lastSendPayloadByCaseId = {};

    _caseStatusByCaseId = {
      if (nurseCaseId.isNotEmpty)
        nurseCaseId: ((mockCaseDetailResponse["meta"]?["workflow_status"] ??
                    mockCaseDetailResponse["case_summary"]?["status"] ??
                    "DOCTOR_REVIEW"))
                .toString(),
    };

    notifyListeners();
  }
}