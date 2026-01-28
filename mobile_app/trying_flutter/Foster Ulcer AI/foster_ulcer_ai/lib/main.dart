import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tailwind_colors/flutter_tailwind_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FosterUlcerApp());
}

class FosterUlcerApp extends StatelessWidget {
  const FosterUlcerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foster Ulcer AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0D9488),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

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
    _occupationCtrl.dispose();
    _patientPhoneCtrl.dispose();
    _patientHeightCtrl.dispose();
    _patientWeightCtrl.dispose();
    _patientHistoryCtrl.dispose();

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
      'pain_score',
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

  final TextEditingController _patientNameCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  String? _selectedGender;
  String? _selectedUrgency; 
  final TextEditingController _occupationCtrl = TextEditingController();
  final TextEditingController _patientPhoneCtrl = TextEditingController();
  final TextEditingController _patientHeightCtrl = TextEditingController();
  final TextEditingController _patientWeightCtrl = TextEditingController();
  final TextEditingController _patientHistoryCtrl = TextEditingController();
  int _activeTab = 0;
  Map<String, dynamic>? _selectedPatient;
  bool _isAnalyzing = false;
  XFile? _capturedImage;
  XFile? _patientPhoto; 
  String? _rawResponse;
  Map<String, dynamic>? _aiExtraction;
  Map<String, dynamic>? _aiWoundJson;
  final Map<String, dynamic> _reviewed = {};

  static const String _baseUrl = "http://10.0.2.2:8000";
  final Uri _fillinUri = Uri.parse("$_baseUrl/analyze-fillin");
  final Uri _analyzeWoundUri = Uri.parse("$_baseUrl/analyze-wound");
  final Uri _createCaseUri = Uri.parse("$_baseUrl/create-case"); 
  final Uri _createPatientUri = Uri.parse("$_baseUrl/create-patient-profile");
  final Uri _docsUri = Uri.parse("$_baseUrl/docs");

  // Mock Clinical Data with Wound Images
  final List<Map<String, dynamic>> _patients = [
    {
      "id": "PT-1002",
      "name": "John Smith",
      "age": 68,
      "gender": "male",
      "stage": "Wagner 3",
      "priority": "Critical",
      "urgency": "high_urgent",
      "status": "In Treatment",
      "date": "2026-01-28",
      "image": "https://upload.wikimedia.org/wikipedia/commons/4/41/DMgas_gangrene.jpg",
      "todos": [
        {"task": "Apply antimicrobial dressing", "completed": false, "due": "Today, 4:00 PM", "urgent": true},
      ],
      "nurse_reviewed": {
        "temperature": "37.8",
        "blood_pressure": "145/95",
        "heart_rate": "92",
        "location_primary": "heel",
        "location_detail": "Lateral side of left heel",
        "wound_type": "Diabetic Foot Ulcer",
        "shape": "irregular",
        "size_width_cm": "4.2",
        "size_length_cm": "3.5",
        "depth_category": "full_thickness",
        "bed_slough_pct": "25",
        "bed_necrotic_pct": "10",
        "edge_description": "undermined",
        "periwound_status": "erythematous",
        "discharge_volume": "moderate",
        "discharge_type": "sanguineous (bloody)",
        "odor_presence": "moderate",
        "pain_score": "8",
        "has_infection": true,
        "skin_condition": "dry",
      },
      "ai_wound_json": {
        "AI_analysis": {
          "wound_stage": "Wagner Grade 3",
          "diagnosis": "Deep diabetic foot ulcer with active infection.",
          "confidence": 0.88,
          "description": "Deep tissue involvement reaching fascia. Slough covers 25% of bed. Active purulent discharge.",
        },
        "treatment_plan": {
          "plan_text": "Sharp debridement. Silver dressing. Oral Clindamycin. Vascular consult.",
          "plan_tasks": [
            {"task_text": "Apply silver dressing", "task_due": "2026-01-28T16:00:00", "status": "Urgent"},
            {"task_text": "Check glycemic levels", "task_due": "2026-01-28T14:00:00", "status": "Pending"},
          ],
        },
      }
    },
    {
      "id": "PT-3091",
      "name": "Rahul Sharma",
      "age": 71,
      "gender": "male",
      "stage": "Wagner 2",
      "priority": "Medium",
      "urgency": "medium",
      "status": "Stable",
      "date": "2026-01-27",
      "image": "https://www.saakhealth.com/wp-content/uploads/2024/10/Image20241008065706.png",
      "todos": [
        {"task": "Prepare for surgical referral", "completed": false, "due": "ASAP", "urgent": true},
      ],
      "nurse_reviewed": {
        "temperature": "36.8",
        "blood_pressure": "122/82",
        "heart_rate": "72",
        "location_primary": "sole",
        "location_detail": "1st metatarsal head",
        "wound_type": "Neuropathic Ulcer",
        "shape": "round",
        "size_width_cm": "2.0",
        "size_length_cm": "2.2",
        "depth_category": "partial_thickness",
        "bed_slough_pct": "0",
        "bed_necrotic_pct": "0",
        "edge_description": "smooth",
        "periwound_status": "normal",
        "discharge_volume": "minimal",
        "discharge_type": "serous",
        "odor_presence": "none",
        "pain_score": "2",
        "has_infection": false,
        "skin_condition": "healthy",
      },
      "ai_wound_json": {
        "AI_analysis": {
          "wound_stage": "Wagner Grade 2",
          "diagnosis": "Superficial neuropathic ulcer.",
          "confidence": 0.94,
          "description": "Healthy granulation tissue. No signs of localized infection.",
        },
        "treatment_plan": {
          "plan_text": "Saline cleaning. Hydrocolloid dressing. Pressure offloading.",
          "plan_tasks": [
            {"task_text": "Clean with saline", "task_due": "2026-01-28T09:00:00", "status": "Completed"},
          ],
        },
      }
    },
    {
      "id": "PT-4022",
      "name": "Sita Devi",
      "age": 62,
      "gender": "female",
      "stage": "Wagner 1",
      "priority": "Routine",
      "urgency": "routine",
      "status": "Stable",
      "date": "2026-01-26",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQq3gdPb0H4GwIzPsWw4L3AVtoQAGck3uX9Gg&s",
      "todos": [
        {"task": "Apply moisturizer", "completed": true, "due": "Completed", "urgent": false},
      ],
      "nurse_reviewed": {
        "temperature": "36.6",
        "blood_pressure": "118/76",
        "heart_rate": "70",
        "location_primary": "toe",
        "location_detail": "Great toe lateral",
        "wound_type": "Neuropathic Ulcer",
        "shape": "oval",
        "size_width_cm": "1.2",
        "size_length_cm": "1.5",
        "depth_category": "superficial",
        "bed_slough_pct": "0",
        "bed_necrotic_pct": "0",
        "edge_description": "smooth",
        "periwound_status": "normal",
        "discharge_volume": "none",
        "discharge_type": "none",
        "odor_presence": "none",
        "pain_score": "1",
        "has_infection": false,
        "skin_condition": "healthy",
      },
      "ai_wound_json": {
        "AI_analysis": {
          "wound_stage": "Wagner Grade 1",
          "diagnosis": "Minor skin break.",
          "confidence": 0.98,
          "description": "Routine maintenance case with no depth or exudate.",
        },
        "treatment_plan": {
          "plan_text": "Monitor daily. Apply urea cream for hydration.",
          "plan_tasks": [
            {"task_text": "Apply urea cream", "task_due": "2026-01-30T10:00:00", "status": "Pending"},
          ],
        },
      }
    }
  ];

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
    if (!_patientProfileSaved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please save/select the patient profile first."), backgroundColor: Colors.redAccent),
        );
      }
      _navigateTo('patient_search');
      return;
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
    setState(() => _isAnalyzing = true);
    try {
      final request = http.MultipartRequest('POST', _fillinUri);
      final bytes = await imageFile.readAsBytes();
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
        });
        _applyPrefillControllersFromReviewed();
      }
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
    setState(() => _isAnalyzing = true);
    try {
      final request = http.MultipartRequest('POST', _analyzeWoundUri);
      final reviewed = Map<String, dynamic>.from(_reviewed);
      final payload = {'patient_profile': Map<String, dynamic>.from(_patientProfile), 'selected_patient': _selectedPatient, 'nurse_reviewed': reviewed};
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

  // API Trigger: /create-case
  Future<String> _createCase() async {
    if (_capturedImage == null || _aiWoundJson == null) throw Exception("Missing clinical data or wound image.");
    if (_selectedUrgency == null) throw Exception("Please select a clinical urgency level.");
    
    final request = http.MultipartRequest('POST', _createCaseUri);
    
    // Bundle all information into caseData
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
    
    request.fields['case_data'] = jsonEncode(caseData);
    
    final bytes = await _capturedImage!.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'image', 
      bytes, 
      filename: 'wound_analysis_case.png'
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200) {
      throw Exception("Case submission failed (${response.statusCode}): ${response.body}");
    }
    
    return response.body;
  }

  Future<void> _sendToDoctor() async {
    if (_selectedUrgency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set an urgency level before sending."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
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
    final name = _patientNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isAnalyzing = true);
    try {
      final payload = {
        'patient_name': name,
        'phone_no': _patientPhoneCtrl.text.trim(),
        'dob': _dobCtrl.text, 
        'gender': _selectedGender,
        'height_cm': _patientHeightCtrl.text.trim(),
        'weight_kg': _patientWeightCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(), 
        'medical_history': _patientHistoryCtrl.text.trim(),
        'created_at': _getFormattedTimestamp(),
      };
      
      final req = http.MultipartRequest('POST', _createPatientUri);
      req.fields['patient_data'] = jsonEncode(payload);

      if (_patientPhoto != null) {
        final bytes = await _patientPhoto!.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes(
          'image', 
          bytes, 
          filename: 'patient_profile.png'
        ));
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Patient image is required."), backgroundColor: Colors.orange),
           );
        }
        setState(() => _isAnalyzing = false);
        return;
      }

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(resp.body);
      if (decoded['status'] == 'success') {
        _patientProfile..clear()..addAll(payload);
        setState(() => _patientProfileSaved = true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Patient profile and photo saved."), backgroundColor: Color(0xFF0D9488)));
      } else {
        throw Exception(decoded['detail'] ?? "Registration failed.");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _navigateTo(String step, {Map<String, dynamic>? patient}) {
    setState(() {
      _currentStep = step;
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
      case 'assessment': return _buildWoundAssessmentForm();
      case 'doctor_summary': return _buildDoctorSummary();
      case 'detail': return _buildDoctorSummary(); 
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Hello, Nurse", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const Text("Raipur Rural Clinic • Unit 4", style: TextStyle(fontSize: 14, color: Colors.grey)),
            ]),
            _buildProfileAvatar(),
          ],
        ),
        const SizedBox(height: 24),
        _buildStatCard(icon: LucideIcons.users, label: "Total Patients", value: "48", subValue: "5 Active", color: Colors.blue.shade50, iconColor: Colors.blue.shade600),
        const SizedBox(height: 16),
        _buildActionCard(),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _navigateTo('patient_search'),
          icon: const Icon(LucideIcons.userPlus, size: 20),
          label: const Text("New Patient Intake", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
        ),
        const SizedBox(height: 32),
        const Text("Upcoming Care Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._patients.take(3).map((p) => _buildPatientListTile(p)),
      ],
    );
  }

  Widget _buildPatientSearch() {
    final q = _patientSearchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _patients
        : _patients.where((p) {
            final name = (p['name'] ?? '').toString().toLowerCase();
            final id = (p['id'] ?? '').toString().toLowerCase();
            return name.contains(q) || id.contains(q);
          }).toList();

    return Column(
      children: [
        _buildHeader("Find Patient", onBack: () => _navigateTo('dashboard')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, color: TWColors.slate.shade400, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _patientSearchCtrl,
                        decoration: const InputDecoration(hintText: "Search by Patient Name or ID", border: InputBorder.none),
                        onChanged: (v) => setState(() => _patientSearchQuery = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("Search Results", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              ...filtered.map((p) {
                  final bool selected = _selectedPatient != null && _selectedPatient!['id'] == p['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPatient = p),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFF0FDFA) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? const Color(0xFF5EEAD4) : const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Icon(LucideIcons.user, size: 18, color: Color(0xFF0D9488))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text((p['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text((p['id'] ?? '').toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ]),
                          ),
                          if (selected) const Icon(LucideIcons.circleCheck, color: Color(0xFF0D9488), size: 18)
                          else Icon(LucideIcons.circle, color: TWColors.slate.shade300, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 120),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedPatient == null) return;
                  // Prepare profile for the follow-up case and navigate directly to camera
                  _patientProfile..clear()..addAll({
                    'patient_id': _selectedPatient?['id'],
                    'patient_name': _selectedPatient?['name'],
                    'age': _selectedPatient?['age'],
                    'gender': _selectedPatient?['gender'],
                  });
                  setState(() => _patientProfileSaved = true);
                  _navigateTo('camera');
                },
                icon: const Icon(LucideIcons.camera),
                label: const Text("Take Wound Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _patientProfile.clear(); _patientProfileSaved = false; _selectedPatient = null;
                  _patientNameCtrl.clear(); _dobCtrl.clear(); _occupationCtrl.clear(); _patientPhoneCtrl.clear();
                  _patientHeightCtrl.clear(); _patientWeightCtrl.clear(); _patientHistoryCtrl.clear();
                  _patientPhoto = null;
                  _navigateTo('intake');
                },
                icon: const Icon(LucideIcons.userPlus),
                label: const Text("Register New Patient", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0D9488), side: const BorderSide(color: Color(0xFF0D9488)), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntakeForm() {
    return Column(children: [
      _buildHeader("New Patient Intake", onBack: () => _navigateTo('patient_search')),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          _buildSectionTitle(LucideIcons.user, "Step 1: Patient Details"),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickPatientPhoto(ImageSource.camera),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.2), width: 3),
                    ),
                    child: _patientPhoto == null
                        ? Icon(LucideIcons.user, size: 48, color: TWColors.slate.shade300)
                        : ClipOval(child: Image.file(File(_patientPhoto!.path), fit: BoxFit.cover)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _pickPatientPhoto(ImageSource.camera),
                  icon: const Icon(LucideIcons.camera, size: 16),
                  label: Text(_patientPhoto == null ? "Capture Patient Image" : "Change Image", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildFormLabel("PATIENT NAME"),
          TextFormField(
            controller: _patientNameCtrl,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: _inputDeco(LucideIcons.userCheck, "Full name"),
          ),
          const SizedBox(height: 20),
          _buildFormLabel("DATE OF BIRTH"),
          TextFormField(
            controller: _dobCtrl,
            readOnly: true, 
            onTap: () => _selectDate(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: _inputDeco(LucideIcons.calendar, "Select Date"),
          ),
          const SizedBox(height: 20),
          _buildFormLabel("GENDER"),
          const SizedBox(height: 8),
          Row(
            children: [
              {'label': 'Male', 'icon': LucideIcons.mars},
              {'label': 'Female', 'icon': LucideIcons.venus},
              {'label': 'Other', 'icon': LucideIcons.user},
            ].map((gender) {
              final label = gender['label'] as String;
              final icon = gender['icon'] as IconData;
              bool isSelected = _selectedGender == label.toLowerCase();
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = label.toLowerCase()),
                  child: Container(
                    margin: EdgeInsets.only(right: label == "Other" ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.blueGrey.shade700),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.blueGrey.shade700)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildFormLabel("OCCUPATION"),
          TextFormField(controller: _occupationCtrl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), decoration: _inputDeco(LucideIcons.briefcase, "e.g. Software Engineer")),
          const SizedBox(height: 20),
          _buildFormLabel("PHONE NO"),
          TextFormField(controller: _patientPhoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), decoration: _inputDeco(LucideIcons.phone, "+91 00000 00000")),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel("HEIGHT (CM)"), TextFormField(controller: _patientHeightCtrl, decoration: _inputDeco(LucideIcons.ruler, "Height"))])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel("WEIGHT (KG)"), TextFormField(controller: _patientWeightCtrl, decoration: _inputDeco(LucideIcons.scale, "Weight"))])),
          ]),
          const SizedBox(height: 20),
          _buildFormLabel("MEDICAL HISTORY"),
          TextFormField(controller: _patientHistoryCtrl, decoration: _inputDeco(LucideIcons.clipboard, "Diabetes, etc.")),
          if (_patientProfileSaved) _buildSuccessBanner(),
          const SizedBox(height: 120),
        ]),
      ),
      _buildIntakeFooter(),
    ]);
  }

  Widget _buildResponseView() {
    final bool isFillin = _responseMode == 'fillin';
    return Column(
      children: [
        _buildHeader(isFillin ? "AI Extraction" : "Clinical Summary", onBack: () => isFillin ? _navigateTo('camera') : _navigateTo('assessment')),
        Expanded(
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(24), color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(LucideIcons.code, size: 18, color: Color(0xFF0D9488)), const SizedBox(width: 10), Text(isFillin ? "RAW JSON" : "RAW TEXT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1, color: Color(0xFF0D9488)))]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: SelectableText(_rawResponse ?? "No data available.", style: GoogleFonts.firaCode(fontSize: 13, color: Colors.blueGrey.shade800)),
                ),
              ]),
            ),
          ),
        ),
        isFillin ? _buildFixedBottomButton("Proceed to Checklist", LucideIcons.arrowRight, () => _navigateTo('assessment')) : _buildFixedBottomButton("Back to Dashboard", LucideIcons.house, () => _navigateTo('dashboard')),
      ],
    );
  }

  Widget _buildWoundAssessmentForm() {
    if (_aiExtraction != null && _reviewed.isEmpty) _reviewed.addAll(_aiExtraction!);
    return Column(
      children: [
        _buildHeader("Clinical Checklist", onBack: () => _navigateTo('response_view')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_aiExtraction != null) _buildAISuggestionBox(),
              _buildSectionTitle(LucideIcons.thermometer, "Vitals"),
              const SizedBox(height: 20),
              _buildTextField(label: "TEMPERATURE", placeholder: "e.g. 37", icon: LucideIcons.thermometer, keyboardType: const TextInputType.numberWithOptions(decimal: true), bindKey: 'temperature'),
              _buildTextField(label: "BLOOD PRESSURE", placeholder: "e.g. 120/80", icon: LucideIcons.droplet, bindKey: 'blood_pressure'),
              _buildTextField(label: "HEART RATE", placeholder: "0.0", icon: LucideIcons.heart, bindKey: 'heart_rate'),
              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.mapPin, "Anatomy & Location"),
              const SizedBox(height: 20),
              _buildDropdownField(label: "Primary Location", value: (_reviewed['location_primary'] ?? _aiExtraction?['location_primary'])?.toString(), options: ["toe", "sole", "side", "heel", "dorsal_aspect", "medial_malleolus", "lateral_malleolus"], bindKey: 'location_primary'),
              _buildTextField(label: "LOCATION DETAIL", placeholder: "e.g. 2nd metatarsal head", icon: LucideIcons.mapPin, bindKey: 'location_detail'),
              _buildTextField(label: "WOUND TYPE", placeholder: "e.g. ulcer", icon: LucideIcons.fileText, bindKey: 'wound_type'),
              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.maximize2, "Geometry & Shape"),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildDropdownField(label: "Shape", value: (_reviewed['shape'] ?? _aiExtraction?['shape'])?.toString(), options: ["round", "oval", "irregular", "linear", "punched_out"], bindKey: 'shape')),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdownField(label: "Depth Category", value: (_reviewed['depth_category'] ?? _aiExtraction?['depth_category'])?.toString(), options: ["superficial", "partial_thickness", "full_thickness", "deep", "very_deep_exposed_bone_tendon"], bindKey: 'depth_category')),
              ]),
              Row(children: [
                Expanded(child: _buildTextField(label: "WIDTH (CM)", placeholder: "0.0", icon: LucideIcons.maximize2, keyboardType: const TextInputType.numberWithOptions(decimal: true), bindKey: 'size_width_cm')),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: "LENGTH (CM)", placeholder: "0.0", icon: LucideIcons.maximize2, keyboardType: const TextInputType.numberWithOptions(decimal: true), bindKey: 'size_length_cm')),
              ]),
              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.chartPie, "Tissue Composition"),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildTextField(label: "BED SLOUGH %", placeholder: "0", icon: LucideIcons.percent, keyboardType: TextInputType.number, bindKey: 'bed_slough_pct')),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(label: "BED NECROTIC %", placeholder: "0", icon: LucideIcons.percent, keyboardType: TextInputType.number, bindKey: 'bed_necrotic_pct')),
              ]),
              _buildDropdownField(label: "Edge Description", value: (_reviewed['edge_description'] ?? _aiExtraction?['edge_description'])?.toString(), options: ["smooth", "thickened", "irregular", "rolled_epibole", "undermined", "calloused"], bindKey: 'edge_description'),
              _buildDropdownField(label: "Periwound Status", value: (_reviewed['periwound_status'] ?? _aiExtraction?['periwound_status'])?.toString(), options: ["normal", "erythematous", "edematous", "indurated", "macerated", "fluctuant", "hyperpigmented"], bindKey: 'periwound_status'),
              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.droplets, "Exudate & Sensation"),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildDropdownField(label: "Volume", value: (_reviewed['discharge_volume'] ?? _aiExtraction?['discharge_volume'])?.toString(), options: ["none", "minimal", "moderate", "heavy"], bindKey: 'discharge_volume')),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdownField(label: "Type", value: (_reviewed['discharge_type'] ?? _aiExtraction?['discharge_type'])?.toString(), options: ["serous (clear)", "sanguineous (bloody)", "serosanguineous (pink)", "purulent (yellow/pus)", "seropurulent (cloudy yellow)"], bindKey: 'discharge_type')),
              ]),
              _buildDropdownField(label: "Odor Presence", value: (_reviewed['odor_presence'] ?? _aiExtraction?['odor_presence'])?.toString(), options: ["none", "faint", "moderate", "foul", "putrid"], bindKey: 'odor_presence'),
              _buildTextField(label: "PAIN SCORE (0-10)", placeholder: "0", icon: LucideIcons.zap, keyboardType: TextInputType.number, bindKey: 'pain_score'),
              const SizedBox(height: 16),
              const Text("Clinical Flags", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [_buildChoiceChip("Has Infection", initialSelected: (_reviewed['has_infection'] ?? _aiExtraction?['has_infection']) == true, bindKey: 'has_infection')]),
              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.sun, "Skin Condition"),
              const SizedBox(height: 20),
              _buildDropdownField(label: "Overall Condition", value: (_reviewed['skin_condition'] ?? _aiExtraction?['skin_condition'])?.toString(), options: ["healthy", "dry", "cracked", "macerated", "fragile", "scaling"], bindKey: 'skin_condition'),
              const SizedBox(height: 120),
            ],
          ),
        ),
        _buildFixedBottomButton("Submit Assessment", LucideIcons.circleCheck, _submitToAnalyzeWound),
      ],
    );
  }

  Widget _buildDoctorSummary() {
    final data = _aiWoundJson;
    if (data == null) return const Center(child: Text("No clinical summary found for this case."));
    
    final ai = (data['AI_analysis'] is Map) ? Map<String, dynamic>.from(data['AI_analysis']) : <String, dynamic>{};
    final plan = (data['treatment_plan'] is Map) ? Map<String, dynamic>.from(data['treatment_plan']) : <String, dynamic>{};
    final tasks = (plan['plan_tasks'] is List) ? List<Map<String, dynamic>>.from(plan['plan_tasks']) : <Map<String, dynamic>>[];
        
    final confidence = ai['confidence'];
    final confPct = (confidence is num) ? (confidence * 100).round() : null;

    String fmtDue(String? iso) {
      if (iso == null || iso.isEmpty) return "TBD";
      try {
        final dt = DateTime.parse(iso).toLocal();
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      } catch (_) { return iso; }
    }

    return Column(
      children: [
        _buildHeader("Clinical Case Summary", onBack: () => _navigateTo('dashboard')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // WOUND IMAGES SECTION IN SUMMARY
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CLINICAL WOUND CAPTURE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  if (_capturedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(File(_capturedImage!.path), height: 220, width: double.infinity, fit: BoxFit.cover),
                    )
                  else if (_selectedPatient != null && _selectedPatient!['image'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _selectedPatient!['image'],
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(height: 220, color: const Color(0xFFF1F5F9), child: const Center(child: Icon(LucideIcons.image, color: Colors.grey))),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF5EEAD4))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(LucideIcons.stethoscope, color: Color(0xFF0D9488), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((ai['wound_stage'] ?? 'Wound Stage').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF134E4A))),
                    const SizedBox(height: 6),
                    Text(ai['diagnosis']?.toString() ?? "No diagnosis provided.", style: const TextStyle(fontSize: 12, color: Color(0xFF134E4A))),
                    if (confPct != null) ...[const SizedBox(height: 8), Text("Confidence: $confPct%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)))]
                  ])),
                ]),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle(LucideIcons.triangleAlert, "Clinical Urgency"),
              const SizedBox(height: 12),
              Row(
                 children: [
                   {'l': 'HIGH', 'v': 'high_urgent', 'c': Colors.red},
                   {'l': 'MEDIUM', 'v': 'medium', 'c': Colors.orange},
                   {'l': 'ROUTINE', 'v': 'routine', 'c': Color(0xFF0D9488)},
                 ].map((u) => Expanded(
                   child: GestureDetector(
                     onTap: _currentStep == 'doctor_summary' ? () => setState(() => _selectedUrgency = u['v'] as String) : null,
                     child: Container(
                       margin: EdgeInsets.only(right: u['l'] == 'ROUTINE' ? 0 : 8),
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       decoration: BoxDecoration(
                         color: _selectedUrgency == u['v'] ? u['c'] as Color : const Color(0xFFF8FAFC),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: _selectedUrgency == u['v'] ? u['c'] as Color : const Color(0xFFE2E8F0)),
                       ),
                       child: Center(child: Text(u['l'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _selectedUrgency == u['v'] ? Colors.white : Colors.blueGrey.shade700))),
                     ),
                   ),
                 )).toList(),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.clipboardCheck, "Nurse-Reviewed Data"),
              const SizedBox(height: 12),
              // Displaying all clinical fields
              _kv("Temperature", "${_reviewed['temperature'] ?? '-'} °C"),
              _kv("Blood Pressure", "${_reviewed['blood_pressure'] ?? '-'} mmHg"),
              _kv("Heart Rate", "${_reviewed['heart_rate'] ?? '-'} bpm"),
              _kv("Location Primary", _reviewed['location_primary']?.toString() ?? '-'),
              _kv("Location Detail", _reviewed['location_detail']?.toString() ?? '-'),
              _kv("Wound Type", _reviewed['wound_type']?.toString() ?? '-'),
              _kv("Shape", _reviewed['shape']?.toString() ?? '-'),
              _kv("Width / Length", "${_reviewed['size_width_cm'] ?? '-'} cm / ${_reviewed['size_length_cm'] ?? '-'} cm"),
              _kv("Depth Category", _reviewed['depth_category']?.toString() ?? '-'),
              _kv("Bed Slough %", "${_reviewed['bed_slough_pct'] ?? '-'}%"),
              _kv("Bed Necrotic %", "${_reviewed['bed_necrotic_pct'] ?? '-'}%"),
              _kv("Edge Description", _reviewed['edge_description']?.toString() ?? '-'),
              _kv("Periwound Status", _reviewed['periwound_status']?.toString() ?? '-'),
              _kv("Discharge Volume", _reviewed['discharge_volume']?.toString() ?? '-'),
              _kv("Discharge Type", _reviewed['discharge_type']?.toString() ?? '-'),
              _kv("Odor Presence", _reviewed['odor_presence']?.toString() ?? '-'),
              _kv("Pain Score", "${_reviewed['pain_score'] ?? '-'}/10"),
              _kv("Has Infection", (_reviewed['has_infection'] == true) ? "YES" : "NO"),
              _kv("Skin Condition", _reviewed['skin_condition']?.toString() ?? '-'),

              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.fileText, "AI Narrative"),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))), child: Text(ai['description']?.toString() ?? "No description provided.", style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3))),
              
              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.bandage, "Treatment Plan"),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))), child: Text(plan['plan_text']?.toString() ?? ai['treatment_plan']?.toString() ?? "No plan provided.", style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3))),
              
              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.listTodo, "Task List"),
              const SizedBox(height: 12),
              ...tasks.map((t) => Container(
                    margin: const EdgeInsets.only(bottom: 10), 
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1F5F9))), 
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.squareCheck, size: 16, color: Color(0xFF0D9488)), 
                        const SizedBox(width: 10), 
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t['task_text']?.toString() ?? "(task)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text("Due: ${fmtDue(t['task_due']?.toString())} • ${t['status'] ?? 'Pending'}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        ])),
                      ],
                    ),
                  )),
              const SizedBox(height: 120),
            ],
          ),
        ),
        if (_currentStep == 'doctor_summary')
          _buildFixedBottomButton("Send to Doctor", LucideIcons.send, _sendToDoctor)
        else
          _buildFixedBottomButton("Back to Dashboard", LucideIcons.house, () => _navigateTo('dashboard')),
      ],
    );
  }

  Widget _buildTasksTab() {
    // Flatten tasks from all patients for combined view
    List<Map<String, dynamic>> allTasks = [];
    for (var p in _patients) {
      final aiJson = p['ai_wound_json'];
      if (aiJson != null) {
        final plan = aiJson['treatment_plan'];
        if (plan != null && plan['plan_tasks'] != null) {
          for (var t in plan['plan_tasks']) {
            allTasks.add({
              ...t,
              'patient_name': p['name'],
              'patient_id': p['id'],
            });
          }
        }
      }
    }

    String fmtDue(String? iso) {
      if (iso == null || iso.isEmpty) return "TBD";
      try {
        final dt = DateTime.parse(iso).toLocal();
        return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) { return iso; }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Care Tasks", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            Text("${allTasks.length} Active Clinical Tasks", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ]),
        ),
        // Filter bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildFilterChip("All Tasks", true),
              const SizedBox(width: 8),
              _buildFilterChip("Urgent", false),
              const SizedBox(width: 8),
              _buildFilterChip("Pending", false),
              const SizedBox(width: 8),
              _buildFilterChip("Completed", false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              final task = allTasks[index];
              final isUrgent = task['status'] == 'Urgent';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isUrgent ? Colors.red.withOpacity(0.2) : const Color(0xFFF1F5F9)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red.shade50 : const Color(0xFFF0FDFA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUrgent ? LucideIcons.triangleAlert : LucideIcons.circleCheck,
                        size: 20,
                        color: isUrgent ? Colors.red : const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(task['patient_name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text(fmtDue(task['task_due']), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(task['task_text'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUrgent ? Colors.red.shade50 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task['status'].toString().toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : Colors.blueGrey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 16, color: TWColors.slate.shade300),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.blueGrey)),
    );
  }

  Widget _buildCasesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Patient Cases", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const Text("Raipur Unit 4 progress", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _patients.length,
            itemBuilder: (context, index) => _buildPatientListTile(_patients[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() => ListView(padding: const EdgeInsets.all(24), children: [Center(child: Column(children: [_buildProfileAvatar(), const SizedBox(height: 16), const Text("Nurse Ananya Sharma", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const Text("Registered Nurse • Senior Lead", style: TextStyle(color: Colors.grey))])), const SizedBox(height: 40), _buildProfileTile(LucideIcons.user, "Personal Information"), _buildProfileTile(LucideIcons.shieldCheck, "Security & Pin"), _buildProfileTile(LucideIcons.settings, "App Settings"), _buildProfileTile(LucideIcons.logOut, "Logout", color: Colors.redAccent)]);

  Widget _buildARCamera() {
    return Container(
      color: Colors.black,
      child: Stack(children: [
        Center(child: Container(width: 280, height: 280, decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 2), borderRadius: BorderRadius.circular(32)), child: const Center(child: Text("ALIGN WOUND", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2))))),
        Positioned(top: 20, left: 20, right: 20, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [CircleAvatar(backgroundColor: Colors.black38, child: IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => _navigateTo('dashboard'))), ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(LucideIcons.folderOpen, size: 16), label: const Text("BROWSE"), style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, shape: const StadiumBorder()))])),
        Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 60), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("LIGHTING OPTIMAL", style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)), const SizedBox(height: 20), InkWell(onTap: () => _pickImage(ImageSource.camera), child: Container(width: 84, height: 84, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)), child: Center(child: Container(width: 68, height: 68, decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle)))))]))),
      ]),
    );
  }

  // Helpers
  Widget _buildFormLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))));
  InputDecoration _inputDeco(IconData icon, String hint) => InputDecoration(prefixIcon: Icon(icon, size: 20, color: TWColors.slate.shade400), hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
  Widget _buildSuccessBanner() => Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF5EEAD4))), child: const Row(children: [Icon(LucideIcons.circleCheck, size: 16, color: Color(0xFF0D9488)), SizedBox(width: 8), Text("Profile saved.", style: TextStyle(fontSize: 12, color: Color(0xFF134E4A), fontWeight: FontWeight.bold))]));
  Widget _buildIntakeFooter() => Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))), child: Column(children: [ElevatedButton.icon(onPressed: _savePatientProfile, icon: const Icon(LucideIcons.save), label: const Text("Save Profile"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))), const SizedBox(height: 12), ElevatedButton.icon(onPressed: _patientProfileSaved ? () => _navigateTo('camera') : null, icon: const Icon(LucideIcons.camera), label: const Text("Take Wound Photo"), style: ElevatedButton.styleFrom(backgroundColor: _patientProfileSaved ? const Color(0xFF0D9488) : TWColors.slate.shade300, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))]));

  Widget _buildTextField({required String label, required String placeholder, IconData? icon, String? initialValue, TextInputType keyboardType = TextInputType.text, String? bindKey}) {
    final TextEditingController? controller = bindKey == null ? null : _ctrl(bindKey, initial: initialValue ?? '');
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))), const SizedBox(height: 8), TextFormField(controller: controller, keyboardType: keyboardType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), onChanged: (v) { if (bindKey != null) _reviewed[bindKey] = v; }, decoration: _inputDeco(icon ?? LucideIcons.fileText, placeholder))]));
  }

  Widget _buildDropdownField({required String label, required List<String> options, String? value, String? bindKey}) {
    final String? effectiveValue = _coerceEnum(value, options);
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))), const SizedBox(height: 8), DropdownButtonFormField<String>(isExpanded: true, key: ValueKey('drop_${label}_${effectiveValue ?? 'none'}'), value: effectiveValue, decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), items: options.map((s) => DropdownMenuItem<String>(value: s, child: Text(s.replaceAll('_', ' '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(), onChanged: (v) { if (bindKey != null) _reviewed[bindKey] = v; })]));
  }

  Widget _buildChoiceChip(String label, {bool initialSelected = false, String? bindKey}) {
    bool selected = initialSelected;
    return StatefulBuilder(builder: (context, setLocal) {
      return FilterChip(label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), selected: selected, onSelected: (b) { setLocal(() => selected = b); if (bindKey != null) _reviewed[bindKey] = b; }, selectedColor: const Color(0xFF0D9488).withOpacity(0.2), checkmarkColor: const Color(0xFF0D9488), backgroundColor: const Color(0xFFF8FAFC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none));
    });
  }

  // Static UI Blocks
  Widget _buildStatCard({required IconData icon, required String label, required String value, required String subValue, required Color color, required Color iconColor}) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))])), Text(subValue, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor))]));
  Widget _buildActionCard() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(24)), child: const Row(children: [Icon(LucideIcons.listTodo, color: Colors.white), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("12", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), Text("TASKS FOR TODAY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70))])), Icon(LucideIcons.chevronRight, color: Colors.white70)]));
  Widget _buildProfileAvatar() => Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(14)), child: const Center(child: Text("RN", style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold))));
  Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 140, child: Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(child: Text(v.isEmpty ? "-" : v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))))]));
  Widget _buildAISuggestionBox() => Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF5EEAD4))), child: Row(children: [const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF0D9488)), const SizedBox(width: 8), Expanded(child: Text("Analysis successful. Please verify clinical data.", style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF134E4A))))]));
  Widget _buildAnalysisOverlay() => Container(color: Colors.black.withOpacity(0.9), width: double.infinity, height: double.infinity, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: Color(0xFF0D9488), strokeWidth: 5)), const SizedBox(height: 32), const Icon(LucideIcons.sparkles, color: Color(0xFF0D9488), size: 32), const SizedBox(height: 16), Text("GEMINI CLOUD", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 12)), const SizedBox(height: 12), const Text("Analyzing...", style: TextStyle(color: Colors.white70, fontSize: 14))]));
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