part of '../widgets/main_navigation_screen.dart';

extension _DoctorSummaryPage on _MainNavigationScreenState {
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
      } catch (_) {
        return iso;
      }
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
                  const Text(
                    "CLINICAL WOUND CAPTURE",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                  ),
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
                        errorBuilder: (c, e, s) =>
                            Container(height: 220, color: const Color(0xFFF1F5F9), child: const Center(child: Icon(LucideIcons.image, color: Colors.grey))),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF5EEAD4))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(LucideIcons.stethoscope, color: Color(0xFF0D9488), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        )
                      ]
                    ]),
                  ),
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
                ].map((u) {
                  return Expanded(
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
                        child: Center(
                          child: Text(
                            u['l'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _selectedUrgency == u['v'] ? Colors.white : Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Text(
                  plan['plan_text']?.toString() ?? ai['treatment_plan']?.toString() ?? "No plan provided.",
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                ),
              ),

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
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t['task_text']?.toString() ?? "(task)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              "Due: ${fmtDue(t['task_due']?.toString())} • ${t['status'] ?? 'Pending'}",
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                            ),
                          ]),
                        ),
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
}
