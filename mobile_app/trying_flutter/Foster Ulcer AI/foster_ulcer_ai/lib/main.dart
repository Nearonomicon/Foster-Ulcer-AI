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
    super.dispose();
  }
  // ✅ Track which response is currently shown
  // - "fillin" => JSON detail from /analyze-fillin
  // - "analysis" => free-text from /analyze-wound
  String _responseMode = 'fillin';

  // ✅ Controllers to ensure prefill works reliably (initialValue only applies once)
  final Map<String, TextEditingController> _controllers = {};
  TextEditingController _ctrl(String key, {String initial = ""}) {
    return _controllers.putIfAbsent(key, () => TextEditingController(text: initial));
  }

  void _applyPrefillControllersFromReviewed() {
    const keys = [
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

  // Navigation & UI State
  String _currentStep = 'dashboard';
  int _activeTab = 0;
  Map<String, dynamic>? _selectedPatient;
  bool _isAnalyzing = false;
  XFile? _capturedImage;

  // Response view
  String? _rawResponse;
  Map<String, dynamic>? _aiExtraction;

  // ✅ NEW: store /analyze-wound JSON result (doctor-facing summary)
  Map<String, dynamic>? _aiWoundJson;

  // ✅ NEW: store nurse-reviewed values from checklist
  final Map<String, dynamic> _reviewed = {};

  // ✅ Android Emulator -> PC localhost
  static const String _baseUrl = "http://10.0.2.2:8000";

  // ✅ FastAPI endpoints
  final Uri _fillinUri = Uri.parse("$_baseUrl/analyze-fillin");
  final Uri _analyzeWoundUri = Uri.parse("$_baseUrl/analyze-wound");
  final Uri _docsUri = Uri.parse("$_baseUrl/docs");

  // Mock Clinical Data
  final List<Map<String, dynamic>> _patients = [
    {
      "id": "PT-1002",
      "name": "John Smith",
      "age": 68,
      "gender": "Male",
      "stage": "Wagner 3",
      "priority": "Critical",
      "status": "Pending Review",
      "date": "Just now",
      "image": "https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?w=800",
      "todos": [
        {"task": "Clean wound with saline", "completed": true, "due": "Completed", "urgent": false},
        {"task": "Apply antimicrobial dressing", "completed": false, "due": "Today, 4:00 PM", "urgent": true},
      ],
    },
    {
      "id": "PT-3091",
      "name": "Rahul Sharma",
      "age": 71,
      "gender": "Male",
      "stage": "Wagner 4",
      "priority": "Critical",
      "status": "Pending Review",
      "date": "2 hours ago",
      "image": "https://images.unsplash.com/photo-1584036533827-45bce166549a?w=800",
      "todos": [
        {"task": "Prepare for surgical referral", "completed": false, "due": "ASAP", "urgent": true},
      ],
    }
  ];

  // --- Helpers: parse analysis ---
  Map<String, dynamic>? _parseAnalysis(dynamic analysisData) {
    if (analysisData == null) return null;

    if (analysisData is Map<String, dynamic>) return analysisData;
    if (analysisData is Map) return Map<String, dynamic>.from(analysisData);

    if (analysisData is String) {
      try {
        var s = analysisData.trim();
        // Gemini sometimes wraps JSON in code fences
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

  // ✅ Make dropdown prefill robust (model sometimes returns spaces/hyphens)
  String? _coerceEnum(String? v, List<String> options) {
    if (v == null) return null;
    if (options.contains(v)) return v;

    final raw = v.toString().trim().toLowerCase();
    final normalized = raw
        .replaceAll(RegExp(r"\\s+"), "_")
        .replaceAll('-', '_')
        .replaceAll(RegExp(r"_+"), "_");

    for (final opt in options) {
      final o = opt.toLowerCase();
      if (o == raw || o == normalized) return opt;
    }

    // last try: ignore underscores
    final compact = normalized.replaceAll('_', '');
    for (final opt in options) {
      final o = opt.toLowerCase().replaceAll('_', '');
      if (o == compact) return opt;
    }

    return null;
  }


  Future<void> _pickImage(ImageSource source) async {
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

  // ✅ Step 1: POST /analyze-fillin (returns {status, detail:{...}})
  Future<void> _uploadAndAnalyzeFillin(XFile imageFile) async {
    setState(() => _isAnalyzing = true);

    try {
      final request = http.MultipartRequest('POST', _fillinUri);

      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      debugPrint("DEBUG: POST $_fillinUri");
      debugPrint("DEBUG: STATUS: ${response.statusCode}");
      debugPrint("DEBUG: BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }

      final Map<String, dynamic> body = json.decode(response.body);

      // Your backend returns: {"status":"success", "analysis": "{...json...}"}
      if (body.containsKey('analysis')) {
        final analysisData = body['analysis'];
        final extracted = _parseAnalysis(analysisData);

        setState(() {
          _responseMode = 'fillin';
          _aiExtraction = extracted;
          _rawResponse = const JsonEncoder.withIndent('  ').convert(extracted ?? analysisData);

          // ✅ initialize reviewed values from AI extraction
          _reviewed
            ..clear()
            ..addAll(extracted ?? {});
        });

        // ✅ make sure controllers are populated (reliable prefill)
        _applyPrefillControllersFromReviewed();
      } else {
        // fallback: show entire body
        setState(() {
          _aiExtraction = null;
          _rawResponse = const JsonEncoder.withIndent('  ').convert(body);
          _reviewed.clear();
        });
      }

      _navigateTo('response_view');
    } catch (e) {
      debugPrint("Network/Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      _navigateTo('assessment');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // ✅ Step 2: POST /analyze-wound with patient_data + image
  Future<void> _submitToAnalyzeWound() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No wound photo found. Please take a photo again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final request = http.MultipartRequest('POST', _analyzeWoundUri);

      // patient_data must be Form field string
      final payload = Map<String, dynamic>.from(_reviewed);
      payload['source'] = 'flutter_demo';

      request.fields['patient_data'] = jsonEncode(payload);

      // attach same photo again
      final bytes = await _capturedImage!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _capturedImage!.name,
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      debugPrint("DEBUG: POST $_analyzeWoundUri");
      debugPrint("DEBUG: STATUS: ${response.statusCode}");
      debugPrint("DEBUG: BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }

      final Map<String, dynamic> body = jsonDecode(response.body);

      // backend returns {status:'success', analysis:'...'}
      if (body['status'] == 'success' && body.containsKey('analysis')) {
        final analysisVal = body['analysis'];
        final parsed = _parseAnalysis(analysisVal);

        // ✅ If analysis is JSON (doctor summary), show Summary page
        if (parsed != null && (parsed.containsKey('AI_analysis') || parsed.containsKey('treatment_plan'))) {
          setState(() {
            _aiWoundJson = parsed;
          });
          _navigateTo('doctor_summary');
          return;
        }

        // Otherwise, treat as free-text (old behavior)
        setState(() {
          _responseMode = 'analysis';
          _rawResponse = analysisVal?.toString();
          _aiExtraction = null;
          _aiWoundJson = null;
        });
        _navigateTo('response_view');
      } else {
        throw Exception("Unexpected response: ${response.body}");
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submit failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _navigateTo(String step, {Map<String, dynamic>? patient}) {
    setState(() {
      _currentStep = step;
      if (patient != null) _selectedPatient = patient;
    });
  }

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

  bool _shouldShowNav() => ['dashboard', 'tasks', 'cases'].contains(_currentStep);

  Widget _buildCurrentStep() {
    if (_currentStep == 'dashboard') {
      switch (_activeTab) {
        case 0:
          return _buildDashboard();
        case 1:
          return _buildTasksTab();
        case 2:
          return _buildCasesTab();
        case 3:
          return _buildProfileTab();
        default:
          return _buildDashboard();
      }
    }

    switch (_currentStep) {
      case 'intake':
        return _buildIntakeForm();
      case 'camera':
        return _buildARCamera();
      case 'response_view':
        return _buildResponseView();
      case 'assessment':
        return _buildWoundAssessmentForm();
      case 'doctor_summary':
        return _buildDoctorSummary();
      case 'detail':
        return _buildPatientDetail();
      default:
        return _buildDashboard();
    }
  }

  // --- RESPONSE VIEW PAGE ---
  Widget _buildResponseView() {
    final bool isFillin = _responseMode == 'fillin';

    return Column(
      children: [
        _buildHeader(
          isFillin ? "AI Extraction (Fill-in JSON)" : "AI Clinical Summary (Analyze Wound)",
          onBack: () => isFillin ? _navigateTo('camera') : _navigateTo('assessment'),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.code, size: 18, color: Color(0xFF0D9488)),
                      const SizedBox(width: 10),
                      Text(
                        isFillin ? "RAW JSON" : "RAW TEXT",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SelectableText(
                      _rawResponse ?? "No data available.",
                      style: GoogleFonts.firaCode(fontSize: 13, color: Colors.blueGrey.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tip: Open docs in emulator browser: $_docsUri",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isFillin
                        ? "Verify the extracted fields. Proceed to edit/confirm the checklist."
                        : "This is an AI-generated clinical summary. Verify with a licensed clinician.",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        isFillin
            ? _buildFixedBottomButton("Proceed to Checklist", LucideIcons.arrowRight, () => _navigateTo('assessment'))
            : _buildFixedBottomButton("Back to Dashboard", LucideIcons.house, () => _navigateTo('dashboard')),
      ],
    );
  }

  // --- WOUND ASSESSMENT FORM ---
  Widget _buildWoundAssessmentForm() {
    // ✅ make sure reviewed has baseline even if user enters assessment directly
    if (_aiExtraction != null && _reviewed.isEmpty) {
      _reviewed.addAll(_aiExtraction!);
    }

    return Column(
      children: [
        _buildHeader("Clinical Checklist", onBack: () => _navigateTo('response_view')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_aiExtraction != null) _buildAISuggestionBox(),

              _buildSectionTitle(LucideIcons.mapPin, "Anatomy & Location"),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: "Primary Location",
                value: (_reviewed['location_primary'] ?? _aiExtraction?['location_primary'])?.toString(),
                options: ["toe", "sole", "side", "heel", "dorsal_aspect", "medial_malleolus", "lateral_malleolus"],
                bindKey: 'location_primary',
              ),
              _buildTextField(
                label: "LOCATION DETAIL",
                placeholder: "e.g. 2nd metatarsal head",
                icon: LucideIcons.mapPin,
                initialValue: (_reviewed['location_detail'] ?? _aiExtraction?['location_detail'])?.toString(),
                bindKey: 'location_detail',
              ),
              _buildTextField(
                label: "WOUND TYPE",
                placeholder: "e.g. ulcer",
                icon: LucideIcons.fileText,
                initialValue: (_reviewed['wound_type'] ?? _aiExtraction?['wound_type'])?.toString(),
                bindKey: 'wound_type',
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.maximize2, "Geometry & Shape"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: "Shape",
                      value: (_reviewed['shape'] ?? _aiExtraction?['shape'])?.toString(),
                      options: ["round", "oval", "irregular", "linear", "punched_out"],
                      bindKey: 'shape',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      label: "Depth Category",
                      value: (_reviewed['depth_category'] ?? _aiExtraction?['depth_category'])?.toString(),
                      options: ["superficial", "partial_thickness", "full_thickness", "deep", "very_deep_exposed_bone_tendon"],
                      bindKey: 'depth_category',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "WIDTH (CM)",
                      placeholder: "0.0",
                      icon: LucideIcons.maximize2,
                      initialValue: (_reviewed['size_width_cm'] ?? _aiExtraction?['size_width_cm'])?.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      bindKey: 'size_width_cm',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: "LENGTH (CM)",
                      placeholder: "0.0",
                      icon: LucideIcons.maximize2,
                      initialValue: (_reviewed['size_length_cm'] ?? _aiExtraction?['size_length_cm'])?.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      bindKey: 'size_length_cm',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.chartPie, "Tissue Composition"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "BED SLOUGH %",
                      placeholder: "0",
                      icon: LucideIcons.percent,
                      initialValue: (_reviewed['bed_slough_pct'] ?? _aiExtraction?['bed_slough_pct'])?.toString(),
                      keyboardType: TextInputType.number,
                      bindKey: 'bed_slough_pct',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: "BED NECROTIC %",
                      placeholder: "0",
                      icon: LucideIcons.percent,
                      initialValue: (_reviewed['bed_necrotic_pct'] ?? _aiExtraction?['bed_necrotic_pct'])?.toString(),
                      keyboardType: TextInputType.number,
                      bindKey: 'bed_necrotic_pct',
                    ),
                  ),
                ],
              ),
              _buildDropdownField(
                label: "Edge Description",
                value: (_reviewed['edge_description'] ?? _aiExtraction?['edge_description'])?.toString(),
                options: ["smooth", "thickened", "irregular", "rolled_epibole", "undermined", "calloused"],
                bindKey: 'edge_description',
              ),
              _buildDropdownField(
                label: "Periwound Status",
                value: (_reviewed['periwound_status'] ?? _aiExtraction?['periwound_status'])?.toString(),
                options: ["normal", "erythematous", "edematous", "indurated", "macerated", "fluctuant", "hyperpigmented"],
                bindKey: 'periwound_status',
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.droplets, "Exudate & Sensation"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: "Volume",
                      value: (_reviewed['discharge_volume'] ?? _aiExtraction?['discharge_volume'])?.toString(),
                      options: ["none", "minimal", "moderate", "heavy"],
                      bindKey: 'discharge_volume',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      label: "Type",
                      value: (_reviewed['discharge_type'] ?? _aiExtraction?['discharge_type'])?.toString(),
                      options: ["serous", "sanguineous", "serosanguineous", "purulent", "seropurulent"],
                      bindKey: 'discharge_type',
                    ),
                  ),
                ],
              ),
              _buildDropdownField(
                label: "Odor Presence",
                value: (_reviewed['odor_presence'] ?? _aiExtraction?['odor_presence'])?.toString(),
                options: ["none", "faint", "moderate", "foul", "putrid"],
                bindKey: 'odor_presence',
              ),
              _buildTextField(
                label: "PAIN SCORE (0-10)",
                placeholder: "0",
                icon: LucideIcons.zap,
                initialValue: (_reviewed['pain_score'] ?? _aiExtraction?['pain_score'])?.toString(),
                keyboardType: TextInputType.number,
                bindKey: 'pain_score',
              ),

              const SizedBox(height: 16),
              const Text(
                "Clinical Flags",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoiceChip(
                    "Has Infection",
                    initialSelected: (_reviewed['has_infection'] ?? _aiExtraction?['has_infection']) == true,
                    bindKey: 'has_infection',
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(LucideIcons.sun, "Skin Condition"),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: "Overall Condition",
                value: (_reviewed['skin_condition'] ?? _aiExtraction?['skin_condition'])?.toString(),
                options: ["healthy", "dry", "cracked", "macerated", "fragile", "scaling"],
                bindKey: 'skin_condition',
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),

        // ✅ Submit now calls /analyze-wound (demo)
        _buildFixedBottomButton(
          "Submit (Demo)",
          LucideIcons.circleCheck,
          _submitToAnalyzeWound,
        ),
      ],
    );
  }

  // --- DOCTOR SUMMARY PAGE (after /analyze-wound JSON) ---
  Widget _buildDoctorSummary() {
    final data = _aiWoundJson;
    if (data == null) {
      return Column(
        children: [
          _buildHeader("Doctor Summary", onBack: () => _navigateTo('assessment')),
          const Expanded(
            child: Center(child: Text("No summary data found. Please submit again.")),
          ),
        ],
      );
    }

    final ai = (data['AI_analysis'] is Map)
        ? Map<String, dynamic>.from(data['AI_analysis'])
        : <String, dynamic>{};
    final plan = (data['treatment_plan'] is Map)
        ? Map<String, dynamic>.from(data['treatment_plan'])
        : <String, dynamic>{};
    final tasks = (plan['plan_tasks'] is List)
        ? List<Map<String, dynamic>>.from(plan['plan_tasks'])
        : <Map<String, dynamic>>[];

    String fmtDue(String? iso) {
      if (iso == null) return "";
      try {
        final dt = DateTime.parse(iso).toLocal();
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm";
      } catch (_) {
        return iso;
      }
    }

    final confidence = ai['confidence'];
    final confPct = (confidence is num) ? (confidence * 100).round() : null;

    return Column(
      children: [
        _buildHeader("Summary Before Sending to Doctor", onBack: () => _navigateTo('assessment')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_capturedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_capturedImage!.path),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 180,
                      color: const Color(0xFFE2E8F0),
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF5EEAD4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.stethoscope, color: Color(0xFF0D9488), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (ai['wound_stage'] ?? 'Wound Stage').toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF134E4A)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ai['diagnosis']?.toString() ?? "No diagnosis provided.",
                            style: const TextStyle(fontSize: 12, color: Color(0xFF134E4A)),
                          ),
                          if (confPct != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Confidence: $confPct%",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                            ),
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.clipboardCheck, "Nurse-Reviewed Data"),
              const SizedBox(height: 12),
              _kv("Location", (_reviewed['location_primary'] ?? '').toString()),
              _kv("Location detail", (_reviewed['location_detail'] ?? '').toString()),
              _kv("Wound type", (_reviewed['wound_type'] ?? '').toString()),
              _kv("Size", "${_reviewed['size_width_cm'] ?? ''} × ${_reviewed['size_length_cm'] ?? ''} cm"),
              _kv("Depth", (_reviewed['depth_category'] ?? '').toString()),
              _kv("Slough / Necrotic", "${_reviewed['bed_slough_pct'] ?? ''}% / ${_reviewed['bed_necrotic_pct'] ?? ''}%"),
              _kv("Discharge", "${_reviewed['discharge_volume'] ?? ''} / ${_reviewed['discharge_type'] ?? ''}"),
              _kv("Odor", (_reviewed['odor_presence'] ?? '').toString()),
              _kv("Pain score", (_reviewed['pain_score'] ?? '').toString()),
              _kv("Infection flag", ((_reviewed['has_infection'] ?? false) == true) ? "Yes" : "No"),

              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.fileText, "AI Narrative"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  ai['description']?.toString() ?? "No description provided.",
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.bandage, "Treatment Plan"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  plan['plan_text']?.toString() ?? ai['treatment_plan']?.toString() ?? "No plan provided.",
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.listTodo, "Task List"),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const Text("No tasks provided.", style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                ...tasks.map((t) {
                  final txt = t['task_text']?.toString() ?? "(task)";
                  final due = fmtDue(t['task_due']?.toString());
                  final status = t['status']?.toString() ?? "";
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.squareCheck, size: 16, color: Color(0xFF0D9488)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(txt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                due.isEmpty ? status : "Due: $due • $status",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 10),
              if (plan['followup_days'] != null)
                Text(
                  "Suggested follow-up: ${plan['followup_days']} day(s)",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                ),

              const SizedBox(height: 18),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text("Raw JSON (for audit)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(data),
                      style: GoogleFonts.firaCode(fontSize: 12, color: Colors.blueGrey.shade800),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  "Disclaimer: This summary is AI-generated and must be verified by a licensed medical professional before use.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
        _buildFixedBottomButton(
          "Send to Doctor (Demo)",
          LucideIcons.send,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Submitted to doctor (demo)."), backgroundColor: Color(0xFF0D9488)),
            );
            setState(() {
              _aiWoundJson = null;
              _responseMode = 'fillin';
            });
            _navigateTo('dashboard');
          },
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v.isEmpty ? "-" : v,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI building blocks ---
  Widget _buildAISuggestionBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5EEAD4)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF0D9488)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Analysis successful. Please verify the pre-filled clinical data before submitting.",
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF134E4A)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  // ✅ Updated: bindKey + controller-based prefill (reliable)
  Widget _buildTextField({
    required String label,
    required String placeholder,
    IconData? icon,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    String? bindKey,
  }) {
    final TextEditingController? controller = bindKey == null ? null : _ctrl(bindKey, initial: initialValue ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          onChanged: (v) {
            if (bindKey != null) _reviewed[bindKey] = v;
          },
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: TWColors.slate.shade400) : null,
            hintText: placeholder,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ]),
    );
  }

  // ✅ Updated: bindKey + onChanged stores to _reviewed
  Widget _buildDropdownField({
    required String label,
    required List<String> options,
    String? value,
    String? bindKey,
  }) {
    final String? effectiveValue = _coerceEnum(value, options);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            key: ValueKey('drop_${label}_${effectiveValue ?? 'none'}'),
            value: effectiveValue,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            selectedItemBuilder: (context) {
              return options.map((s) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.replaceAll('_', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList();
            },
            items: options.map((s) {
              return DropdownMenuItem<String>(
                value: s,
                child: Text(
                  s.replaceAll('_', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (bindKey != null) _reviewed[bindKey] = v;
            },
          ),
        ),
      ]),
    );
  }

  // ✅ Updated: stateful chip stores to _reviewed
  Widget _buildChoiceChip(String label, {bool initialSelected = false, String? bindKey}) {
    bool selected = initialSelected;

    return StatefulBuilder(
      builder: (context, setLocal) {
        return FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          selected: selected,
          onSelected: (b) {
            setLocal(() => selected = b);
            if (bindKey != null) _reviewed[bindKey] = b;
          },
          selectedColor: const Color(0xFF0D9488).withOpacity(0.2),
          checkmarkColor: const Color(0xFF0D9488),
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
        );
      },
    );
  }

  Widget _buildAnalysisOverlay() {
    return Container(
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
          Text("GEMINI CLOUD", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 12)),
          const SizedBox(height: 12),
          const Text("Analyzing...", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  // --- Remaining UI (unchanged from your file) ---
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
          onPressed: () => _navigateTo('intake'),
          icon: const Icon(LucideIcons.userPlus, size: 20),
          label: const Text("New Patient Intake", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
        ),
        const SizedBox(height: 32),
        const Text("Upcoming Care Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._patients.take(2).map((p) => _buildPatientListTile(p)),
      ],
    );
  }

  Widget _buildIntakeForm() {
    return Column(children: [
      _buildHeader("New Patient Intake", onBack: () => _navigateTo('dashboard')),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          _buildSectionTitle(LucideIcons.user, "Step 1: Patient Details"),
          const SizedBox(height: 24),
          _buildTextField(label: "HN (HOSPITAL NUMBER)", placeholder: "e.g. HN-12345", icon: LucideIcons.hash),
          _buildTextField(label: "PATIENT NAME", placeholder: "Full name", icon: LucideIcons.userCheck),
          _buildTextField(label: "PHONE NO", placeholder: "+91 00000 00000", icon: LucideIcons.phone, keyboardType: TextInputType.phone),
          Row(children: [
            Expanded(child: _buildTextField(label: "HEIGHT (CM)", placeholder: "175", icon: LucideIcons.ruler, keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField(label: "WEIGHT (KG)", placeholder: "70", icon: LucideIcons.scale, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 40),
        ]),
      ),
      _buildFixedBottomButton("Take Wound Photo", LucideIcons.camera, () => _navigateTo('camera')),
    ]);
  }

  Widget _buildARCamera() {
    return Container(
      color: Colors.black,
      child: Stack(children: [
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 2), borderRadius: BorderRadius.circular(32)),
            child: const Center(child: Text("ALIGN WOUND", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2))),
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            CircleAvatar(
              backgroundColor: Colors.black38,
              child: IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => _navigateTo('intake')),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(LucideIcons.folderOpen, size: 16),
              label: const Text("BROWSE"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, shape: const StadiumBorder()),
            )
          ]),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("LIGHTING OPTIMAL", style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                  child: Center(child: Container(width: 68, height: 68, decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle))),
                ),
              ),
            ]),
          ),
        )
      ]),
    );
  }

  Widget _buildTasksTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Care Tasks", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const Text("Priority care list for Raipur Clinic", style: TextStyle(fontSize: 14, color: Colors.grey))
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _patients.length,
          itemBuilder: (context, index) {
            final p = _patients[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Column(
                children: (p['todos'] as List).map((todo) {
                  return ListTile(
                    title: Text(todo['task'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(todo['due'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    trailing: Icon(todo['completed'] ? LucideIcons.circleCheck : LucideIcons.circle, color: todo['completed'] ? Colors.teal : Colors.grey),
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildCasesTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Patient Cases", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const Text("Unit 4 Clinical Progress", style: TextStyle(fontSize: 14, color: Colors.grey))
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _patients.length,
          itemBuilder: (context, index) => _buildPatientListTile(_patients[index]),
        ),
      ),
    ]);
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              _buildProfileAvatar(),
              const SizedBox(height: 16),
              const Text("Nurse Ananya Sharma", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text("Registered Nurse • Senior Lead", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildProfileTile(LucideIcons.user, "Personal Information"),
        _buildProfileTile(LucideIcons.shieldCheck, "Security & Pin"),
        _buildProfileTile(LucideIcons.settings, "App Settings"),
        _buildProfileTile(LucideIcons.logOut, "Logout", color: Colors.redAccent),
      ],
    );
  }

  Widget _buildProfileTile(IconData icon, String label, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF0D9488)),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16),
    );
  }

  Widget _buildHeader(String title, {required VoidCallback onBack}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: onBack),
          const SizedBox(width: 8),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 20, color: const Color(0xFF0D9488)),
      const SizedBox(width: 10),
      Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)))),
    ]);
  }

  Widget _buildFixedBottomButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(14)),
      child: const Center(child: Text("RN", style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required String subValue, required Color color, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 24)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ]),
        ),
        Text(subValue, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor)),
      ]),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(24)),
      child: const Row(children: [
        Icon(LucideIcons.listTodo, color: Colors.white),
        SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("12", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("TASKS FOR TODAY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
          ]),
        ),
        Icon(LucideIcons.chevronRight, color: Colors.white70)
      ]),
    );
  }

  Widget _buildPatientListTile(Map<String, dynamic> p) {
    final bool isUrgent = p['priority'] == 'Critical';

    return GestureDetector(
      onTap: () => _navigateTo('detail', patient: p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isUrgent ? Colors.red.shade100 : const Color(0xFFF1F5F9)),
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
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(width: 50, height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(width: 50, height: 50, color: const Color(0xFFE2E8F0), child: const Icon(Icons.broken_image, size: 18));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text("NEXT: ${p['todos'][0]['due']}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (isUrgent)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text("URGENT", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _activeTab,
      onTap: (index) => setState(() {
        _activeTab = index;
        _currentStep = 'dashboard';
      }),
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
  }

  Widget _buildPatientDetail() {
    if (_selectedPatient == null) return const SizedBox.shrink();
    return Column(children: [
      _buildHeader(_selectedPatient!['name'], onBack: () => _navigateTo('dashboard')),
      Expanded(child: Center(child: Text("Details for ${_selectedPatient!['id']}"))),
    ]);
  }
}
