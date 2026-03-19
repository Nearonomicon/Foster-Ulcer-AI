import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tailwind_colors/flutter_tailwind_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:foster_ulcer_ai/models/mock_patients.dart';


part '../pages/dashboard_page.dart';
part '../pages/patient_search_page.dart';
part '../pages/intake_page.dart';
part '../pages/response_view_page.dart';
part '../pages/doctor_summary_page.dart';
part '../pages/task_detail_page.dart';
part '../pages/tasks_page.dart';
part '../pages/cases_page.dart';
part '../pages/case_detail_page.dart';
part '../pages/profile_page.dart';
part '../pages/camera_page.dart';
part '../pages/vital_check_page.dart';
part '../pages/assessment_page.dart';
part '../pages/healing_progress_page.dart';

const String kSinbadAreaSmall = "< 1 cm²";
const String kSinbadAreaLarge = ">= 1 cm²";


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _patientSearchCtrl.dispose();

    // patient profile controllers
    _patientNameCtrl.dispose();
    _nrcIdCtrl.dispose();
    _dobCtrl.dispose();
    _patientPhoneCtrl.dispose();
    _patientHeightCtrl.dispose();
    _patientWeightCtrl.dispose();
    _patientHistoryCtrl.dispose();
    _otherCompCtrl.dispose();
    _healingPageCtrl.dispose();

    super.dispose();
  }

  // Helper to get standard date/time format (YYYY-MM-DD HH:MM:SS)
  String _getFormattedTimestamp() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return "$year-$month-$day $hour:$minute:$second";
  }

  // Helper for Date Selection - Fixed DOB Logic
  Future<void> _selectDate() async {
    // Force unfocus to ensure keyboard doesn't pop up
    FocusScope.of(context).requestFocus(FocusNode());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D9488),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF0D9488)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  String _responseMode = 'fillin';
  final Map<String, TextEditingController> _controllers = {};
  TextEditingController _ctrl(String key, {String initial = ""}) {
    return _controllers.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  void _applyPrefillControllersFromReviewed() {
    const keys = [
      'temperature',
      'blood_pressure',
      'heart_rate',
      'location_detail',
      'wound_type',
      'size_width_cm',
      'size_length_cm',
      'bed_slough_pct',
      'bed_necrotic_pct',
      'lab_wbc_count',
      'lab_crp',
      'lab_esr',
      'lab_procalcitonin',
      'vascular_abi_value',
      'vascular_ankle_pressure_mmHg',
      'vascular_toe_pressure_mmHg',
      'vascular_tcpo2_mmHg',
    ];
    for (final k in keys) {
      final v = _reviewed[k];
      _ctrl(k).text = v == null ? '' : v.toString();
    }
  }

  String _currentStep = 'dashboard';
  String _previousStep = 'dashboard';
  int _previousTab = 0;
  String _taskDetailReturnStep = 'dashboard';
  int _taskDetailReturnTab = 0;
  final TextEditingController _patientSearchCtrl = TextEditingController();
  String _patientSearchQuery = "";
  final Map<String, dynamic> _patientProfile = {};
  bool _patientProfileSaved = false;
  bool _emergencyBypassProfile = false;
  bool _followUpFlow = false;

  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _nrcIdCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  String? _selectedGender;
  String? _selectedUrgency; 
  final TextEditingController _patientPhoneCtrl = TextEditingController();
  final TextEditingController _patientHeightCtrl = TextEditingController();
  final TextEditingController _patientWeightCtrl = TextEditingController();
  final TextEditingController _patientHistoryCtrl = TextEditingController();
  final TextEditingController _otherCompCtrl = TextEditingController();
  String? _hasDiabetes;
  String? _diabetesYears;
  final Set<String> _riskHistory = {};
  final Set<String> _complications = {};
  String? _bpLevel;
  String? _sugarLevel;
  String? _tempLevel;
  String? _heartRateLevel;
  String? _respRateLevel;
   int _activeTab = 0;
  String? _sinbadSite;
  String? _sinbadIschemia;
  String? _sinbadNeuropathy;
  String? _sinbadInfection;
  String? _sinbadArea;
  String? _sinbadDepth;
  int _sinbadScoreLast = 0;
  final Set<int> _neuropathyPoints = {};
  final Set<int> _ischemiaPoints = {};
  final Set<String> _ischemiaChecklist = {};
  String? _ischemiaPulse;
  final Set<String> _infectionChecklist = {};
  bool _fillinReviewed = false;
  bool _fillinExpanded = false;
  final Map<String, bool> _sinbadHelpExpanded = {};
  bool _showInflammatoryLabs = false;
  bool _showDeepInfectionIndicators = false;
  bool _showObjectiveIschemia = false;
  Map<String, dynamic>? _selectedPatient;
  bool _isAnalyzing = false;
  String _analysisTitle = "GEMINI CLOUD";
  String _analysisMessage = "Analyzing...";
  XFile? _capturedImage;
  Uint8List? _capturedImageBytes;
  final PageController _healingPageCtrl = PageController(viewportFraction: 0.88);
  int _healingIndex = 0;
  XFile? _patientPhoto;
  String? _patientPhotoUrl;
  String? _rawResponse;
  Map<String, dynamic>? _aiExtraction;
  Map<String, dynamic>? _aiWoundJson;
  String? _healingResponseText;
  String? _healingRawResponse;
  final Map<String, dynamic> _reviewed = {};
  final Map<String, dynamic> _caseRefs = {};
  void _clearVitalsInfo() {
    _reviewed.remove('temperature');
    _reviewed.remove('blood_pressure');
    _reviewed.remove('heart_rate');
    _reviewed.remove('respiratory_rate');
    _reviewed.remove('blood_sugar');
    _reviewed.remove('repiratory_rate');
    _bpLevel = null;
    _sugarLevel = null;
    _tempLevel = null;
    _heartRateLevel = null;
    _respRateLevel = null;
  }

  void _resetCaseInputs() {
    _reviewed.clear();
    _caseRefs.clear();
    _aiExtraction = null;
    _aiWoundJson = null;
    _healingResponseText = null;
    _capturedImage = null;
    _capturedImageBytes = null;
  }

  void _resetAssessmentInputs() {
    _sinbadSite = null;
    _sinbadIschemia = null;
    _sinbadNeuropathy = null;
    _sinbadInfection = null;
    _sinbadArea = null;
    _sinbadDepth = null;
    _sinbadScoreLast = 0;
    _neuropathyPoints.clear();
    _ischemiaPoints.clear();
    _ischemiaChecklist.clear();
    _ischemiaPulse = null;
    _infectionChecklist.clear();
    _fillinReviewed = false;
    _fillinExpanded = false;
    _sinbadHelpExpanded.clear();
    _showInflammatoryLabs = false;
    _showDeepInfectionIndicators = false;
    _showObjectiveIschemia = false;
  }
  List<Map<String, dynamic>> _caseItems = [];
  bool _casesLoading = false;
  String? _casesError;
  bool _casesFetchedOnce = false;
  String? _casesFilterPatientId;
  Map<String, dynamic>? _caseDetail;
  Map<String, dynamic>? _caseDetailPatientProfile;
  List<Map<String, dynamic>> _caseDetailRecords = [];
  bool _caseDetailLoading = false;
  String? _caseDetailError;
  int _caseDetailIndex = 0;
  String _caseDetailTab = 'specs';
  bool _caseDetailShowWoundDetails = false;
  final ScrollController _caseDetailTimelineCtrl = ScrollController();
  bool _tasksLoading = false;
  String? _tasksError;
  List<Map<String, dynamic>> _tasksItems = [];
  bool _tasksIsFlat = false;
  bool _tasksFetchedOnce = false;
  List<Map<String, dynamic>> _patientItems = [];
  bool _patientsLoading = false;
  String? _patientsError;
  bool _patientsFetchedOnce = false;
    // =========================
  // Task Detail (NEW)
  // =========================
  int? _selectedTaskPatientIndex;
  int? _selectedTaskIndex;
  String _tasksViewMode = 'plan';
  String _tasksStatusQuery = '';
  String _tasksSearchQuery = '';
  String _tasksTreatmentStatus = 'ALL';
  String _tasksTaskStatus = 'ALL';
  XFile? _taskEvidencePhotoTemp; // temp holder (optional)
  Map<String, dynamic>? _selectedTask;
  Map<String, dynamic>? _selectedTaskPatient;
  final Map<String, bool> _tasksExpandedByCase = {};
  final Map<String, bool> _taskDetailExpandedById = {};
  final Map<String, bool> _taskDetailSelectedById = {};

  Map<String, dynamic>? _getSelectedTask() {
    if (_selectedTask != null) return _selectedTask;
    if (_selectedTaskPatientIndex == null || _selectedTaskIndex == null) return null;
    final p = _patients[_selectedTaskPatientIndex!];
    final aiJson = p['ai_wound_json'];
    final plan = aiJson?['treatment_plan'];
    final tasks = plan?['plan_tasks'];
    if (tasks is! List) return null;
    if (_selectedTaskIndex! < 0 || _selectedTaskIndex! >= tasks.length) return null;
    return tasks[_selectedTaskIndex!] as Map<String, dynamic>;
  }

  Map<String, dynamic>? _getSelectedTaskPatient() {
    if (_selectedTaskPatient != null) return _selectedTaskPatient;
    if (_selectedTaskPatientIndex == null) return null;
    return _patients[_selectedTaskPatientIndex!];
  }

  Future<bool> _taskUpdateApi({
    required String caseId,
    String? planId,
    required List<Map<String, dynamic>> updates,
    List<File>? images,
  }) async {
    if (updates.isEmpty) return false;
    final req = http.MultipartRequest('POST', _taskUpdateUri);
    req.fields['case_id'] = caseId;
    if (planId != null && planId.isNotEmpty) {
      req.fields['plan_id'] = planId;
    }
    req.fields['updates'] = jsonEncode(updates);
    debugPrint("[REQUEST] POST /task_update fields=${req.fields} images=${images?.length ?? 0}");
    if (images != null) {
      for (final file in images) {
        if (!await file.exists()) continue;
        req.files.add(await http.MultipartFile.fromPath('images', file.path));
      }
    }
    try {
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        throw Exception("task_update failed (${resp.statusCode}): ${resp.body}");
      }
      return true;
    } catch (e) {
      debugPrint("task_update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Task update failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
      return false;
    }
  }

  Future<void> _pickTaskEvidencePhoto(ImageSource source, Map<String, dynamic> task, String caseId, {String? planId}) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 75);
      if (image == null) return;

      setState(() {
        _taskEvidencePhotoTemp = image;
        task['evidence_path'] = image.path; // local preview
        task['evidence_captured_at'] = _getFormattedTimestamp();
      });
    } catch (e) {
      debugPrint("Error picking task evidence: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to capture evidence: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _completeSelectedTask() async {
    final t = _getSelectedTask();
    final p = _getSelectedTaskPatient();
    if (t == null || p == null) return;
    final caseId = (p['case_id'] ?? '').toString();
    final planId = (p['plan_id'] ?? p['current_treatment']?['plan_id'])?.toString();
    if (caseId.isEmpty) return;

    final evidencePath = (t['evidence_path'] ?? '').toString();
    final evidenceUrl = (t['task_photo_url'] ?? '').toString();
    if (evidencePath.isEmpty && evidenceUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take an evidence photo before completing."), backgroundColor: Colors.orange),
      );
      return;
    }

    final taskId = (t['task_id'] ?? '').toString();
    if (taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing task_id for completion."), backgroundColor: Colors.orange),
      );
      return;
    }
    final completedAt = _getFormattedTimestamp();
    final updates = [
      {
        'task_id': taskId,
        'updates': {
          'status': "COMPLETED",
          'completed_at': completedAt,
        },
      }
    ];
    final images = evidencePath.isNotEmpty ? [File(evidencePath)] : null;
    final ok = await _taskUpdateApi(caseId: caseId, planId: planId, updates: updates, images: images);
    if (!ok) return;

    setState(() {
      t['status'] = "COMPLETED";
      t['completed_at'] = completedAt;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task marked as completed."), backgroundColor: Color(0xFF0D9488)),
    );
  }

  static const String _baseUrl = "http://10.0.2.2:8080";
  // static const String _baseUrl = "https://foster-ulcer-ai-backend-429230748709.asia-southeast3.run.app";
  final Uri _fillinUri = Uri.parse("$_baseUrl/analyze-fillin");
  final Uri _analyzeWoundUri = Uri.parse("$_baseUrl/analyze-wound");
  final Uri _analyzeHealingUri = Uri.parse("$_baseUrl/analyze-healing");
  final Uri _createPatientUri = Uri.parse("$_baseUrl/create-patient-profile");
  Uri _updatePatientUri(String id) => Uri.parse("$_baseUrl/patients/$id");
  final Uri _createCaseUri = Uri.parse("$_baseUrl/create-case");
  final Uri _updateCaseUri = Uri.parse("$_baseUrl/update_cases");
  final Uri _sendToDoctorUri = Uri.parse("$_baseUrl/send-to-doctor");
  final Uri _casesListUri = Uri.parse("$_baseUrl/cases_list");
  final Uri _tasksListUri = Uri.parse("$_baseUrl/tasks_list");
  final Uri _taskDetailUri = Uri.parse("$_baseUrl/task_detail");
  final Uri _taskUpdateUri = Uri.parse("$_baseUrl/task_update");
  final Uri _caseDetailUri = Uri.parse("$_baseUrl/case_detail");
  final Uri _patientListUri = Uri.parse("$_baseUrl/patients_list");
  final Uri _docsUri = Uri.parse("$_baseUrl/docs");

  // Mock Clinical Data with Wound Images
  final List<Map<String, dynamic>> _patients = buildMockPatients();

  Map<String, dynamic>? _parseAnalysis(dynamic analysisData) {
    if (analysisData == null) return null;
    if (analysisData is Map<String, dynamic>) return analysisData;
    if (analysisData is Map) return Map<String, dynamic>.from(analysisData);
    if (analysisData is String) {
      try {
        var s = analysisData.trim();
        s = s.replaceAll('```json', '').replaceAll('```', '').trim();
        final decoded = json.decode(s);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _coerceEnum(String? v, List<String> options) {
    if (v == null) return null;
    if (options.contains(v)) return v;
    final raw = v.toString().trim().toLowerCase();
    final normalized = raw.replaceAll(RegExp(r"\\s+"), "_").replaceAll('-', '_').replaceAll(RegExp(r"_+"), "_");
    for (final opt in options) {
      final o = opt.toLowerCase();
      if (o == raw || o == normalized) return opt;
    }
    return null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    return int.tryParse(v.toString());
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_patientProfileSaved && !_emergencyBypassProfile) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please save/select the patient profile first."), backgroundColor: Colors.redAccent),
        );
      }
      _navigateTo('patient_search');
      return;
    }
    if (_emergencyBypassProfile && !_patientProfileSaved) {
      setState(() => _patientProfileSaved = true);
    }
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImage = image;
          _capturedImageBytes = bytes;
        });
        await _uploadAndAnalyzeFillin(image);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Picker for patient profile photo
  Future<void> _pickPatientPhoto(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 60);
      if (image != null) {
        setState(() {
          _patientPhoto = image;
          _patientPhotoUrl = null;
        });
      }
    } catch (e) {
      debugPrint("Error picking patient photo: $e");
    }
  }

  Future<void> _uploadAndAnalyzeFillin(XFile imageFile) async {
    setState(() {
      _analysisTitle = "GEMINI CLOUD";
      _analysisMessage = "Analyzing...";
      _isAnalyzing = true;
    });
    try {
      if (_caseRefs['record_id'] == null || _caseRefs['case_id'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Missing case/record ID. Please complete Vital Check first."), backgroundColor: Colors.orange),
          );
        }
        return;
      }
      final request = http.MultipartRequest('POST', _fillinUri);
      final bytes = _capturedImageBytes ?? await imageFile.readAsBytes();
      request.fields['record_id'] = _caseRefs['record_id'].toString();
      request.fields['case_id'] = _caseRefs['case_id'].toString();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) throw Exception("Server Error ${response.statusCode}");
      final Map<String, dynamic> body = json.decode(response.body);
      if (body.containsKey('analysis')) {
        final analysisData = body['analysis'];
        final extracted = _parseAnalysis(analysisData);
        final preservedVitals = {
          'temperature': _reviewed['temperature'],
          'blood_pressure': _reviewed['blood_pressure'],
          'blood_sugar': _reviewed['blood_sugar'],
          'heart_rate': _reviewed['heart_rate'],
          'respiratory_rate': _reviewed['respiratory_rate'],
        };
        setState(() {
          _responseMode = 'fillin';
          _aiExtraction = extracted;
          _rawResponse = const JsonEncoder.withIndent('  ').convert(extracted ?? analysisData);
          _reviewed..clear()..addAll(extracted ?? {});
          _reviewed.remove('odor_presence');
          _reviewed.remove('pain_score');
          _reviewed.remove('has_infection');
          _reviewed.addAll(preservedVitals);
        });
        _applyPrefillControllersFromReviewed();
        _maybeComputeSinbadAreaFromSize();
      }
      _navigateTo('response_view');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submitToAnalyzeWound() async {
    if (_capturedImage == null) return;
    final imageFile = File(_capturedImage!.path);
    if (!_patientProfileSaved || _patientProfile.isEmpty) {
      _navigateTo('patient_search');
      return;
    }
    if (_caseRefs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing case reference. Please complete Vital Check first."), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    final missing = <String>[];
    if ((_reviewed['sinbad_site'] ?? _reviewed['location_primary']) == null) missing.add('SINBAD site/location');
    if ((_reviewed['sinbad_ischemia'] ?? _reviewed['ischemia_pulse']) == null) missing.add('Ischemia');
    if ((_reviewed['sinbad_neuropathy'] ?? _reviewed['neuropathy_points']) == null) missing.add('Neuropathy');
    if ((_reviewed['sinbad_infection'] ?? _reviewed['infection_checklist']) == null) missing.add('Infection signs');
    if (_reviewed['sinbad_area'] == null &&
        (_reviewed['size_width_cm'] == null || _reviewed['size_length_cm'] == null)) {
      missing.add('Wound size (width & length)');
    }
    if ((_reviewed['sinbad_depth'] ?? _reviewed['depth_category']) == null) missing.add('Depth');

    if (missing.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Missing required fields: ${missing.join(', ')}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() {
      _analysisTitle = "GEMINI CLOUD";
      _analysisMessage = "Analyzing...";
      _isAnalyzing = true;
    });
    try {
      final request = http.MultipartRequest('POST', _analyzeWoundUri);
      final reviewed = {
        'nurse_reviewed_flag': _fillinReviewed,
        'vital_signs': {
          'temperature': _reviewed['temperature'],
          'blood_pressure': _reviewed['blood_pressure'],
          'blood_glucose': _reviewed['blood_sugar'],
          'heart_rate': _reviewed['heart_rate'],
          'respiratory_rate': _reviewed['respiratory_rate'],
        },
        'wound_detail': {
          'location_primary': _reviewed['location_primary'],
          'location_detail': _reviewed['location_detail'],
          'wound_type': _reviewed['wound_type'],
          'shape': _reviewed['shape'],
          'size': {
            'width_cm': _toDouble(_reviewed['size_width_cm']),
            'length_cm': _toDouble(_reviewed['size_length_cm']),
          },
          'depth_category': _reviewed['depth_category'],
          'bed': {
            'slough_pct': _toInt(_reviewed['bed_slough_pct']),
            'necrotic_pct': _toInt(_reviewed['bed_necrotic_pct']),
          },
          'edge_description': _reviewed['edge_description'],
          'periwound_status': _reviewed['periwound_status'],
          'discharge': {
            'volume': _reviewed['discharge_volume'],
            'type': _reviewed['discharge_type'],
          },
          'odor_presence': _reviewed['odor_presence'],
          'pain_score': _toInt(_reviewed['pain_score']),
          'has_infection': _reviewed['has_infection']?.toString().toLowerCase() == 'true',
          'skin_condition': _reviewed['skin_condition'],
        },
        'ischemia': {
          'points': _reviewed['ischemia_points'] ?? [],
          'pulse': _reviewed['ischemia_pulse'],
          'checklist': _reviewed['ischemia_checklist'] ?? [],
        },
        'infection': {
          'checklist': _reviewed['infection_checklist'] ?? [],
          'erythema_extent': _reviewed['erythema_extent'],
          'probe_to_bone_test': _reviewed['probe_to_bone_test'],
          'has_deep_abscess_or_fasciitis': _reviewed['has_deep_abscess_or_fasciitis'],
        },
        'neuropathy': {
          'points': _reviewed['neuropathy_points'] ?? [],
        },
        'sinbad': {
          'site': _reviewed['sinbad_site'],
          'ischemia': _reviewed['sinbad_ischemia'],
          'neuropathy': _reviewed['sinbad_neuropathy'],
          'infection': _reviewed['sinbad_infection'],
          'area': _reviewed['sinbad_area'],
          'depth': _reviewed['sinbad_depth'],
        },
        'lab_results': {
          'wbc_count': _reviewed['lab_wbc_count'],
          'crp': _reviewed['lab_crp'],
          'esr': _reviewed['lab_esr'],
          'procalcitonin': _reviewed['lab_procalcitonin'],
        },
        'vascular': {
          'abi_value': _reviewed['vascular_abi_value'],
          'ankle_pressure_mmHg': _reviewed['vascular_ankle_pressure_mmHg'],
          'toe_pressure_mmHg': _reviewed['vascular_toe_pressure_mmHg'],
          'tcpo2_mmHg': _reviewed['vascular_tcpo2_mmHg'],
        },
        'gangrene_extent': _reviewed['gangrene_extent'],
      };
      final filteredProfile = Map<String, dynamic>.from(_patientProfile)
        ..remove('patient_name')
        ..remove('phone_no')
        ..remove('patient_photo_url')
        ..remove('patient_photo');
      final payload = {
        'patient_profile': filteredProfile,
        'nurse_reviewed': reviewed,
        'ai_prefill': _aiExtraction,
        'case_ref': _caseRefs.isEmpty ? null : Map<String, dynamic>.from(_caseRefs),
      };
      debugPrint("Analyze-wound payload: ${jsonEncode(payload)}");
      request.fields['payload_data'] = jsonEncode(payload);
      final bytes = _capturedImageBytes ?? await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: _capturedImage!.name));
      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) throw Exception("Server Error");
      final Map<String, dynamic> body = jsonDecode(response.body);
      final followUpFlowEnabled = _followUpFlow;
      final followUpCaseId = _caseRefs['case_id']?.toString();
      debugPrint(
        "Follow-up gate before analyze-healing: "
        "_followUpFlow=$followUpFlowEnabled, "
        "case_id=${followUpCaseId ?? 'null'}, "
        "caseRefs=${jsonEncode(_caseRefs)}",
      );
      if (body['status'] == 'success' && body.containsKey('analysis')) {
        final analysisVal = body['analysis'];
        final parsed = _parseAnalysis(analysisVal);
        debugPrint(
          "Analyze-wound success: parsed=${parsed != null}, "
          "hasAIAnalysis=${parsed?.containsKey('AI_analysis') == true}, "
          "hasTreatmentPlan=${parsed?.containsKey('treatment_plan') == true}",
        );
        if (parsed != null && (parsed.containsKey('AI_analysis') || parsed.containsKey('treatment_plan'))) {
          if (!parsed.containsKey('treatment_plan')) {
            final ai = parsed['AI_analysis'];
            if (ai is Map && ai['treatment_plan'] != null) {
              parsed['treatment_plan'] = ai['treatment_plan'];
            }
          }
          setState(() {
            _aiWoundJson = parsed;
            _selectedUrgency = null; 
          });
          if (_followUpFlow) {
            try {
              final caseId = _caseRefs['case_id']?.toString();
              debugPrint(
                "Follow-up flow enabled. Preparing /analyze-healing with case_id=${caseId ?? 'null'}",
              );
              if (caseId != null && caseId.isNotEmpty) {
                final resp = await http
                    .post(
                      _analyzeHealingUri,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'case_id': caseId}),
                    )
                    .timeout(const Duration(seconds: 30));
                if (resp.statusCode != 200) {
                  debugPrint("Analyze-healing failed (${resp.statusCode}): ${resp.body}");
                } else {
                  debugPrint("Analyze-healing success: ${resp.body}");
                  String? summary;
                  try {
                    final decoded = jsonDecode(resp.body);
                    if (decoded is Map<String, dynamic>) {
                      summary = decoded['analysis']?.toString() ??
                          decoded['summary']?.toString() ??
                          decoded['message']?.toString() ??
                          decoded['result']?.toString();
                    }
                  } catch (_) {
                    summary = null;
                  }
                  setState(() {
                    _healingRawResponse = resp.body;
                    _healingResponseText = (summary != null && summary.isNotEmpty) ? summary : resp.body;
                  });
                  _navigateTo('healing_progress');
                }
              } else {
                debugPrint("Skip /analyze-healing: _followUpFlow=true but case_id is missing.");
              }
            } catch (e) {
              debugPrint("Analyze-healing error: $e");
            }
          } else {
            debugPrint("Skip /analyze-healing: _followUpFlow=false.");
            _navigateTo('doctor_summary');
          }
          return;
        }
        debugPrint(
          "Skip /analyze-healing: analyze-wound response did not satisfy parsed AI gate.",
        );
        setState(() {
          _responseMode = 'analysis';
          _rawResponse = analysisVal?.toString();
          _aiExtraction = null;
          _aiWoundJson = null;
        });
        _navigateTo('response_view');
      }
    } catch (e) {
      debugPrint("Analyze-wound error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submit failed: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _sendToDoctor() async {
    if (_caseRefs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing case reference. Please complete Vital Check first."), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final urgencyMap = {
      'high_urgent': 'URGENT',
      'medium': 'MEDIUM',
      'routine': 'ROUTINE',
    };
    final urgency = _selectedUrgency == null ? null : urgencyMap[_selectedUrgency];

    final woundDetail = {
      'location_primary': _reviewed['location_primary'],
      'location_detail': _reviewed['location_detail'],
      'wound_type': _reviewed['wound_type'],
      'shape': _reviewed['shape'],
      'size': {
        'width_cm': _toDouble(_reviewed['size_width_cm']),
        'length_cm': _toDouble(_reviewed['size_length_cm']),
      },
      'depth_category': _reviewed['depth_category'],
      'bed': {
        'slough_pct': _toInt(_reviewed['bed_slough_pct']),
        'necrotic_pct': _toInt(_reviewed['bed_necrotic_pct']),
      },
      'edge_description': _reviewed['edge_description'],
      'periwound_status': _reviewed['periwound_status'],
      'discharge': {
        'volume': _reviewed['discharge_volume'],
        'type': _reviewed['discharge_type'],
      },
      'odor_presence': _reviewed['odor_presence'],
      'pain_score': _toInt(_reviewed['pain_score']),
      'has_infection': _reviewed['has_infection']?.toString().toLowerCase() == 'true',
      'skin_condition': _reviewed['skin_condition'],
    };

    final payload = {
      'record_id': _caseRefs['record_id'],
      'case_id': _caseRefs['case_id'],
      'patient_id': _caseRefs['patient_id'],
      'status': 'DOCTOR_REVIEW',
      'urgency': urgency,
      'vital_signs': {
        'temperature': _reviewed['temperature'],
        'blood_pressure': _reviewed['blood_pressure'],
        'blood_glucose': _reviewed['blood_sugar'],
        'heart_rate': _reviewed['heart_rate'],
        'respiratory_rate': _reviewed['respiratory_rate'],
      },
      'wound_detail': woundDetail,
      'ischemia': {
        'points': _reviewed['ischemia_points'] ?? [],
        'pulse': _reviewed['ischemia_pulse'],
        'checklist': _reviewed['ischemia_checklist'] ?? [],
      },
      'infection': {
        'checklist': _reviewed['infection_checklist'] ?? [],
        'erythema_extent': _reviewed['erythema_extent'],
        'probe_to_bone_test': _reviewed['probe_to_bone_test'],
        'has_deep_abscess_or_fasciitis': _reviewed['has_deep_abscess_or_fasciitis'],
      },
      'neuropathy': {
        'points': _reviewed['neuropathy_points'] ?? [],
      },
      'sinbad': {
        'site': _reviewed['sinbad_site'],
        'ischemia': _reviewed['sinbad_ischemia'],
        'neuropathy': _reviewed['sinbad_neuropathy'],
        'infection': _reviewed['sinbad_infection'],
        'area': _reviewed['sinbad_area'],
        'depth': _reviewed['sinbad_depth'],
      },
      'lab_results': {
        'wbc_count': _reviewed['lab_wbc_count'],
        'crp': _reviewed['lab_crp'],
        'esr': _reviewed['lab_esr'],
        'procalcitonin': _reviewed['lab_procalcitonin'],
      },
      'vascular': {
        'abi_value': _reviewed['vascular_abi_value'],
        'ankle_pressure_mmHg': _reviewed['vascular_ankle_pressure_mmHg'],
        'toe_pressure_mmHg': _reviewed['vascular_toe_pressure_mmHg'],
        'tcpo2_mmHg': _reviewed['vascular_tcpo2_mmHg'],
      },
      'gangrene_extent': _reviewed['gangrene_extent'],
      'analysis': _aiWoundJson?['AI_analysis'],
      'treatment_plan': _aiWoundJson?['treatment_plan'],
      'task_list': _aiWoundJson?['treatment_plan']?['plan_tasks'],
    };
    debugPrint("Send-to-doctor payload: ${jsonEncode(payload)}");

    debugPrint("Send-to-doctor payload: ${jsonEncode(payload)}");

    setState(() {
      _analysisTitle = "SENDING";
      _analysisMessage = "Sending to doctor...";
      _isAnalyzing = true;
    });
    try {
      final resp = await http
          .post(
            _sendToDoctorUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception("Send failed (${resp.statusCode}): ${resp.body}");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Clinical case successfully sent to doctor."), backgroundColor: Color(0xFF0D9488)),
      );
      setState(() {
        _responseMode = 'analysis';
        _rawResponse = resp.body;
      });
      _navigateTo('dashboard');
    } catch (e) {
      debugPrint("Send-to-doctor error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Send failed: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _savePatientProfile() async {
    final phone = _patientPhoneCtrl.text.trim();
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number is required."), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    if (_hasDiabetes == "Yes" && (_diabetesYears == null || _diabetesYears!.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select years of diabetes."), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    setState(() {
      _analysisTitle = "SAVING PROFILE";
      _analysisMessage = "Saving...";
      _isAnalyzing = true;
    });
    try {
      final payload = {
        'nrc_id': _nrcIdCtrl.text.trim(),
        'patient_name': _patientNameCtrl.text.trim(),
        'phone_no': phone,
        'dob': _dobCtrl.text, 
        'gender': _selectedGender,
        'height_cm': _patientHeightCtrl.text.trim(),
        'weight_kg': _patientWeightCtrl.text.trim(),
        'medical_history': _otherCompCtrl.text.trim(),
        'diabetes': {
          'has_diabetes': _hasDiabetes,
          'years': _diabetesYears,
          'risk_history': _riskHistory.toList()..sort(),
          'complications': _complications.toList()..sort(),
        },
        'created_at': _getFormattedTimestamp(),
      };
      debugPrint("Create patient payload: ${jsonEncode(payload)}");

      final existingId = _patientProfile['patient_id']?.toString();
      if (existingId != null && existingId.isNotEmpty) {
        final ok = await _updatePatientProfile(existingId, payload);
        if (ok) {
          if (_followUpFlow) {
            _navigateTo('patient_cases');
            _fetchCasesList(patientId: existingId);
          } else {
            _navigateTo('vital_check_page');
          }
        }
      } else {
        final req = http.MultipartRequest('POST', _createPatientUri);
        req.fields['patient_data'] = jsonEncode(payload);

        if (_patientPhoto != null) {
          final bytes = await _patientPhoto!.readAsBytes();
          req.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'patient_profile.png'));
        }

        final streamed = await req.send().timeout(const Duration(seconds: 30));
        final resp = await http.Response.fromStream(streamed);
        debugPrint("Create patient response: ${resp.statusCode} ${resp.body}");
        final decoded = jsonDecode(resp.body);
        if (decoded['status'] == 'success') {
          _patientProfile..clear()..addAll(payload);
          final backendId = decoded['patient_id'] ?? decoded['id'];
          if (backendId != null && backendId.toString().isNotEmpty) {
            _patientProfile['patient_id'] = backendId;
          }
          setState(() => _patientProfileSaved = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Patient profile and photo saved."), backgroundColor: Color(0xFF0D9488)),
            );
          }
          _navigateTo('vital_check_page');
        } else {
          throw Exception(decoded['detail'] ?? resp.body ?? "Registration failed.");
        }
      }
    } catch (e) {
      debugPrint("Create patient error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) {
        setState(() {
          _analysisTitle = "GEMINI CLOUD";
          _analysisMessage = "Analyzing...";
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<bool> _updatePatientProfile(String id, Map<String, dynamic> payload) async {
    try {
      debugPrint("Update patient payload: ${jsonEncode(payload)}");
      final resp = await http
          .patch(
            _updatePatientUri(id),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint("Update patient response: ${resp.statusCode} ${resp.body}");
      if (resp.statusCode != 200) {
        throw Exception("Update failed (${resp.statusCode}): ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is Map && decoded['status'] == 'success') {
        _patientProfile..clear()..addAll(payload);
        _patientProfile['patient_id'] = id;
        setState(() => _patientProfileSaved = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Patient profile updated."), backgroundColor: Color(0xFF0D9488)),
          );
        }
        return true;
      } else {
        throw Exception(decoded is Map ? (decoded['detail'] ?? "Update failed.") : "Update failed.");
      }
    } catch (e) {
      debugPrint("Update patient error: $e");
      return false;
    }
  }

  Future<void> _fetchCasesList({String? patientId, int limit = 50}) async {
    if (_casesLoading) return;
    setState(() {
      _casesLoading = true;
      _casesError = null;
      _casesFilterPatientId = patientId;
      _caseItems = [];
      _casesFetchedOnce = true;
    });
    try {
      final payload = {
        'limit': limit,
        if (patientId != null && patientId.isNotEmpty) 'patient_id': patientId,
      };
      final resp = await http
          .post(
            _casesListUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception("cases_list failed (${resp.statusCode}): ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      List<dynamic> raw;
      if (decoded is List) {
        raw = decoded;
      } else if (decoded is Map && decoded['cases'] is List) {
        raw = decoded['cases'] as List;
      } else {
        throw Exception("cases_list: unexpected response");
      }
      final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) {
        setState(() => _caseItems = items);
      }
    } catch (e) {
      debugPrint("cases_list error: $e");
      if (mounted) {
        setState(() => _casesError = "Failed to load cases: $e");
      }
    } finally {
      if (mounted) setState(() => _casesLoading = false);
    }
  }

  Future<void> _fetchTasksList() async {
    if (_tasksLoading) return;
    setState(() {
      _tasksLoading = true;
      _tasksError = null;
      _tasksItems = [];
      _tasksIsFlat = false;
      _tasksFetchedOnce = true;
    });
    try {
      final resp = await http
          .post(
            _tasksListUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'limit': 200}),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception("tasks_list failed (${resp.statusCode}): ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      List<Map<String, dynamic>> items = [];
      bool flat = false;
      if (decoded is Map && decoded['tasks'] is List) {
        items = List<Map<String, dynamic>>.from(decoded['tasks']);
        flat = false;
      } else if (decoded is Map && decoded['current_treatment_plan'] is List) {
        items = List<Map<String, dynamic>>.from(decoded['current_treatment_plan']);
        flat = false;
      } else {
        throw Exception("tasks_list: unexpected response");
      }
      setState(() {
        _tasksItems = items;
        _tasksIsFlat = flat;
      });
    } catch (e) {
      debugPrint("tasks_list error: $e");
      if (mounted) {
        setState(() => _tasksError = "Failed to load tasks: $e");
      }
    } finally {
      if (mounted) setState(() => _tasksLoading = false);
    }
  }

  Future<bool> _fetchTaskDetail({required String caseId, required int taskIndex}) async {
    try {
      final resp = await http
          .post(
            _taskDetailUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'case_id': caseId,
              'task_index': taskIndex,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception("task_detail failed (${resp.statusCode}): ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) {
        throw Exception("task_detail: unexpected response");
      }
      setState(() {
        _selectedTask = decoded['task'] is Map ? Map<String, dynamic>.from(decoded['task']) : null;
        final planTasks = decoded['plan_tasks'] is List
            ? List<Map<String, dynamic>>.from(decoded['plan_tasks'])
            : (decoded['current_treatment']?['plan_tasks'] is List
                ? List<Map<String, dynamic>>.from(decoded['current_treatment']['plan_tasks'])
                : <Map<String, dynamic>>[]);
        _selectedTaskPatient = {
          'case_id': (decoded['case_id'] ?? caseId).toString(),
          'patient_id': (decoded['patient_id'] ?? '').toString(),
          'patient_name': (decoded['patient_name'] ?? '').toString(),
          'plan_id': (decoded['current_treatment']?['plan_id'] ?? decoded['plan_id'] ?? '').toString(),
          'current_treatment': decoded['current_treatment'] is Map ? Map<String, dynamic>.from(decoded['current_treatment']) : <String, dynamic>{},
          'plan_tasks': planTasks,
        };
      });
      return true;
    } catch (e) {
      debugPrint("task_detail error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load task detail: $e"), backgroundColor: Colors.redAccent),
        );
      }
      return false;
    }
  }

  Future<bool> _fetchCaseDetail(String caseId) async {
    if (_caseDetailLoading) return false;
    setState(() {
      _caseDetailLoading = true;
      _caseDetailError = null;
    });
    try {
      final resp = await http
          .post(
            _caseDetailUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'case_id': caseId}),
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception("case_detail failed (${resp.statusCode}): ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is Map) {
        final data = decoded['case'] is Map ? Map<String, dynamic>.from(decoded['case']) : decoded;
        final profile = decoded['patient_profile'] is Map ? Map<String, dynamic>.from(decoded['patient_profile']) : null;
        if (profile != null) {
          data['patient_profile'] = profile;
        }
        final recs = decoded['records'] is List ? List<Map<String, dynamic>>.from(decoded['records']) : <Map<String, dynamic>>[];
        setState(() {
          _caseDetail = Map<String, dynamic>.from(data);
          _caseDetailPatientProfile = profile;
          _caseDetailRecords = recs;
        });
        return true;
      }
      throw Exception("case_detail: unexpected response");
    } catch (e) {
      debugPrint("case_detail error: $e");
      if (mounted) {
        setState(() => _caseDetailError = "Failed to load case detail: $e");
      }
      return false;
    } finally {
      if (mounted) setState(() => _caseDetailLoading = false);
    }
  }

  Future<void> _fetchPatientList() async {
    if (_patientsLoading) return;
    setState(() {
      _patientsLoading = true;
      _patientsError = null;
      _patientsFetchedOnce = true;
    });
    try {
      final resp = await http.get(_patientListUri).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception("patients_list failed (${resp.statusCode}): ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      List<dynamic> raw;
      if (decoded is List) {
        raw = decoded;
      } else if (decoded is Map && decoded['patients'] is List) {
        raw = decoded['patients'] as List;
      } else {
        throw Exception("patients_list: unexpected response");
      }
      final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final active = items.where((p) {
        final status = p['status']?.toString().toLowerCase();
        return status == null || status == "active";
      }).toList();
      if (mounted) {
        setState(() => _patientItems = active);
      }
    } catch (e) {
      debugPrint("patients_list error: $e");
      if (mounted) {
        setState(() => _patientsError = "Failed to load patients: $e");
      }
    } finally {
      if (mounted) setState(() => _patientsLoading = false);
    }
  }

  void _prefillIntakeFromSelectedPatient(Map<String, dynamic> p) {
    String? formatDob(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      try {
        final dt = DateTime.parse(s);
        return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      } catch (_) {
        return s;
      }
    }

    String? mapDiabetesYears(dynamic v) {
      if (v == null) return null;
      final raw = v.toString().trim();
      if (raw.isEmpty) return null;
      if (["<1y", "1-5y", "5-10y", ">10y"].contains(raw)) return raw;
      final n = double.tryParse(raw);
      if (n == null) return null;
      if (n < 1) return "<1y";
      if (n <= 5) return "1-5y";
      if (n <= 10) return "5-10y";
      return ">10y";
    }

    final diabetes = (p['diabetes'] is Map) ? Map<String, dynamic>.from(p['diabetes']) : <String, dynamic>{};
    final hasDiabetesRaw = diabetes['has_diabetes']?.toString().toLowerCase();
    final hasDiabetes = hasDiabetesRaw == 'yes' || hasDiabetesRaw == 'true' ? "Yes" : (hasDiabetesRaw == 'no' || hasDiabetesRaw == 'false' ? "No" : null);

    _patientProfile
      ..clear()
      ..addAll(p);

    _patientNameCtrl.text = (p['patient_name'] ?? '').toString();
    _nrcIdCtrl.text = (p['nrc_id'] ?? '').toString();
    _dobCtrl.text = formatDob(p['dob']) ?? '';
    _selectedGender = p['gender']?.toString().toLowerCase();
    _patientPhoneCtrl.text = (p['phone_no'] ?? '').toString();
    _patientHeightCtrl.text = (p['height_cm'] ?? '').toString();
    _patientWeightCtrl.text = (p['weight_kg'] ?? '').toString();
    _otherCompCtrl.text = (p['medical_history'] ?? '').toString();

    _hasDiabetes = hasDiabetes;
    _diabetesYears = mapDiabetesYears(diabetes['years']);
    _riskHistory
      ..clear()
      ..addAll((diabetes['risk_history'] is List) ? List<String>.from(diabetes['risk_history']) : const <String>[]);
    _complications
      ..clear()
      ..addAll((diabetes['complications'] is List) ? List<String>.from(diabetes['complications']) : const <String>[]);
    _patientPhoto = null;
    _patientPhotoUrl = (p['photo_url'] ?? p['patient_photo_url'] ?? p['patient_photo'] ?? '').toString();
    if (_patientPhotoUrl != null && _patientPhotoUrl!.isEmpty) {
      _patientPhotoUrl = null;
    }
  }

  Future<bool> _createCaseFromVitals() async {
    final patientId = _patientProfile['patient_id'];
    if (patientId == null || patientId.toString().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Missing patient ID."), backgroundColor: Colors.orange),
        );
      }
      return false;
    }

    final vitals = {
      'temperature': _reviewed['temperature'],
      'blood_pressure': _reviewed['blood_pressure'],
      'heart_rate': _reviewed['heart_rate'],
      'respiratory_rate': _reviewed['respiratory_rate'],
      'blood_sugar': _reviewed['blood_sugar'],
    };

    final payload = {
      'patient_id': patientId,
      'status': 'CREATION',
      if (_followUpFlow && _caseRefs['case_id'] != null) 'case_id': _caseRefs['case_id'],
      'vitals': vitals,
      'meta': {
        'sent_at': _getFormattedTimestamp(),
      }
    };
    debugPrint("Create case payload: ${jsonEncode(payload)}");

    try {
      final caseId = _caseRefs['case_id']?.toString();
      final useUpdate = _followUpFlow && caseId != null && caseId.isNotEmpty;
      final uri = useUpdate ? _updateCaseUri : _createCaseUri;
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw Exception("${useUpdate ? 'Update-case' : 'Create-case'} failed (${resp.statusCode}): ${resp.body}");
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is Map) {
        final pid = decoded['patient_id'];
        final caseId = decoded['case_id'];
        final recordId = decoded['record_id'];
        if (pid != null && caseId != null && recordId != null) {
          _caseRefs
            ..clear()
            ..addAll({'patient_id': pid, 'case_id': caseId, 'record_id': recordId});
        } else {
          throw Exception("Create-case missing IDs.");
        }
      }
      return true;
    } catch (e) {
      debugPrint("Create-case error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Create case failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
      return false;
    }
  }

  void _navigateTo(String step, {Map<String, dynamic>? patient}) {
    setState(() {
      _currentStep = step;
      if (step != 'camera') {
        _emergencyBypassProfile = false;
      }
      if (step == 'assessment') {
        _sinbadSite = _reviewed['sinbad_site'];
        _sinbadIschemia = _reviewed['sinbad_ischemia'];
        _sinbadNeuropathy = _reviewed['sinbad_neuropathy'];
        _sinbadInfection = _reviewed['sinbad_infection'];
        _sinbadArea = _reviewed['sinbad_area'];
        _sinbadDepth = _reviewed['sinbad_depth'];
      }
      if (step == 'vital_check_page') {
        _clearVitalsInfo();
      }
      if (step == 'patient_search') {
        setState(() => _patientsFetchedOnce = false);
        _fetchPatientList();
      }
      if (step == 'tasks') {
        _fetchTasksList();
      }
      if (patient != null) {
        _selectedPatient = patient;
        _capturedImage = null; // BUG FIX: Clear session image when viewing a record
        _capturedImageBytes = null;
        // Bind clinical data to state for mock patients/existing cases
        if (patient.containsKey('ai_wound_json')) {
          _aiWoundJson = Map<String, dynamic>.from(patient['ai_wound_json']);
        } else {
          _aiWoundJson = null;
        }
        if (patient.containsKey('nurse_reviewed')) {
          _reviewed..clear()..addAll(Map<String, dynamic>.from(patient['nurse_reviewed']));
        } else {
          _reviewed.clear();
        }
        if (patient.containsKey('urgency')) {
          _selectedUrgency = patient['urgency'];
        } else {
          _selectedUrgency = null;
        }
      }
    });
  }

  void _enterFollowUpVitals(Map<String, dynamic> caseData) {
    final patientId = caseData['patient_id']?.toString();
    final caseId = caseData['case_id']?.toString();
    final recordId = caseData['current_record_id']?.toString();
    _capturedImage = null;
    _capturedImageBytes = null;
    if (patientId != null && patientId.isNotEmpty) {
      _patientProfile['patient_id'] = patientId;
    }
    _caseRefs
      ..clear()
      ..addAll({
        if (patientId != null) 'patient_id': patientId,
        if (caseId != null) 'case_id': caseId,
        if (recordId != null) 'record_id': recordId,
      });
    _navigateTo('vital_check_page');
  }

  bool _shouldShowNav() => ['dashboard', 'tasks', 'cases'].contains(_currentStep);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(_currentStep + _activeTab.toString()),
                child: _buildCurrentStep(),
              ),
            ),
          ),
          if (_isAnalyzing) _buildAnalysisOverlay(),
        ],
      ),
      bottomNavigationBar: _shouldShowNav() ? _buildBottomNav() : null,
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 'dashboard') {
      switch (_activeTab) {
        case 0: return _buildDashboard();
        case 1: return _buildTasksTab();
        case 2: return _buildCasesTab();
        case 3: return _buildProfileTab();
        default: return _buildDashboard();
      }
    }
    switch (_currentStep) {
      case 'patient_search': return _buildPatientSearch();
      case 'intake': return _buildIntakeForm();
      case 'camera': return _buildARCamera();
      case 'response_view': return _buildResponseView();
      case 'doctor_summary': return _buildDoctorSummary();
      case 'assessment': return _buildWoundAssessmentForm();
      case 'detail': return _buildDoctorSummary(); 
      case 'case_detail': return _buildCaseDetailPage();
      case 'patient_cases': return _buildPatientCasesPage();
      case 'healing_progress': return _buildHealingProgressPage();
      case 'task_detail': return _buildTaskDetailPage();
      case 'vital_check_page': return _buildVitalCheckPage();
      default: return _buildDashboard();
    }
  }

  

  

  

  

  

  

  

  

  

  

  

  // Helpers
  Widget _buildFormLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))));
  InputDecoration _inputDeco(IconData icon, String hint) => InputDecoration(prefixIcon: Icon(icon, size: 20, color: TWColors.slate.shade400), hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
  Widget _buildSuccessBanner() => Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF5EEAD4))), child: const Row(children: [Icon(LucideIcons.circleCheck, size: 16, color: Color(0xFF0D9488)), SizedBox(width: 8), Text("Profile saved.", style: TextStyle(fontSize: 12, color: Color(0xFF134E4A), fontWeight: FontWeight.bold))]));
  Widget _buildIntakeFooter() => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _savePatientProfile,
              icon: const Icon(LucideIcons.save),
              label: const Text("Save Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            // const SizedBox(height: 12),
            // ElevatedButton.icon(
            //   onPressed: _patientProfileSaved ? () => _navigateTo('camera') : null,
            //   icon: const Icon(LucideIcons.camera),
            //   label: const Text("Take Wound Photo"),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: _patientProfileSaved ? const Color(0xFF0D9488) : TWColors.slate.shade300,
            //     foregroundColor: Colors.white,
            //     minimumSize: const Size(double.infinity, 60),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            //   ),
            // ),
          ],
        ),
      );

  Widget _buildTextField({required String label, required String placeholder, IconData? icon, String? initialValue, TextInputType keyboardType = TextInputType.text, String? bindKey}) {
    final TextEditingController? controller = bindKey == null ? null : _ctrl(bindKey, initial: initialValue ?? '');
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))), const SizedBox(height: 8), TextFormField(controller: controller, keyboardType: keyboardType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), onChanged: (v) { if (bindKey != null) { _reviewed[bindKey] = v; if (bindKey == 'size_width_cm' || bindKey == 'size_length_cm') { _maybeComputeSinbadAreaFromSize(); } } }, decoration: _inputDeco(icon ?? LucideIcons.fileText, placeholder))]));
  }

  void _maybeComputeSinbadAreaFromSize() {
    final widthRaw = _reviewed['size_width_cm']?.toString();
    final lengthRaw = _reviewed['size_length_cm']?.toString();
    if (widthRaw == null || lengthRaw == null) return;
    final width = double.tryParse(widthRaw);
    final length = double.tryParse(lengthRaw);
    if (width == null || length == null) return;
    final area = width * length;
    final areaLabel = area >= 1.0 ? kSinbadAreaLarge : kSinbadAreaSmall;
    setState(() {
      _sinbadArea = areaLabel;
      _reviewed['sinbad_area'] = areaLabel;
    });
  }

  Widget _buildDropdownField({required String label, required List<String> options, String? value, String? bindKey}) {
    final String? effectiveValue = _coerceEnum(value, options);
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))), const SizedBox(height: 8), DropdownButtonFormField<String>(isExpanded: true, key: ValueKey('drop_${label}_${effectiveValue ?? 'none'}'), initialValue: effectiveValue, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), items: options.map((s) => DropdownMenuItem<String>(value: s, child: Text(s.replaceAll('_', ' '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(), onChanged: (v) { if (bindKey == null) return; setState(() { _reviewed[bindKey] = v; if (bindKey == 'has_infection') { if (v == 'true') { _sinbadInfection = 'Yes'; _reviewed['sinbad_infection'] = 'Yes'; } else if (v == 'false') { _sinbadInfection = 'No'; _reviewed['sinbad_infection'] = 'No'; } } }); })]));
  }

  Widget _buildChoiceChip(String label, {bool initialSelected = false, String? bindKey}) {
    bool selected = initialSelected;
    return StatefulBuilder(builder: (context, setLocal) {
      return FilterChip(label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), selected: selected, onSelected: (b) { setLocal(() => selected = b); if (bindKey != null) _reviewed[bindKey] = b; }, selectedColor: const Color(0xFF0D9488).withOpacity(0.2), checkmarkColor: const Color(0xFF0D9488), backgroundColor: const Color(0xFFF8FAFC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none));
    });
  }

  // Static UI Blocks
  Widget _buildStatCard({required IconData icon, required String label, required String value, required String subValue, required Color color, required Color iconColor}) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))])), Text(subValue, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor))]));
  Widget _buildActionCard() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(24)), child: const Row(children: [Icon(LucideIcons.listTodo, color: Colors.white), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("4", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), Text("TASKS FOR TODAY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70))])), Icon(LucideIcons.chevronRight, color: Colors.white70)]));
  Widget _buildProfileAvatar() => Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(14)), child: const Center(child: Text("RN", style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold))));
  Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 140, child: Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(child: Text(v.isEmpty ? "-" : v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))))]));
  Widget _buildAISuggestionBox() => Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF5EEAD4))), child: Row(children: [const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF0D9488)), const SizedBox(width: 8), Expanded(child: Text("Analysis successful. Please verify clinical data.", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF134E4A))))]));
  Widget _buildAnalysisOverlay() => Container(
        color: Colors.black.withOpacity(0.9),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: Color(0xFF0D9488), strokeWidth: 5)),
            const SizedBox(height: 32),
            const Icon(LucideIcons.sparkles, color: Color(0xFF0D9488), size: 32),
            const SizedBox(height: 16),
            Text(
              _analysisTitle,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(_analysisMessage, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
  Widget _buildHeader(String title, {required VoidCallback onBack}) => Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))), child: Row(children: [IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: onBack), const SizedBox(width: 8), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]));
  Widget _buildSectionTitle(IconData icon, String title) => Row(children: [Icon(icon, size: 20, color: const Color(0xFF0D9488)), const SizedBox(width: 10), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))))]);
  Widget _buildFixedBottomButton(String label, IconData icon, VoidCallback onPressed) => Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))), child: ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))));

  Widget _buildPatientListTile(Map<String, dynamic> p, {VoidCallback? onTap}) {
    Color urgencyColor;
    String urgencyText;
    
    switch (p['urgency']) {
      case 'high_urgent':
        urgencyColor = Colors.red;
        urgencyText = "HIGH";
        break;
      case 'medium':
        urgencyColor = Colors.orange;
        urgencyText = "MEDIUM";
        break;
      case 'routine':
      default:
        urgencyColor = const Color(0xFF0D9488);
        urgencyText = "ROUTINE";
        break;
    }

    final image = p['image'] ?? p['image_url'] ?? p['patient_photo_url'] ?? '';
    final patientId = p['patient_id'] ?? p['patientId'];
    final id = p['id'] ?? p['case_id'] ?? p['caseId'] ?? "-";
    final name = p['name'] ??
        p['patient_name'] ??
        p['patient']?['patient_name'] ??
        (patientId != null ? "Patient $patientId" : "Unknown");
    final title = (p['case_id'] ?? p['caseId']) != null ? id.toString() : name.toString();
    final status = p['status']?.toString() ?? "unknown";
    Color statusBg(String s) {
      switch (s.toUpperCase()) {
        case 'CREATION':
          return const Color(0xFFE0F2FE);
        case 'ANALYZING':
          return const Color(0xFFFFF7ED);
        case 'DOCTOR_REVIEW':
          return const Color(0xFFE0E7FF);
        case 'COMPLETED':
          return const Color(0xFFDCFCE7);
        default:
          return const Color(0xFFF1F5F9);
      }
    }

    Color statusFg(String s) {
      switch (s.toUpperCase()) {
        case 'CREATION':
          return const Color(0xFF0369A1);
        case 'ANALYZING':
          return const Color(0xFF9A3412);
        case 'DOCTOR_REVIEW':
          return const Color(0xFF4338CA);
        case 'COMPLETED':
          return const Color(0xFF15803D);
        default:
          return const Color(0xFF64748B);
      }
    }

    String formatCaseUpdated(dynamic raw) {
      if (raw == null || raw.toString().isEmpty) return "-";
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return "$y-$m-$d $hh:$mm";
      } catch (_) {
        return raw.toString();
      }
    }

    return GestureDetector(
      onTap: onTap ?? () => _navigateTo('detail', patient: p),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (image is String && image.isNotEmpty)
                      ? Image.network(
                          image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 50,
                            height: 50,
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.broken_image, size: 18),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.person, size: 18),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Patient: ${patientId ?? '-'}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Updated: ${formatCaseUpdated(p['case_updated_at'])}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                urgencyText,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: urgencyColor,
                ),
              ),
            ),
          ),
          Positioned(
            top: 36,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg(status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: statusFg(status),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() => BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          setState(() {
            _activeTab = index;
            _currentStep = 'dashboard';
          });
          if (index == 1) {
            setState(() => _tasksFetchedOnce = false);
            _fetchTasksList();
          }
          if (index == 2) {
            setState(() => _casesFetchedOnce = false);
            _fetchCasesList();
          }
        },
        selectedItemColor: const Color(0xFF0D9488),
        unselectedItemColor: TWColors.slate.shade400,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.house), label: "Home"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.listTodo), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList), label: "Cases"),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: "Profile"),
        ],
      );
  Widget _buildProfileTile(IconData icon, String label, {Color? color}) => ListTile(leading: Icon(icon, color: color ?? const Color(0xFF0D9488)), title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), trailing: const Icon(LucideIcons.chevronRight, size: 16));
}
