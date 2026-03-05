import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

const String kDemoWoundImageUrl = "https://blog.wcei.net/wp-content/uploads/2019/03/diabetic_foot_ulcer.jpg";

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
  Map<String, dynamic>? _selectedPatient;
  bool _isAnalyzing = false;
  String _analysisTitle = "GEMINI CLOUD";
  String _analysisMessage = "Analyzing...";
  XFile? _capturedImage;
  Uint8List? _capturedImageBytes;
  XFile? _patientPhoto; 
  Uint8List? _patientPhotoBytes;
  String? _rawResponse;
  Map<String, dynamic>? _aiExtraction;
  Map<String, dynamic>? _aiWoundJson;
  final Map<String, dynamic> _reviewed = {};
    // =========================
  // Task Detail (NEW)
  // =========================
  int? _selectedTaskPatientIndex;
  int? _selectedTaskIndex;
  XFile? _taskEvidencePhotoTemp; // temp holder (optional)
  Uint8List? _taskEvidencePhotoTempBytes;

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
      final Uint8List bytes = await image.readAsBytes();

      setState(() {
        _taskEvidencePhotoTemp = image;
        _taskEvidencePhotoTempBytes = bytes;
        final t = _getSelectedTask();
        if (t != null) {
          t['evidence_path'] = image.path; // store local file path (demo)
          t['evidence_bytes'] = bytes;
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


  static const String _baseUrl = "http://10.0.2.2:8000";
  final Uri _fillinUri = Uri.parse("$_baseUrl/analyze-fillin");
  final Uri _analyzeWoundUri = Uri.parse("$_baseUrl/analyze-wound");
  final Uri _createCaseUri = Uri.parse("$_baseUrl/create-case"); 
  final Uri _createPatientUri = Uri.parse("$_baseUrl/create-patient-profile");
  final Uri _docsUri = Uri.parse("$_baseUrl/docs");

  // Mock Clinical Data with Wound Images
  final List<Map<String, dynamic>> _patients = buildMockPatients();
  final Map<String, dynamic> _mockFillin = {
    "location_primary": "sole",
    "location_detail": "Plantar aspect of the first metatarsal head (ball of the foot)",
    "wound_type": "Diabetic Foot Ulcer (DFU)",
    "shape": "punched_out",
    "size_width_cm": 2.5,
    "size_length_cm": 3.0,
    "depth_category": "full_thickness",
    "bed_slough_pct": 80,
    "bed_necrotic_pct": 5,
    "edge_description": "calloused",
    "periwound_status": "erythematous",
    "discharge_volume": "moderate",
    "discharge_type": "seropurulent (cloudy yellow)",
    "odor_presence": "faint",
    "pain_score": 2,
    "has_infection": true,
    "skin_condition": "dry"
  };
  final Map<String, dynamic> _mockAiWound = {
    "AI_analysis": {
      "creator": "Gemini AI",
      "wound_stage": "UT Grade 1 Stage B",
      "description": "1. Patient & Clinical Overview: Patient presents with a chronic ulcer on the plantar aspect of the foot. History and presentation are consistent with a neuropathic diabetic foot ulcer (DFU). 2. Formal Wound Description: Location: Plantar aspect of the first metatarsal head. Size: Approximately 2.5cm x 3.0cm. Shape: Punched-out with hyperkeratotic (calloused) borders. Wound Bed: Predominantly yellow slough (~80%) with minimal visible granulation tissue. Discharge: Moderate seropurulent (cloudy yellow) exudate. Periwound: Significant erythema and dry skin. 3. Image Analysis Insights: Visual inspection confirms a classic neuropathic DFU. The thick callous ring suggests repetitive mechanical stress. The presence of cloudy exudate and surrounding redness strongly suggests localized infection. No deep structures (tendon/bone) are clearly visible in the photo, though depth must be confirmed via probing. 4. Wound Staging: UT Grade 1 Stage B. Justification: Grade 1 due to superficial involvement without visible deep structures; Stage B due to clinical signs of infection (erythema, seropurulent discharge, slough). 5. Red Flags: None immediately visible (no gangrene or systemic signs reported), but erythema requires monitoring for cellulitis. FINAL SAFETY DISCLAIMER: This is an AI-generated draft for clinical documentation support only and must be reviewed and verified by a licensed medical professional before use. Seek urgent medical care if there are signs of severe infection, rapidly worsening redness/swelling, fever, severe pain, or gangrene.",
      "diagnosis": "Infected neuropathic diabetic foot ulcer (plantar surface).",
      "confidence": 0.65,
      "red_flag": false,
      "treatment_plan": "Focus on infection control, offloading, and debridement. 1. Infection Management: Consider topical or systemic antimicrobials per clinician/local protocol given Stage B status. 2. Debridement: Sharp debridement of the hyperkeratotic rim and non-viable slough to stimulate the wound bed. 3. Offloading: Essential to use therapeutic footwear or total contact casting to reduce pressure on the metatarsal head. 4. Moisture Balance: Use dressings capable of managing moderate seropurulent exudate (e.g., foams or alginates). FINAL SAFETY DISCLAIMER: This is an AI-generated draft for clinical documentation support only and must be reviewed and verified by a licensed medical professional before use. Seek urgent medical care if there are signs of severe infection, rapidly worsening redness/swelling, fever, severe pain, or gangrene."
    },
    "treatment_plan": {
      "plan_text": "Nurse-led care for infected DFU: Cleanse wound, apply prescribed antimicrobial dressing, ensure patient is using offloading device, and monitor for spreading redness or fever. FINAL SAFETY DISCLAIMER: This is an AI-generated draft for clinical documentation support only and must be reviewed and verified by a licensed medical professional before use. Seek urgent medical care if there are signs of severe infection, rapidly worsening redness/swelling, fever, severe pain, or gangrene.",
      "followup_days": 3,
      "status": "DRAFT",
      "plan_tasks": [
        {
          "task_text": "Cleanse wound and apply antimicrobial dressing per protocol.",
          "status": "DRAFT",
          "task_due": "2026-02-16T16:00:00+07:00"
        },
        {
          "task_text": "Verify patient has and is using appropriate offloading footwear.",
          "status": "DRAFT",
          "task_due": "2026-02-16T16:00:00+07:00"
        },
        {
          "task_text": "Monitor periwound erythema for signs of spreading (cellulitis).",
          "status": "DRAFT",
          "task_due": "2026-02-17T10:00:00+07:00"
        },
        {
          "task_text": "Assess for systemic symptoms (fever, chills, malaise).",
          "status": "DRAFT",
          "task_due": "2026-02-17T10:00:00+07:00"
        }
      ]
    }
  };

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
    try {
      if (kIsWeb) {
        final XFile image = XFile(kDemoWoundImageUrl);
        setState(() {
          _capturedImage = image;
          _capturedImageBytes = null;
        });
        await _uploadAndAnalyzeFillin(image);
        return;
      }
      // Demo mode: use a fixed online image instead of taking a real photo.
      final response = await http.get(Uri.parse(kDemoWoundImageUrl));
      if (response.statusCode != 200) {
        throw Exception("Failed to load demo image (HTTP ${response.statusCode}).");
      }
      final Uint8List bytes = response.bodyBytes;
      final XFile image = XFile.fromData(
        bytes,
        name: "demo_wound.jpg",
        mimeType: "image/jpeg",
      );
      setState(() {
        _capturedImage = image;
        _capturedImageBytes = bytes;
      });
      await _uploadAndAnalyzeFillin(image);
    } catch (e) {
      debugPrint("Error loading demo image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load demo image: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Picker for patient profile photo
  Future<void> _pickPatientPhoto(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 60);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _patientPhoto = image;
          _patientPhotoBytes = bytes;
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
      final extracted = Map<String, dynamic>.from(_mockFillin);
      setState(() {
        _responseMode = 'fillin';
        _aiExtraction = extracted;
        _rawResponse = const JsonEncoder.withIndent('  ').convert(extracted);
        _reviewed..clear()..addAll(extracted);
        _reviewed.remove('odor_presence');
        _reviewed.remove('pain_score');
        _reviewed.remove('has_infection');
      });
      _applyPrefillControllersFromReviewed();
      _maybeComputeSinbadAreaFromSize();
      _navigateTo('response_view');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.redAccent));
      _navigateTo('assessment');
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
    setState(() {
      _analysisTitle = "GEMINI CLOUD";
      _analysisMessage = "Analyzing...";
      _isAnalyzing = true;
    });
    try {
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
      };
      setState(() {
        _aiWoundJson = Map<String, dynamic>.from(_mockAiWound);
        _selectedUrgency = null;
        _rawResponse = const JsonEncoder.withIndent('  ').convert(payload);
      });
      _navigateTo('doctor_summary');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submit failed: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // API Trigger: /create-case
  Future<String> _createCase() async {
    if (_capturedImage == null || _aiWoundJson == null) throw Exception("Missing clinical data or wound image.");
    if (_selectedUrgency == null) throw Exception("Please select a clinical urgency level.");
    
    final caseData = {
      'patient_profile': _patientProfile, 
      'selected_patient': _selectedPatient, 
      'nurse_reviewed': _reviewed, 
      'ai_prefill': _aiExtraction, 
      'ai_analysis': _aiWoundJson, 
      'urgency': _selectedUrgency, 
      'meta': {
        'sent_at': _getFormattedTimestamp(),
      }
    };
    return jsonEncode(caseData);
  }

  Future<void> _sendToDoctor() async {
    if (_selectedUrgency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set an urgency level before sending."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _analysisTitle = "GEMINI CLOUD";
      _analysisMessage = "Analyzing...";
      _isAnalyzing = true;
    });
    try {
      final bodyText = await _createCase();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Clinical case successfully sent to doctor."),
          backgroundColor: Color(0xFF0D9488),
        ),
      );

      setState(() {
        _responseMode = 'analysis';
        _rawResponse = bodyText;
        _capturedImage = null; // Clear image after submission
        _aiWoundJson = null;   // Reset session state
        _reviewed.clear();
      });
      _navigateTo('dashboard');
    } catch (e) {
      debugPrint("API Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Send failed: $e"), backgroundColor: Colors.redAccent));
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
      _patientProfile..clear()..addAll(payload);
      setState(() => _patientProfileSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Patient profile saved (mock)."), backgroundColor: Color(0xFF0D9488)),
        );
      }
      _navigateTo('vital_check_page');
    } catch (e) {
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
  Widget _buildXFileImage(
    XFile file, {
    Uint8List? bytes,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (kIsWeb) {
      if (bytes != null) {
        return Image.memory(bytes, height: height, width: width, fit: fit);
      }
      final path = file.path;
      if (path.isNotEmpty) {
        return Image.network(path, height: height, width: width, fit: fit);
      }
      return const SizedBox.shrink();
    }
    return Image.file(File(file.path), height: height, width: width, fit: fit);
  }

  Widget _buildEvidenceImage(
    String path, {
    Uint8List? bytes,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (kIsWeb) {
      if (bytes != null) {
        return Image.memory(bytes, height: height, width: width, fit: fit);
      }
      return Container(
        height: height,
        width: width,
        color: const Color(0xFFE2E8F0),
        child: const Center(child: Icon(Icons.broken_image)),
      );
    }
    return Image.file(File(path), height: height, width: width, fit: fit);
  }

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
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))), const SizedBox(height: 8), DropdownButtonFormField<String>(isExpanded: true, key: ValueKey('drop_${label}_${effectiveValue ?? 'none'}'), value: effectiveValue, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), items: options.map((s) => DropdownMenuItem<String>(value: s, child: Text(s.replaceAll('_', ' '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(), onChanged: (v) { if (bindKey == null) return; setState(() { _reviewed[bindKey] = v; if (bindKey == 'has_infection' && v == 'true') { _sinbadInfection = 'Yes'; _reviewed['sinbad_infection'] = 'Yes'; } }); })]));
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
