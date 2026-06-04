import 'package:flutter_application/core/network/api_client.dart';
import 'package:flutter_application/mockdata/mock_case_runtime_store.dart';
import 'package:flutter_application/mockdata/mock_doctor_response.dart';
import 'package:flutter_application/mockdata/mock_nurse_case.dart';

class DoctorReviewService {
  final ApiClient apiClient;
  final bool useMock;

  DoctorReviewService({
    required this.apiClient,
    this.useMock = true,
  });

  Future<Map<String, dynamic>> getDoctorReview(String caseId) async {
    if (useMock) {
      final saved = MockCaseRuntimeStore.instance.getDoctorResponse(caseId);
      if (saved != null) return saved;

      if ((mockDoctorResponse['case_id'] ?? '').toString() == caseId) {
        return mockDoctorResponse;
      }

      throw Exception('Doctor review not found: $caseId');
    }

    return apiClient.get(
      '/api/v1/cases/$caseId/doctor-review',
      withAuth: true,
    );
  }

  Future<Map<String, dynamic>> saveDoctorReview({
    required String caseId,
    required String imageId,
    required bool isLatestEditable,
    required String woundStage,
    required String diagnosisOverride,
    required String clinicalDescription,
    required String proposedTreatmentPlan,
    required String healingProgress,
    required bool aiAccurate,
    required String reviewedBy,
    String? reviewedAt,
  }) async {
    final body = <String, dynamic>{
      'image_id': imageId,
      'is_latest_editable': isLatestEditable,
      'doctor_review': {
        'wound_stage': woundStage,
        'diagnosis_override': diagnosisOverride,
        'clinical_description': clinicalDescription,
        'proposed_treatment_plan': proposedTreatmentPlan,
        'healing_progress': healingProgress,
        'ai_accurate': aiAccurate,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt ?? DateTime.now().toIso8601String(),
      },
    };

    if (useMock) {
      final response = {
        'case_id': caseId,
        'doctor_draft': {
          'image_id': imageId,
          'is_latest_editable': isLatestEditable,
          'wound_stage': woundStage,
          'diagnosis_override': diagnosisOverride,
          'clinical_notes': clinicalDescription,
          'proposed_treatment_plan': proposedTreatmentPlan,
          'healing_progress': healingProgress,
          'ai_accurate': aiAccurate,
          'reviewed_by': reviewedBy,
          'reviewed_at':
              reviewedAt ?? DateTime.now().toIso8601String(),
        },
        'raw_request': body,
      };

      MockCaseRuntimeStore.instance.saveDoctorResponse(
        caseId: caseId,
        responseJson: response,
      );

      return {
        'request_id': 'mock_save_doctor_review_$caseId',
        'timestamp': DateTime.now().toIso8601String(),
        'success': true,
        'message': 'Doctor review saved',
        'data': {
          'case_id': caseId,
          'image_id': imageId,
          'review_status': 'DRAFT_SAVED',
        },
        'meta': {
          'version': 'v1',
          'pagination': null,
        },
        'error': null,
      };
    }

    return apiClient.post(
      '/api/v1/cases/$caseId/doctor-review',
      body: body,
      withAuth: true,
    );
  }

  Future<Map<String, dynamic>> buildSavePayloadFromCaseBundle({
    required String caseId,
    required int selectedTimelineIndex,
    required String woundStage,
    required String diagnosisOverride,
    required String clinicalDescription,
    required String proposedTreatmentPlan,
    required String healingProgress,
    required bool aiAccurate,
    required String reviewedBy,
  }) async {
    final data =
        (mockCaseDetailResponse['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final caseBundle =
        (data['case_bundle'] ?? <String, dynamic>{}) as Map<String, dynamic>;

    final images =
        (caseBundle['wound_images'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final safeIndex = images.isEmpty
        ? 0
        : (selectedTimelineIndex >= 0 && selectedTimelineIndex < images.length)
            ? selectedTimelineIndex
            : 0;

    final selectedImage =
        images.isNotEmpty ? images[safeIndex] : <String, dynamic>{};

    final permissions =
        (caseBundle['permissions'] ?? <String, dynamic>{}) as Map<String, dynamic>;

    final imageId = (selectedImage['image_id'] ?? '').toString();
    final latestImageId = (permissions['latest_image_id'] ?? '').toString();
    final isLatestEditable =
        selectedImage['is_latest'] == true || imageId == latestImageId;

    return saveDoctorReview(
      caseId: caseId,
      imageId: imageId,
      isLatestEditable: isLatestEditable,
      woundStage: woundStage,
      diagnosisOverride: diagnosisOverride,
      clinicalDescription: clinicalDescription,
      proposedTreatmentPlan: proposedTreatmentPlan,
      healingProgress: healingProgress,
      aiAccurate: aiAccurate,
      reviewedBy: reviewedBy,
    );
  }
}