import 'dart:convert';
import 'dart:io';
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
part '../pages/profile_page.dart';
part '../pages/camera_page.dart';
part '../pages/vital_check_page.dart';
part '../pages/assessment_page.dart';

const String kSinbadAreaSmall = "< 1 cm²";
const String kSinbadAreaLarge = "≥ 1 cm²";


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
  final TextEditingController _patientSearchCtrl = TextEditingController();
  String _patientSearchQuery = "";
  final Map<String, dynamic> _patientProfile = {};
  bool _patientProfileSaved = false;
  bool _emergencyBypassProfile = false;

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
  XFile? _patientPhoto; 
  String? _rawResponse;
  Map<String, dynamic>? _aiExtraction;
  Map<String, dynamic>? _aiWoundJson;
  final Map<String, dynamic> _reviewed = {};
  final Map<String, dynamic> _caseRefs = {};
    // =========================
  // Task Detail (NEW)
  // =========================
  int? _selectedTaskPatientIndex;
  int? _selectedTaskIndex;
  XFile? _taskEvidencePhotoTemp; // temp holder (optional)

  Map<String, dynamic>? _getSelectedTask() {
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
    if (_selectedTaskPatientIndex == null) return null;
    return _patients[_selectedTaskPatientIndex!];
  }

  Future<void> _pickTaskEvidencePhoto(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 75);
      if (image == null) return;

      setState(() {
        _taskEvidencePhotoTemp = image;
        final t = _getSelectedTask();
        if (t != null) {
          t['evidence_path'] = image.path; // store local file path (demo)
          t['evidence_captured_at'] = _getFormattedTimestamp();
        }
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

  void _completeSelectedTask() {
    final t = _getSelectedTask();
    if (t == null) return;

    final evidencePath = (t['evidence_path'] ?? '').toString();
    if (evidencePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take an evidence photo before completing."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      t['status'] = "Completed";
      t['completed_at'] = _getFormattedTimestamp();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task marked as completed."), backgroundColor: Color(0xFF0D9488)),
    );
  }


  static const String _baseUrl = "https://foster-ulcer-backend-583037019860.asia-southeast3.run.app";
  final Uri _fillinUri = Uri.parse("$_baseUrl/analyze-fillin");
  final Uri _analyzeWoundUri = Uri.parse("$_baseUrl/analyze-wound");
  final Uri _createPatientUri = Uri.parse("$_baseUrl/create-patient-profile");
  final Uri _createCaseUri = Uri.parse("$_baseUrl/create-case");
  final Uri _sendToDoctorUri = Uri.parse("$_baseUrl/send-to-doctor");
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
        setState(() => _capturedImage = image);
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
        setState(() => _patientPhoto = image);
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
      final bytes = await imageFile.readAsBytes();
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
        setState(() {
          _responseMode = 'fillin';
          _aiExtraction = extracted;
          _rawResponse = const JsonEncoder.withIndent('  ').convert(extracted ?? analysisData);
          _reviewed..clear()..addAll(extracted ?? {});
          _reviewed.remove('odor_presence');
          _reviewed.remove('pain_score');
          _reviewed.remove('has_infection');
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
      final reviewed = Map<String, dynamic>.from(_reviewed);
      reviewed.putIfAbsent('odor_presence', () => '');
      reviewed.putIfAbsent('pain_score', () => '');
      reviewed.putIfAbsent('has_infection', () => null);
      final filteredProfile = Map<String, dynamic>.from(_patientProfile)
        ..remove('patient_name')
        ..remove('phone_no')
        ..remove('patient_photo_url')
        ..remove('patient_photo');
      final payload = {
        'patient_profile': filteredProfile,
        'selected_patient': _selectedPatient,
        'nurse_reviewed': reviewed,
        'ai_prefill': _aiExtraction,
        'case_ref': _caseRefs.isEmpty ? null : Map<String, dynamic>.from(_caseRefs),
      };
      debugPrint("Analyze-wound payload: ${jsonEncode(payload)}");
      request.fields['patient_data'] = jsonEncode(payload);
      final bytes = await _capturedImage!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: _capturedImage!.name));
      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) throw Exception("Server Error");
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['status'] == 'success' && body.containsKey('analysis')) {
        final analysisVal = body['analysis'];
        final parsed = _parseAnalysis(analysisVal);
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
          _navigateTo('doctor_summary');
          return;
        }
        setState(() {
          _responseMode = 'analysis';
          _rawResponse = analysisVal?.toString();
          _aiExtraction = null;
          _aiWoundJson = null;
        });
        _navigateTo('response_view');
      }
    } catch (e) {
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
        'respiratory_rate': _reviewed['repiratory_rate'],
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
      'repiratory_rate': _reviewed['repiratory_rate'],
      'blood_sugar': _reviewed['blood_sugar'],
    };

    final payload = {
      'patient_id': patientId,
      'status': 'CREATION',
      'vitals': vitals,
      'meta': {
        'sent_at': _getFormattedTimestamp(),
      }
    };
    debugPrint("Create case payload: ${jsonEncode(payload)}");

    try {
      final resp = await http
          .post(
            _createCaseUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        throw Exception("Create-case failed (${resp.statusCode}): ${resp.body}");
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
      if (patient != null) {
        _selectedPatient = patient;
        _capturedImage = null; // BUG FIX: Clear session image when viewing a record
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

  Widget _buildPatientListTile(Map<String, dynamic> p) {
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

    return GestureDetector(
      onTap: () => _navigateTo('detail', patient: p),
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
                  child: Image.network(
                    p['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.broken_image, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "ID: ${p['id']} • Status: ${p['status']}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
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
        ],
      ),
    );
  }

  Widget _buildBottomNav() => BottomNavigationBar(currentIndex: _activeTab, onTap: (index) => setState(() { _activeTab = index; _currentStep = 'dashboard'; }), selectedItemColor: const Color(0xFF0D9488), unselectedItemColor: TWColors.slate.shade400, type: BottomNavigationBarType.fixed, items: const [BottomNavigationBarItem(icon: Icon(LucideIcons.house), label: "Home"), BottomNavigationBarItem(icon: Icon(LucideIcons.listTodo), label: "Tasks"), BottomNavigationBarItem(icon: Icon(LucideIcons.clipboardList), label: "Cases"), BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: "Profile")]);
  Widget _buildProfileTile(IconData icon, String label, {Color? color}) => ListTile(leading: Icon(icon, color: color ?? const Color(0xFF0D9488)), title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), trailing: const Icon(LucideIcons.chevronRight, size: 16));
}
