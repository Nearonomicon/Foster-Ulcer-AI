import 'package:flutter_application/core/network/api_client.dart';
import 'package:flutter_application/mockdata/mock_case_runtime_store.dart';

class TreatmentPlanService {
  final ApiClient apiClient;
  final bool useMock;

  TreatmentPlanService({
    required this.apiClient,
    this.useMock = true,
  });

  Future<Map<String, dynamic>> saveTreatmentPlanDraft({
    required String caseId,
    required String planText,
    required int followupDays,
    required String createdBy,
    required List<Map<String, dynamic>> tasks,
  }) async {
    final body = <String, dynamic>{
      'case_id': caseId,
      'plan_text': planText,
      'followup_days': followupDays,
      'created_by': createdBy,
      'tasks': tasks.map((task) {
        return {
          'task_text': (task['task_text'] ?? '').toString(),
          'due_date': task['due_date'],
          'status': (task['status'] ?? 'DRAFT').toString(),
          'source': (task['source'] ?? 'doctor').toString(),
        };
      }).toList(),
    };

    if (useMock) {
      final now = DateTime.now().toIso8601String();
      const planId = 'PLAN-001';

      final response = {
        'request_id': 'mock_save_plan_$caseId',
        'timestamp': now,
        'success': true,
        'message': 'Treatment plan draft saved',
        'data': {
          'plan_id': planId,
          'case_id': caseId,
          'status': 'DRAFT',
        },
        'meta': {
          'version': 'v1',
          'pagination': null,
        },
        'error': null,
      };

      MockCaseRuntimeStore.instance.saveDoctorResponse(
        caseId: caseId,
        responseJson: {
          'case_id': caseId,
          'treatment_plan_draft': body,
        },
      );

      return response;
    }

    return apiClient.post(
      '/api/v1/plans',
      body: body,
      withAuth: true,
    );
  }

  Future<Map<String, dynamic>> sendTreatmentPlan({
    required String caseId,
    required String planId,
    required String signatureBase64,
    required String sentBy,
    required List<Map<String, dynamic>> tasks,
    required String planText,
  }) async {
    final body = <String, dynamic>{
      'case_id': caseId,
      'plan_id': planId,
      'signature_base64': signatureBase64,
      'sent_by': sentBy,
      'plan_text': planText,
      'tasks': tasks.map((task) {
        return {
          'task_text': (task['task_text'] ?? '').toString(),
          'due_date': task['due_date'],
          'status': (task['status'] ?? 'PENDING').toString(),
          'source': (task['source'] ?? 'doctor').toString(),
        };
      }).toList(),
    };

    if (useMock) {
      final response = {
        'request_id': 'mock_send_plan_$caseId',
        'timestamp': DateTime.now().toIso8601String(),
        'success': true,
        'message': 'Treatment plan sent',
        'data': {
          'case_id': caseId,
          'plan_id': planId,
          'status': 'TREATMENT_SENT',
        },
        'meta': {
          'version': 'v1',
          'pagination': null,
        },
        'error': null,
      };

      MockCaseRuntimeStore.instance.saveDoctorResponse(
        caseId: caseId,
        responseJson: {
          'case_id': caseId,
          'sent_plan': body,
        },
      );

      return response;
    }

    return apiClient.post(
      '/api/v1/plans/$planId/send',
      body: body,
      withAuth: true,
    );
  }
}