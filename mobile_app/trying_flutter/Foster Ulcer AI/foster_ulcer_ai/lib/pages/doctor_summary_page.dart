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
    final redFlag = ai['red_flag'] == true;
    final creator = ai['creator']?.toString();
    final diag = ai['diagnosis'];
    final diagnosisRaw = (diag is Map ? diag['text'] : diag) ?? ai['diagnosis_text'] ?? ai['dx'] ?? data['diagnosis'];
    final diagnosis = (diagnosisRaw == null || diagnosisRaw.toString().trim().isEmpty)
        ? "No diagnosis provided."
        : diagnosisRaw.toString();
    final classifications = (ai['classifications'] is Map) ? Map<String, dynamic>.from(ai['classifications']) : <String, dynamic>{};
    final idsaStage = classifications['IDSA_infection_stage'] ?? ai['IDSA_infection_stage'] ?? ai['IDSA_infaction_stage'];

    final wIfi = (classifications['WIfI'] is Map) ? Map<String, dynamic>.from(classifications['WIfI']) : <String, dynamic>{};
    final wIfiWound = wIfi['wound_grade'] ?? ai['WIfI_wound_stage'] ?? ai['WIfI_wound_grade'] ?? ai['wIfI_wound_stage'];
    final wIfiIschemia = wIfi['ischemia_grade'] ?? ai['WIfI_ischemia_stage'] ?? ai['WIfI_ischemia_grade'] ?? ai['wIfI_ischemia_stage'];
    final wIfiFootInf = wIfi['foot_infection_grade'] ?? ai['WIfI_foot_infection_stage'] ?? ai['WIfI_foot_infection_grade'] ?? ai['wIfI_foot_infection_stage'];
    final wIfiStage = wIfi['clinical_stage'] ?? ai['WIfI_clinical_stage'] ?? ai['WIfI_stage'] ?? ai['wIfI_stage'];

    final sinbad = (classifications['SINBAD'] is Map) ? Map<String, dynamic>.from(classifications['SINBAD']) : <String, dynamic>{};
    final sinbadTotal = sinbad['total'] ?? _calcSinbadScore();
    final sinbadSite = sinbad['site'] ?? _reviewed['sinbad_site'];
    final sinbadIschemia = sinbad['ischemia'] ?? _reviewed['sinbad_ischemia'];
    final sinbadNeuropathy = sinbad['neuropathy'] ?? _reviewed['sinbad_neuropathy'];
    final sinbadInfection = sinbad['bacterial_infection'] ?? _reviewed['sinbad_infection'];
    final sinbadArea = sinbad['area'] ?? _reviewed['sinbad_area'];
    final sinbadDepth = sinbad['depth'] ?? _reviewed['sinbad_depth'];

    int sinbadScoreValue(String group, dynamic value) {
      final v = value?.toString();
      switch (group) {
        case 'site':
          return v == "Midfoot/Hindfoot" ? 1 : 0;
        case 'ischemia':
          return v == "Yes" ? 1 : 0;
        case 'neuropathy':
          return v == "Yes" ? 1 : 0;
        case 'infection':
          return v == "Yes" ? 1 : 0;
        case 'area':
          return v == kSinbadAreaLarge ? 1 : 0;
        case 'depth':
          return v == "Deep/Bone" ? 1 : 0;
        default:
          return 0;
      }
    }
    final treatmentSummary = ai['treatment_plan_summary']?.toString();

    String fmtDue(String? iso) {
      if (iso == null || iso.isEmpty) return "TBD";
      try {
        final dt = DateTime.parse(iso).toLocal();
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      } catch (_) {
        return iso;
      }
    }

    String fmtList(dynamic v) {
      if (v is List) return v.join(', ');
      if (v == null) return '-';
      final s = v.toString();
      return s.isEmpty ? '-' : s;
    }

    return Column(
      children: [
        _buildHeader("Clinical Case Summary", onBack: () => _navigateTo('assessment')),
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
              if (redFlag)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFCA5A5))),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.triangleAlert, size: 16, color: Color(0xFFB91C1C)),
                      SizedBox(width: 8),
                      Expanded(child: Text("Red Flag: Urgent review recommended.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)))),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF5EEAD4))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.stethoscope, color: Color(0xFF0D9488), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diagnosis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF134E4A)),
                              ),
                              if (creator != null && creator.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(creator, style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E))),
                              ],
                              if (confPct != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "Confidence: $confPct%",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                )
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F7F3),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF5EEAD4)),
                          ),
                          child: Text(
                            "IDSA Stage: ${(idsaStage ?? '-').toString()}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF134E4A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F7F3),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF5EEAD4)),
                          ),
                          child: Text(
                            "WIfI W:${(wIfiWound ?? '-').toString()} I:${(wIfiIschemia ?? '-').toString()} FI:${(wIfiFootInf ?? '-').toString()}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF134E4A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F7F3),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF5EEAD4)),
                          ),
                          child: Text(
                            "WIfI Stage: ${(wIfiStage ?? '-').toString()}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF134E4A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F7F3),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF5EEAD4)),
                          ),
                          child: Text(
                            "SINBAD: ${(sinbadTotal ?? '-').toString()}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF134E4A)),
                          ),
                        ),
                      ],
                    ),
                    if (treatmentSummary != null && treatmentSummary.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        treatmentSummary,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF134E4A)),
                      ),
                    ],
                  ],
                ),
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
              _buildSectionTitle(LucideIcons.clipboardCheck, "Assessment Inputs"),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 560;
                  final cardWidth = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
                  Widget card(String title, List<Widget> children) {
                    return SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                            const SizedBox(height: 8),
                            ...children,
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          card("Vitals", [
                            _kv("Temperature", _tempLevel?.toString() ?? '-'),
                            _kv("Blood Pressure", _bpLevel?.toString() ?? '-'),
                            _kv("Heart Rate", _heartRateLevel?.toString() ?? '-'),
                            _kv("Respiratory Rate", _respRateLevel?.toString() ?? _reviewed['repiratory_rate']?.toString() ?? '-'),
                            _kv("Blood Sugar", _sugarLevel?.toString() ?? _reviewed['blood_sugar']?.toString() ?? '-'),
                          ]),
                          card("SINBAD", [
                            _kv("Site", _reviewed['sinbad_site']?.toString() ?? '-'),
                            _kv("Ischemia", _reviewed['sinbad_ischemia']?.toString() ?? '-'),
                            _kv("Neuropathy", _reviewed['sinbad_neuropathy']?.toString() ?? '-'),
                            _kv("Infection", _reviewed['sinbad_infection']?.toString() ?? '-'),
                            _kv("Area", _reviewed['sinbad_area']?.toString() ?? '-'),
                            _kv("Depth", _reviewed['sinbad_depth']?.toString() ?? '-'),
                            _kv("Total Score", _calcSinbadScore().toString()),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text("Wound Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                card("Wound Basics", [
                                  _kv("Location Primary", _reviewed['location_primary']?.toString() ?? '-'),
                                  _kv("Location Detail", _reviewed['location_detail']?.toString() ?? '-'),
                                  _kv("Wound Type", _reviewed['wound_type']?.toString() ?? '-'),
                                  _kv("Shape", _reviewed['shape']?.toString() ?? '-'),
                                ]),
                                card("Size & Depth", [
                                  _kv("Width / Length", "${_reviewed['size_width_cm'] ?? '-'} cm / ${_reviewed['size_length_cm'] ?? '-'} cm"),
                                  _kv("Depth Category", _reviewed['depth_category']?.toString() ?? '-'),
                                ]),
                                card("Tissue & Edge", [
                                  _kv("Bed Slough %", "${_reviewed['bed_slough_pct'] ?? '-'}%"),
                                  _kv("Bed Necrotic %", "${_reviewed['bed_necrotic_pct'] ?? '-'}%"),
                                  _kv("Edge Description", _reviewed['edge_description']?.toString() ?? '-'),
                                  _kv("Periwound Status", _reviewed['periwound_status']?.toString() ?? '-'),
                                ]),
                                card("Discharge & Symptoms", [
                                  _kv("Discharge Volume", _reviewed['discharge_volume']?.toString() ?? '-'),
                                  _kv("Discharge Type", _reviewed['discharge_type']?.toString() ?? '-'),
                                  _kv("Odor Presence", _reviewed['odor_presence']?.toString() ?? '-'),
                                  _kv("Pain Score", "${_reviewed['pain_score'] ?? '-'}/10"),
                                  _kv("Has Infection", (_reviewed['has_infection']?.toString().toLowerCase() == 'true') ? "YES" : "NO"),
                                  _kv("Skin Condition", _reviewed['skin_condition']?.toString() ?? '-'),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text("Advanced Inputs (WIfI / IDSA)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                card("WIfI: Ischemia", [
                                  _kv("Pulse Check", _reviewed['ischemia_pulse']?.toString() ?? '-'),
                                  _kv("Ischemia Checklist", fmtList(_reviewed['ischemia_checklist'])),
                                  _kv("Ischemia Points", fmtList(_reviewed['ischemia_points'])),
                                  _kv("ABI", _reviewed['vascular_abi_value']?.toString() ?? '-'),
                                  _kv("Ankle Pressure", _reviewed['vascular_ankle_pressure_mmHg']?.toString() ?? '-'),
                                  _kv("Toe Pressure", _reviewed['vascular_toe_pressure_mmHg']?.toString() ?? '-'),
                                  _kv("TcPO2", _reviewed['vascular_tcpo2_mmHg']?.toString() ?? '-'),
                                ]),
                                card("WIfI: Wound", [
                                  _kv("Gangrene Extent", _reviewed['gangrene_extent']?.toString() ?? '-'),
                                  _kv("Depth Category", _reviewed['depth_category']?.toString() ?? '-'),
                                  _kv("Location Primary", _reviewed['location_primary']?.toString() ?? '-'),
                                ]),
                                card("IDSA: Infection", [
                                  _kv("Infection Checklist", fmtList(_reviewed['infection_checklist'])),
                                  _kv("Erythema Extent", _reviewed['erythema_extent']?.toString() ?? '-'),
                                  _kv("Probe-to-Bone", _reviewed['probe_to_bone_test']?.toString() ?? '-'),
                                  _kv("Deep Abscess/Fasciitis", _reviewed['has_deep_abscess_or_fasciitis']?.toString() ?? '-'),
                                ]),
                                card("Neuropathy", [
                                  _kv("Neuropathy Points", fmtList(_reviewed['neuropathy_points'])),
                                ]),
                                card("Labs", [
                                  _kv("WBC Count", _reviewed['lab_wbc_count']?.toString() ?? '-'),
                                  _kv("CRP", _reviewed['lab_crp']?.toString() ?? '-'),
                                  _kv("ESR", _reviewed['lab_esr']?.toString() ?? '-'),
                                  _kv("Procalcitonin", _reviewed['lab_procalcitonin']?.toString() ?? '-'),
                                ]),
                                card("Advanced Inputs", [
                                  _kv("Erythema Extent", _reviewed['erythema_extent']?.toString() ?? '-'),
                                  _kv("Probe-to-Bone", _reviewed['probe_to_bone_test']?.toString() ?? '-'),
                                  _kv("Deep Abscess/Fasciitis", _reviewed['has_deep_abscess_or_fasciitis']?.toString() ?? '-'),
                                  _kv("Gangrene Extent", _reviewed['gangrene_extent']?.toString() ?? '-'),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.fileText, "AI Results"),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text("View AI results", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 560;
                        final cardWidth = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
                        Widget card(String title, List<Widget> children) {
                          return SizedBox(
                            width: cardWidth,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                                  const SizedBox(height: 8),
                                  ...children,
                                ],
                              ),
                            ),
                          );
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            card("AI Narrative", [
                              Text(
                                ai['description']?.toString() ?? "No description provided.",
                                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                              ),
                            ]),
                            card("AI Classifications", [
                              _kv("IDSA Stage", (idsaStage ?? '-').toString()),
                              _kv("WIfI Wound", (wIfiWound ?? '-').toString()),
                              _kv("WIfI Ischemia", (wIfiIschemia ?? '-').toString()),
                              _kv("WIfI Foot Infection", (wIfiFootInf ?? '-').toString()),
                              _kv("WIfI Clinical Stage", (wIfiStage ?? '-').toString()),
                              _kv("SINBAD Total", (sinbadTotal ?? '-').toString()),
                            ]),
                            card("SINBAD Breakdown", [
                              _kv("Site", (sinbadSite ?? '-').toString()),
                              _kv("Ischemia", (sinbadIschemia ?? '-').toString()),
                              _kv("Neuropathy", (sinbadNeuropathy ?? '-').toString()),
                              _kv("Infection", (sinbadInfection ?? '-').toString()),
                              _kv("Area", (sinbadArea ?? '-').toString()),
                              _kv("Depth", (sinbadDepth ?? '-').toString()),
                            ]),
                          ],
                        );
                      },
                    ),
                  ],
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
              if (plan['followup_days'] != null || plan['status'] != null) ...[
                const SizedBox(height: 8),
                _kv("Follow-up (days)", plan['followup_days']?.toString() ?? '-'),
                _kv("Plan Status", plan['status']?.toString() ?? '-'),
              ],

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
                              "Due: ${fmtDue(t['task_due']?.toString())} || Status: ${t['status'] ?? 'Pending'}",
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
