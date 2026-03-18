import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CaseService {
  static const String _baseUrl =
      'https://foster-ulcer-ai-backend-429230748709.asia-southeast3.run.app';
  static const String _apiBaseUrl = '$_baseUrl/api/v1';

  Future<Map<String, dynamic>> getCasesByStatus(String status) async {
    final uri = Uri.parse('$_baseUrl/cases_list');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load cases (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Invalid response format for cases_list');
    }

    final decodedMap = Map<String, dynamic>.from(decoded);
    final rawCases = (decodedMap['cases'] as List?) ?? <dynamic>[];

    final mappedItems = rawCases
        .where((e) => e is Map)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(_mapCaseListItem)
        .where((e) => (e['status'] ?? '').toString() == status)
        .toList();

    return {
      'success': true,
      'data': {
        'items': mappedItems,
      }
    };
  }

  Future<Map<String, dynamic>> getCaseDetail(String caseId) async {
    final uri = Uri.parse('$_baseUrl/case_detail');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'case_id': caseId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load case detail (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Invalid response format for case_detail');
    }

    return _mapCaseDetailResponse(Map<String, dynamic>.from(decoded));
  }

  Future<Map<String, dynamic>> saveDoctorReview({
    required String caseId,
    required String imageId,
    required bool isLatestEditable,
    required Map<String, dynamic> doctorReview,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/cases/$caseId/doctor-review');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image_id': imageId,
        'is_latest_editable': isLatestEditable,
        'doctor_review': doctorReview,
      }),
    );

    return _decodeStandardResponse(
      response,
      fallbackErrorPrefix: 'Failed to save doctor review',
    );
  }

  Future<Map<String, dynamic>> saveTreatmentPlanDraft({
    required String caseId,
    required String doctorId,
    required String planText,
    required int followupDays,
    required List<Map<String, dynamic>> tasks,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/plans');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'case_id': caseId,
        'doctor_id': doctorId,
        'plan_text': planText,
        'followup_days': followupDays,
        'tasks': tasks,
      }),
    );

    return _decodeStandardResponse(
      response,
      fallbackErrorPrefix: 'Failed to save plan draft',
    );
  }

  Future<Map<String, dynamic>> sendTreatmentPlan({
    required String planId,
    required String sentBy,
    required Uint8List signatureBytes,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/plans/$planId/send');
    final signatureBase64 = base64Encode(signatureBytes);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'signature_base64': 'data:image/png;base64,$signatureBase64',
        'sent_by': sentBy,
      }),
    );

    return _decodeStandardResponse(
      response,
      fallbackErrorPrefix: 'Failed to send treatment plan',
    );
  }

  Map<String, dynamic> _mapCaseListItem(Map<String, dynamic> raw) {
    final analysis = _asStringDynamicMap(raw['current_analysis']);
    final classifications = _asStringDynamicMap(analysis['classifications']);
    final sinbad = _asStringDynamicMap(classifications['SINBAD']);

    final wound = _asStringDynamicMap(raw['current_wound_detail']);
    final size = _asStringDynamicMap(wound['size']);

    final timestamps = _asStringDynamicMap(raw['current_timestamps']);

    final patientName = _guessPatientNameFromCase(raw);
    final status = (raw['status'] ?? '').toString();
    final urgency = _mapUrgencyValue((raw['urgency'] ?? '').toString());

    final aiConfidence = (analysis['confidence'] is num)
        ? (analysis['confidence'] as num).toDouble()
        : 0.0;

    final aiStage = _mapDepthToStage(
      (wound['depth_category'] ?? '').toString(),
    );

    final imageUrl = _extractImageUrl(raw['current_image']);
    final imageCount = imageUrl.isEmpty ? 0 : 1;

    final createdAt = (timestamps['created_at'] ?? raw['case_created_at'] ?? '')
        .toString();

    return {
      'case_id': (raw['case_id'] ?? '').toString(),
      'patient_name': patientName,
      'urgency': urgency,
      'status': _mapBackendStatusToUiStatus(status),
      'ai_stage': aiStage,
      'ai_confidence': aiConfidence,
      'image_count': imageCount,
      'time_elapsed_text': _timeAgoText(createdAt),
      'record_id': (raw['current_record_id'] ?? '').toString(),
      'patient_id': (raw['patient_id'] ?? '').toString(),
      'sinbad_site': (sinbad['site'] ?? '').toString(),
      'wound_width_cm': size['width_cm'],
      'wound_length_cm': size['length_cm'],
    };
  }

  Map<String, dynamic> _mapCaseDetailResponse(Map<String, dynamic> raw) {
    final caseMap = _asStringDynamicMap(raw["case"]);
    final patient = _asStringDynamicMap(raw["patient_profile"]);
    final records = _asMapList(raw["records"]);

    final latestRecord = records.isNotEmpty
        ? Map<String, dynamic>.from(records.last)
        : <String, dynamic>{};

    final firstAnalyzedRecord = records.firstWhere(
      (e) => e["analysis"] != null,
      orElse: () => latestRecord,
    );

    final currentStatus =
        (caseMap["status"] ?? latestRecord["status"] ?? "UNKNOWN").toString();

    final currentUrgency =
        (caseMap["urgency"] ?? firstAnalyzedRecord["urgency"] ?? "ROUTINE")
            .toString();

    final analysis = _asStringDynamicMap(firstAnalyzedRecord["analysis"]);
    final classifications = _asStringDynamicMap(analysis["classifications"]);
    final wifi = _asStringDynamicMap(classifications["WIfI"]);
    final sinbad = _asStringDynamicMap(classifications["SINBAD"]);

    final currentWound = _asStringDynamicMap(caseMap["current_wound_detail"]);
    final currentBed = _asStringDynamicMap(currentWound["bed"]);
    final currentSize = _asStringDynamicMap(currentWound["size"]);
    final currentDischarge = _asStringDynamicMap(currentWound["discharge"]);

    final currentVitals = _asStringDynamicMap(caseMap["current_vital_signs"]);
    final currentLabs = _asStringDynamicMap(caseMap["current_lab_results"]);
    final currentVascular = _asStringDynamicMap(caseMap["current_vascular"]);
    final currentInfection = _asStringDynamicMap(caseMap["current_infection"]);
    final currentIschemia = _asStringDynamicMap(caseMap["current_ischemia"]);
    final currentNeuropathy = _asStringDynamicMap(caseMap["current_neuropathy"]);
    final currentSinbad = _asStringDynamicMap(caseMap["current_sinbad"]);
    final currentPlan = _asStringDynamicMap(caseMap["current_treatment_plan"]);

    final currentPlanTasks = _asMapList(currentPlan["plan_tasks"]);
    final currentTaskList = _asMapList(caseMap["current_task_list"]);

    final woundImages = records.map((record) {
      final r = Map<String, dynamic>.from(record);
      final rWound = _asStringDynamicMap(r["wound_detail"]);
      final rBed = _asStringDynamicMap(rWound["bed"]);
      final rSize = _asStringDynamicMap(rWound["size"]);
      final rDischarge = _asStringDynamicMap(rWound["discharge"]);
      final rAnalysis =
          r["analysis"] != null ? _asStringDynamicMap(r["analysis"]) : null;

      final rVitalSigns = _asStringDynamicMap(r["vital_signs"]);
      final rSinbad = _asStringDynamicMap(r["sinbad"]);
      final rIschemia = _asStringDynamicMap(r["ischemia"]);
      final rVascular = _asStringDynamicMap(r["vascular"]);
      final rInfection = _asStringDynamicMap(r["infection"]);
      final rNeuropathy = _asStringDynamicMap(r["neuropathy"]);
      final rLabResults = _asStringDynamicMap(r["lab_results"]);
      final rImage = _asStringDynamicMap(r["image"]);
      final rTreatmentPlan = _asStringDynamicMap(r["treatment_plan"]);
      final rPlanTasks = _asMapList(rTreatmentPlan["plan_tasks"]);

      final rClassifications = rAnalysis != null
          ? _asStringDynamicMap(rAnalysis["classifications"])
          : <String, dynamic>{};
      final rWifi = _asStringDynamicMap(rClassifications["WIfI"]);
      final rSinbadClassification =
          _asStringDynamicMap(rClassifications["SINBAD"]);

      final resolvedImageUrl =
          _extractImageUrl(r["image"]).isNotEmpty ? _extractImageUrl(r["image"]) : _extractImageUrl(r);

      return {
        "image_id":
            (rImage["image_id"] ?? r["image_id"] ?? r["record_id"] ?? "")
                .toString(),
        "image_url": resolvedImageUrl,
        "visit_day_label": (r["record_id"] ?? "Visit").toString(),
        "is_latest": (r["record_id"]?.toString() ==
            (latestRecord["record_id"] ?? "").toString()),
        "nurse_note": (r["healing_progress"] ?? "").toString(),
        "wound_snapshot": {
          "wound_type": (rWound["wound_type"] ?? "").toString(),
          "location_primary": (rWound["location_primary"] ?? "").toString(),
          "location_detail": (rWound["location_detail"] ?? "").toString(),
          "size_width_cm": rSize["width_cm"],
          "size_length_cm": rSize["length_cm"],
          "depth_category": (rWound["depth_category"] ?? "").toString(),
          "bed_slough_pct": rBed["slough_pct"],
          "bed_necrotic_pct": rBed["necrotic_pct"],
          "periwound_status": (rWound["periwound_status"] ?? "").toString(),
          "shape": (rWound["shape"] ?? "").toString(),
          "edge_description": (rWound["edge_description"] ?? "").toString(),
          "discharge_volume": (rDischarge["volume"] ?? "").toString(),
          "discharge_type": (rDischarge["type"] ?? "").toString(),
          "odor_presence": (rWound["odor_presence"] ?? "").toString(),
          "pain_score": rWound["pain_score"],
          "has_infection": rWound["has_infection"],
          "skin_condition": (rWound["skin_condition"] ?? "").toString(),
          "blood_pressure": rVitalSigns["blood_pressure"],
          "heart_rate": rVitalSigns["heart_rate"],
          "respiratory_rate": rVitalSigns["respiratory_rate"],
          "temperature": rVitalSigns["temperature"],
          "blood_glucose_mg_dl": rVitalSigns["blood_glucose"],
          "sinbad_site": rSinbad["site"],
          "sinbad_depth": rSinbad["depth"],
          "sinbad_infection": rSinbad["infection"],
          "sinbad_neuropathy": rSinbad["neuropathy"],
          "sinbad_area": rSinbad["area"],
          "sinbad_ischemia": rSinbad["ischemia"],
          "wifi_pulse_check": rIschemia["pulse"],
          "wifi_ischemia_points": rIschemia["points"] ?? [],
          "wifi_ischemia_checklist": rIschemia["checklist"] ?? [],
          "wifi_abi": rVascular["abi_value"],
          "wifi_ankle_pressure": rVascular["ankle_pressure_mmHg"],
          "wifi_toe_pressure": rVascular["toe_pressure_mmHg"],
          "wifi_tcpo2": rVascular["tcpo2_mmHg"],
          "wifi_gangrene_extent": r["gangrene_extent"],
          "idsa_infection_checklist": rInfection["checklist"] ?? [],
          "idsa_erythema_extent": rInfection["erythema_extent"],
          "idsa_probe_to_bone": rInfection["probe_to_bone_test"],
          "idsa_deep_abscess_fasciitis":
              rInfection["has_deep_abscess_or_fasciitis"],
          "neuropathy_points": rNeuropathy["points"] ?? [],
          "lab_wbc": rLabResults["wbc_count"],
          "lab_crp": rLabResults["crp"],
          "lab_esr": rLabResults["esr"],
          "lab_procalcitonin": rLabResults["procalcitonin"],
        },
        "ai_snapshot": rAnalysis == null
            ? {}
            : {
                "wound_stage": _mapDepthToStage(
                  (rWound["depth_category"] ?? "").toString(),
                ),
                "diagnosis": (rAnalysis["diagnosis"] ?? "").toString(),
                "description": (rAnalysis["description"] ?? "").toString(),
                "confidence": rAnalysis["confidence"],
                "treatment_suggestion":
                    (rAnalysis["treatment_plan"] ?? "").toString(),
                "red_flag": rAnalysis["red_flag"],
                "draft_status": (rTreatmentPlan["status"] ?? "READY").toString(),
                "idsa_stage": rClassifications["IDSA_infection_stage"],
                "wifi_wound": rWifi["wound_grade"],
                "wifi_ischemia": rWifi["ischemia_grade"],
                "wifi_foot_infection": rWifi["foot_infection_grade"],
                "wifi_stage": rWifi["clinical_stage"],
                "sinbad_total": rSinbadClassification["total"],
                "sinbad_site": rSinbadClassification["site"],
                "sinbad_ischemia": rSinbadClassification["ischemia"],
                "sinbad_neuropathy": rSinbadClassification["neuropathy"],
                "sinbad_infection":
                    rSinbadClassification["bacterial_infection"],
                "sinbad_area": rSinbadClassification["area"],
                "sinbad_depth": rSinbadClassification["depth"],
              },
        "treatment_plan_snapshot": {
          "followup_days": rTreatmentPlan["followup_days"],
          "plan_text": rTreatmentPlan["plan_text"],
          "status": rTreatmentPlan["status"],
          "plan_tasks": rPlanTasks,
        },
      };
    }).toList();

    final latestImageId = woundImages.isNotEmpty
        ? (woundImages.last["image_id"] ?? "").toString()
        : "";

    return {
      "success": true,
      "data": {
        "case_bundle": {
          "case_summary": {
            "case_id": (caseMap["case_id"] ?? "").toString(),
            "urgency": _mapUrgencyValue(currentUrgency),
            "status": _mapBackendStatusToUiStatus(currentStatus),
            "record_id": (caseMap["current_record_id"] ?? "").toString(),
            "patient_id": (caseMap["patient_id"] ?? "").toString(),
            "created_at": caseMap["case_created_at"],
            "updated_at": caseMap["case_updated_at"],
          },
          "patient_profile": {
            "patient_id": (patient["patient_id"] ?? "").toString(),
            "patient_name": (patient["patient_name"] ?? "").toString(),
            "dob": _normalizeDob((patient["dob"] ?? "").toString()),
            "gender": (patient["gender"] ?? "").toString(),
            "medical_history": _medicalHistoryList(patient),
            "comorbidities": _medicalHistoryList(patient),
            "diabetes_flag":
                (_asStringDynamicMap(patient["diabetes"])["has_diabetes"] ?? "")
                        .toString()
                        .toLowerCase() ==
                    "yes",
            "phone_no": patient["phone_no"],
            "nrc_id": patient["nrc_id"],
            "height_cm": patient["height_cm"],
            "weight_kg": patient["weight_kg"],
            "photo_url": patient["photo_url"],
            "status": patient["status"],
          },
          "nurse_reviewed": {
            "wound_type": (currentWound["wound_type"] ?? "").toString(),
            "location_primary": (currentWound["location_primary"] ?? "")
                .toString(),
            "location_detail": (currentWound["location_detail"] ?? "")
                .toString(),
            "size_width_cm": currentSize["width_cm"],
            "size_length_cm": currentSize["length_cm"],
            "depth_category": (currentWound["depth_category"] ?? "").toString(),
            "bed_slough_pct": currentBed["slough_pct"],
            "bed_necrotic_pct": currentBed["necrotic_pct"],
            "periwound_status": (currentWound["periwound_status"] ?? "")
                .toString(),
            "shape": (currentWound["shape"] ?? "").toString(),
            "edge_description": (currentWound["edge_description"] ?? "")
                .toString(),
            "discharge_volume": (currentDischarge["volume"] ?? "").toString(),
            "discharge_type": (currentDischarge["type"] ?? "").toString(),
            "odor_presence": (currentWound["odor_presence"] ?? "").toString(),
            "pain_score": currentWound["pain_score"],
            "has_infection": currentWound["has_infection"],
            "skin_condition": (currentWound["skin_condition"] ?? "").toString(),
            "temperature": currentVitals["temperature"],
            "blood_pressure": currentVitals["blood_pressure"],
            "heart_rate": currentVitals["heart_rate"],
            "respiratory_rate": currentVitals["respiratory_rate"],
            "blood_glucose_mg_dl": currentVitals["blood_glucose"],
            "sinbad_site": currentSinbad["site"],
            "sinbad_depth": currentSinbad["depth"],
            "sinbad_infection": currentSinbad["infection"],
            "sinbad_neuropathy": currentSinbad["neuropathy"],
            "sinbad_area": currentSinbad["area"],
            "sinbad_ischemia": currentSinbad["ischemia"],
            "wifi_pulse_check": currentIschemia["pulse"],
            "wifi_ischemia_points": currentIschemia["points"] ?? [],
            "wifi_ischemia_checklist": currentIschemia["checklist"] ?? [],
            "wifi_abi": currentVascular["abi_value"],
            "wifi_ankle_pressure": currentVascular["ankle_pressure_mmHg"],
            "wifi_toe_pressure": currentVascular["toe_pressure_mmHg"],
            "wifi_tcpo2": currentVascular["tcpo2_mmHg"],
            "wifi_gangrene_extent": caseMap["current_gangrene_extent"],
            "idsa_infection_checklist": currentInfection["checklist"] ?? [],
            "idsa_erythema_extent": currentInfection["erythema_extent"],
            "idsa_probe_to_bone": currentInfection["probe_to_bone_test"],
            "idsa_deep_abscess_fasciitis":
                currentInfection["has_deep_abscess_or_fasciitis"],
            "neuropathy_points": currentNeuropathy["points"] ?? [],
            "lab_wbc": currentLabs["wbc_count"],
            "lab_crp": currentLabs["crp"],
            "lab_esr": currentLabs["esr"],
            "lab_procalcitonin": currentLabs["procalcitonin"],
          },
          "ai_analysis": {
            "wound_stage": _mapDepthToStage(
              (currentWound["depth_category"] ?? "").toString(),
            ),
            "diagnosis": (analysis["diagnosis"] ?? "").toString(),
            "description":
                (analysis["description"] ??
                        caseMap["current_healing_progress"] ??
                        "")
                    .toString(),
            "confidence": analysis["confidence"] ?? 0,
            "treatment_suggestion":
                (analysis["treatment_plan"] ?? currentPlan["plan_text"] ?? "")
                    .toString(),
            "red_flag": analysis["red_flag"],
            "draft_status": (currentPlan["status"] ?? "READY").toString(),
            "idsa_stage": classifications["IDSA_infection_stage"],
            "wifi_wound": wifi["wound_grade"],
            "wifi_ischemia": wifi["ischemia_grade"],
            "wifi_foot_infection": wifi["foot_infection_grade"],
            "wifi_stage": wifi["clinical_stage"],
            "sinbad_total": sinbad["total"],
            "sinbad_site": sinbad["site"],
            "sinbad_ischemia": sinbad["ischemia"],
            "sinbad_neuropathy": sinbad["neuropathy"],
            "sinbad_infection": sinbad["bacterial_infection"],
            "sinbad_area": sinbad["area"],
            "sinbad_depth": sinbad["depth"],
          },
          "current_treatment_plan": {
            "plan_id": (caseMap["current_plan_id"] ?? "").toString(),
            "followup_days": currentPlan["followup_days"] ?? 3,
            "plan_text": (currentPlan["plan_text"] ?? "").toString(),
            "status": (currentPlan["status"] ?? "DRAFT").toString(),
            "plan_tasks":
                currentPlanTasks.isNotEmpty ? currentPlanTasks : currentTaskList,
          },
          "wound_images": woundImages,
          "permissions": {
            "can_edit_ai_review": true,
            "latest_image_id": latestImageId,
          },
        },
      },
    };
  }

  String _mapBackendStatusToUiStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DOCTOR_REVIEW':
        return 'DOCTOR_REVIEW';
      case 'TREATMENT_SENT':
        return 'TREATMENT_SENT';
      case 'ANALYZING':
        return 'DOCTOR_REVIEW';
      case 'CREATION':
        return 'DOCTOR_REVIEW';
      default:
        return status;
    }
  }

  String _mapUrgencyValue(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'URGENT':
        return 'HIGH';
      case 'HIGH':
        return 'HIGH';
      case 'MEDIUM':
        return 'MEDIUM';
      case 'LOW':
        return 'ROUTINE';
      case '':
        return 'ROUTINE';
      default:
        return 'ROUTINE';
    }
  }

  String _mapDepthToStage(String depth) {
    switch (depth.toLowerCase()) {
      case 'superficial':
        return 'Stage 1';
      case 'partial_thickness':
        return 'Stage 2';
      case 'full_thickness':
        return 'Stage 3';
      case 'deep':
        return 'Stage 4';
      case 'skin_only':
        return 'Stage 1';
      default:
        return 'Stage -';
    }
  }

  String _normalizeDob(String dob) {
    if (dob.contains('/')) {
      final parts = dob.split('/');
      if (parts.length == 3) {
        final dd = parts[0].padLeft(2, '0');
        final mm = parts[1].padLeft(2, '0');
        final yyyy = parts[2];
        return '$yyyy-$mm-$dd';
      }
    }
    return dob;
  }

  List<String> _medicalHistoryList(Map<String, dynamic> patient) {
    final result = <String>[];

    final medicalHistory = (patient["medical_history"] ?? "").toString().trim();
    if (medicalHistory.isNotEmpty) {
      result.add(medicalHistory);
    }

    final diabetes = _asStringDynamicMap(patient["diabetes"]);
    final complications = (diabetes["complications"] as List?) ?? [];
    final riskHistory = (diabetes["risk_history"] as List?) ?? [];

    result.addAll(complications.map((e) => e.toString()));
    result.addAll(riskHistory.map((e) => e.toString()));

    return result.toSet().toList();
  }

  String _guessPatientNameFromCase(Map<String, dynamic> raw) {
    final caseId = (raw['case_id'] ?? '').toString();

    if (caseId == 'CS-260312-00002') {
      return 'TEST FULL FLOW (FOLLOWUP)';
    }
    if (caseId == 'CS-260311-00003') {
      return 'Patient ${caseId.substring(caseId.length - 4)}';
    }

    return 'Patient ${caseId.isEmpty ? '' : caseId.substring(caseId.length - 4)}';
  }

  Map<String, dynamic> _decodeStandardResponse(
    http.Response response, {
    required String fallbackErrorPrefix,
  }) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('$fallbackErrorPrefix: invalid response format');
    }

    final decodedMap = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$fallbackErrorPrefix (${response.statusCode}): ${decodedMap['message'] ?? decodedMap['detail'] ?? response.body}',
      );
    }

    final success = decodedMap['success'];
    final status = decodedMap['status']?.toString().toLowerCase();

    if (success == false || status == 'error' || status == 'failed') {
      throw Exception(
        decodedMap['message'] ?? decodedMap['detail'] ?? fallbackErrorPrefix,
      );
    }

    return decodedMap;
  }

  String _timeAgoText(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '-';

    final now = DateTime.now().toUtc();
    final diff = now.difference(dt.toUtc());

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  Map<String, dynamic> _asStringDynamicMap(dynamic value) {
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

  String _extractImageUrl(dynamic source) {
    final map = _asStringDynamicMap(source);

    final candidates = [
      map["image_url"],
      map["image_folder_url"],
      map["file_url"],
      map["url"],
      map["download_url"],
      map["signed_url"],
    ];

    for (final v in candidates) {
      final s = (v ?? "").toString().trim();
      if (s.isNotEmpty) return s;
    }

    return "";
  }
}