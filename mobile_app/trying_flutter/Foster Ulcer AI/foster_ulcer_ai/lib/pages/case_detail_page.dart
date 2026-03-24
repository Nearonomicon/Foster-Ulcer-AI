part of '../widgets/main_navigation_screen.dart';

extension _CaseDetailPage on _MainNavigationScreenState {
  Widget _buildCaseDetailPage() {
    final c = _caseDetail ?? _selectedPatient;
    if (_caseDetailLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
    }
    if (_caseDetailError != null) {
      return Center(child: Text(_caseDetailError!, style: const TextStyle(color: Colors.redAccent)));
    }
    if (c == null) return const Center(child: Text("No case selected."));

    String fmt(dynamic v) => (v == null || v.toString().isEmpty) ? "-" : v.toString();
    
    // 1. Data Extraction
    final profile = (_caseDetailPatientProfile is Map)
        ? Map<String, dynamic>.from(_caseDetailPatientProfile!)
        : (c['patient_profile'] is Map)
            ? Map<String, dynamic>.from(c['patient_profile'])
            : <String, dynamic>{};
    final currentWound = (c['current_wound_detail'] is Map) ? Map<String, dynamic>.from(c['current_wound_detail']) : <String, dynamic>{};
    final currentVitals = (c['current_vital_signs'] is Map) ? Map<String, dynamic>.from(c['current_vital_signs']) : <String, dynamic>{};
    
    // Records & Timeline
    final records = _caseDetailRecords;
    if (_caseDetailIndex >= records.length) {
      _caseDetailIndex = records.isEmpty ? 0 : records.length - 1;
    }

    final activeRecord = records.isNotEmpty ? records[_caseDetailIndex] : null;
    final baselineRecord = records.isNotEmpty ? records.first : null;
    final currentHealing = fmt(
      activeRecord?['current_healing_progress'] ??
          activeRecord?['healing_progress'] ??
          c['current_healing_progress'],
    );

    // Analysis & Scores (prefer active record analysis if present)
    final currentAnalysis = (c['current_analysis'] is Map) ? Map<String, dynamic>.from(c['current_analysis']) : <String, dynamic>{};
    final currentClassifications = (currentAnalysis['classifications'] is Map)
        ? Map<String, dynamic>.from(currentAnalysis['classifications'])
        : <String, dynamic>{};
    final activeAnalysis = (activeRecord?['analysis'] is Map) ? Map<String, dynamic>.from(activeRecord?['analysis']) : <String, dynamic>{};
    final activeClassifications = (activeAnalysis['classifications'] is Map)
        ? Map<String, dynamic>.from(activeAnalysis['classifications'])
        : <String, dynamic>{};
    final activeDescription = activeAnalysis['description']?.toString();
    final classifications = activeClassifications.isNotEmpty ? activeClassifications : currentClassifications;
    final sinbadMap = (classifications['SINBAD'] is Map)
        ? Map<String, dynamic>.from(classifications['SINBAD'])
        : (activeRecord?['sinbad'] is Map)
            ? Map<String, dynamic>.from(activeRecord?['sinbad'])
            : (c['current_sinbad'] is Map)
                ? Map<String, dynamic>.from(c['current_sinbad'])
                : <String, dynamic>{};
    final sinbadTotal = sinbadMap['total'];
    
    final activeImage = activeRecord?['image']?['image_folder_url']?.toString();
    final activeDate = fmt(activeRecord?['record_created_at'] ?? activeRecord?['timestamps']?['created_at']);
    final hasInf = activeRecord?['wound_detail']?['has_infection'] == true || activeRecord?['wound_detail']?['has_infection']?.toString().toLowerCase() == 'true';
    final vitalsForProfile = (activeRecord?['vital_signs'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['vital_signs'])
        : currentVitals;
    String formatDateTime(String? raw) {
      if (raw == null || raw.isEmpty) return "-";
      try {
        final dt = DateTime.parse(raw).toLocal();
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return "$y-$m-$d $hh:$mm";
      } catch (_) {
        return raw;
      }
    }

    final currentTimestamps = (c['current_timestamps'] is Map) ? Map<String, dynamic>.from(c['current_timestamps']) : <String, dynamic>{};
    final appointmentAt = activeRecord?['timestamps']?['appointment_at'] ?? currentTimestamps['appointment_at'];
    final plan = (activeRecord?['treatment_plan'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['treatment_plan'])
        : (c['current_treatment_plan'] is Map)
            ? Map<String, dynamic>.from(c['current_treatment_plan'])
            : <String, dynamic>{};
    final planTasks = (plan['plan_tasks'] is List)
        ? List<Map<String, dynamic>>.from(plan['plan_tasks'])
        : (activeRecord?['task_list'] is List)
            ? List<Map<String, dynamic>>.from(activeRecord?['task_list'])
            : (c['current_task_list'] is List)
                ? List<Map<String, dynamic>>.from(c['current_task_list'])
                : <Map<String, dynamic>>[];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _currentStep = _previousStep;
          if (_previousStep == 'dashboard') {
            _activeTab = _previousTab;
          }
        });
      },
      child: Column(
        children: [
          // --- HEADER ---
          _buildModernHeader(c),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // --- PATIENT IDENTITY ---
                _buildPatientIdentityCard(profile),
                const SizedBox(height: 16),
                _buildCurrentVitalsCard(vitalsForProfile),
                const SizedBox(height: 24),

                // --- AI TREND BANNER ---
                if (currentHealing != "-") ...[
                  _buildTrendBanner(currentHealing, sinbadTotal),
                  const SizedBox(height: 24),
                ],

                // --- VISUAL EVIDENCE (CAROUSEL) ---
                _buildVisualEvidenceSection(records, activeImage, activeDate, hasInf, baselineRecord, activeRecord, activeDescription),
                const SizedBox(height: 24),

                // --- CLINICAL SNAPSHOT ---
                _buildClinicalSnapshotCard(activeRecord, currentWound, currentVitals, classifications),
                const SizedBox(height: 16),

                // --- APPOINTMENT ---
                _buildAppointmentCard(formatDateTime(appointmentAt?.toString())),
                const SizedBox(height: 16),

                // --- TREATMENT PLAN ---
                _buildTreatmentPlanCard(plan, planTasks, formatDateTime, c),
                const SizedBox(height: 24),

                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // UI COMPONENT BUILDERS
  // =========================================================================

  Widget _buildModernHeader(Map<String, dynamic> c) {
    final status = c['status']?.toString();
    final urgency = c['urgency']?.toString();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.blueGrey), 
            onPressed: () => setState(() {
              _currentStep = _previousStep;
              if (_previousStep == 'dashboard') {
                _activeTab = _previousTab;
              }
            })
          ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Case Detail", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  Text(
                    c['case_id'] ?? "-",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.blueGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const Spacer(),
              _buildNotificationButton(),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status != null && status.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusBgColor(status),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _statusBgColor(status)),
                      ),
                      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _statusFgColor(status))),
                    ),
                  if (urgency != null && urgency.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _urgencyColor(urgency).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _urgencyColor(urgency).withOpacity(0.28)),
                      ),
                      child: Text(
                        _urgencyLabel(urgency),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _urgencyColor(urgency),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildPatientIdentityCard(Map<String, dynamic> profile) {
    int? calcAge(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      DateTime? dob;
      try {
        dob = DateTime.parse(raw);
      } catch (_) {
        try {
          final parts = raw.split('/'); // dd/MM/yyyy
          if (parts.length == 3) {
            final d = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final y = int.parse(parts[2]);
            dob = DateTime(y, m, d);
          }
        } catch (_) {}
      }
      if (dob == null) return null;
      final today = DateTime.now();
      var age = today.year - dob.year;
      final hasHadBirthday = (today.month > dob.month) || (today.month == dob.month && today.day >= dob.day);
      if (!hasHadBirthday) age -= 1;
      return age;
    }

    final dob = profile['dob']?.toString();
    final age = calcAge(dob);
    final diabetes = (profile['diabetes'] is Map) ? Map<String, dynamic>.from(profile['diabetes']) : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(20)),
            child: const Icon(LucideIcons.user, color: Color(0xFF0D9488), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile['patient_name'] ?? "-", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Text(
                  "${profile['gender']} • DOB: ${dob ?? '-'}${age != null ? " ($age)" : ""}",
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                ),
                if (profile['medical_history'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Text("Hx: ${profile['medical_history']}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  )
                ],
                if (diabetes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      shape: const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      title: const Text("Diabetes Details", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      children: [
                        _detailRow("Has Diabetes", (diabetes['has_diabetes'] ?? "-").toString()),
                        _detailRow("Years", (diabetes['years'] ?? "-").toString()),
                        _detailRow("Risk History", (diabetes['risk_history'] ?? "-").toString()),
                        _detailRow("Complications", (diabetes['complications'] ?? "-").toString()),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentVitalsCard(Map<String, dynamic> vitals) {
    String fmt(dynamic v) => (v == null || v.toString().isEmpty) ? "-" : v.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CURRENT VITALS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _vitalChip("BP", fmt(vitals['blood_pressure'])),
              _vitalChip("TEMP", fmt(vitals['temperature'])),
              _vitalChip("HR", fmt(vitals['heart_rate'])),
              _vitalChip("RR", fmt(vitals['respiratory_rate'])),
              _vitalChip("BG", fmt(vitals['blood_glucose'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildTrendBanner(String trendText, dynamic sinbad) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(LucideIcons.sparkles, color: Color(0xFFCCFBF1), size: 14),
            ),
            const SizedBox(width: 10),
            const Text("HEALING PROGRESS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFCCFBF1), letterSpacing: 1)),
            const Spacer(),
            if (sinbad != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                child: Text("SINBAD $sinbad", style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w900, fontSize: 10)),
              ),
          ]),
          const SizedBox(height: 16),
          Text(trendText, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildVisualEvidenceSection(List records, String? activeImage, String activeDate, bool hasInf, Map<String, dynamic>? baselineRecord, Map<String, dynamic>? activeRecord, String? activeDescription) {
    final descriptionText = (activeDescription == null || activeDescription.trim().isEmpty)
        ? "No description provided."
        : activeDescription.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text("VISUAL EVIDENCE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
            ),
            if (records.length > 1)
              GestureDetector(
                onTap: () => _showComparisonDialog(context, baselineRecord, activeRecord),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text("Compare Baseline", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0D9488))),
                ),
              ),
          ],
        ),
        
        // Timeline Selector
        SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, size: 18, color: Color(0xFF64748B)),
                onPressed: () {
                  final itemExtent = 92.0 + 8.0;
                  final target = (_caseDetailTimelineCtrl.offset - (itemExtent * 5)).clamp(
                    0.0,
                    _caseDetailTimelineCtrl.position.maxScrollExtent,
                  );
                  _caseDetailTimelineCtrl.animateTo(
                    target,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
              ),
              Expanded(
                child: ListView.separated(
                  controller: _caseDetailTimelineCtrl,
                  scrollDirection: Axis.horizontal,
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    String? recordTime(Map r) {
                      return (r['record_created_at'] ??
                              r['timestamps']?['created_at'] ??
                              r['record_updated_at'] ??
                              r['timestamps']?['updated_at'])
                          ?.toString();
                    }

                    String formatShortDate(String? raw) {
                      if (raw == null || raw.isEmpty) return "-";
                      try {
                        final dt = DateTime.parse(raw).toLocal();
                        final d = dt.day.toString().padLeft(2, '0');
                        final m = dt.month.toString().padLeft(2, '0');
                        final y = (dt.year % 100).toString().padLeft(2, '0');
                        return "$d/$m/$y";
                      } catch (_) {
                        return raw.split('T').first;
                      }
                    }

                    final isSelected = _caseDetailIndex == i;
                    final raw = recordTime(records[i]);
                    return InkWell(
                      onTap: () => setState(() => _caseDetailIndex = i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 92,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D9488).withOpacity(0.12) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Text(
                            formatShortDate(raw),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.2,
                              color: isSelected ? const Color(0xFF0D9488) : Colors.blueGrey,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFF64748B)),
                onPressed: () {
                  final itemExtent = 92.0 + 8.0;
                  final target = (_caseDetailTimelineCtrl.offset + (itemExtent * 5)).clamp(
                    0.0,
                    _caseDetailTimelineCtrl.position.maxScrollExtent,
                  );
                  _caseDetailTimelineCtrl.animateTo(
                    target,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Main Image Container
        Container(
          height: 340,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(32),
            image: activeImage != null ? DecorationImage(image: NetworkImage(activeImage), fit: BoxFit.cover) : null,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            children: [
              if (activeImage == null) const Center(child: Icon(LucideIcons.image, size: 48, color: Colors.grey)),
              // Glassmorphism Overlay
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("RECORD ${_caseDetailIndex + 1}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(activeDate, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ]
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasInf ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(hasInf ? "INFECTION" : "NO INFECTION", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF99F6E4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ANALYSIS DESCRIPTION",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F766E),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                descriptionText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF134E4A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalSnapshotCard(Map? activeRecord, Map wound, Map vitals, Map classifications) {
    String fmt(dynamic v) => (v == null || v.toString().isEmpty) ? "-" : v.toString();
    final recordWound = (activeRecord?['wound_detail'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['wound_detail'])
        : <String, dynamic>{};
    final recordVitals = (activeRecord?['vital_signs'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['vital_signs'])
        : <String, dynamic>{};
    final recordAnalysis = (activeRecord?['analysis'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['analysis'])
        : <String, dynamic>{};
    final recordClassifications = (recordAnalysis['classifications'] is Map)
        ? Map<String, dynamic>.from(recordAnalysis['classifications'])
        : <String, dynamic>{};
    final recordIschemia = (activeRecord?['ischemia'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['ischemia'])
        : <String, dynamic>{};
    final recordInfection = (activeRecord?['infection'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['infection'])
        : <String, dynamic>{};
    final recordNeuropathy = (activeRecord?['neuropathy'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['neuropathy'])
        : <String, dynamic>{};
    final recordSinbad = (activeRecord?['sinbad'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['sinbad'])
        : <String, dynamic>{};
    final recordLabs = (activeRecord?['lab_results'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['lab_results'])
        : <String, dynamic>{};
    final recordVascular = (activeRecord?['vascular'] is Map)
        ? Map<String, dynamic>.from(activeRecord?['vascular'])
        : <String, dynamic>{};
    final recordGangrene = activeRecord?['gangrene_extent'];

    final snapWound = recordWound.isNotEmpty ? recordWound : wound;
    final snapVitals = recordVitals.isNotEmpty ? recordVitals : vitals;
    final snapClassifications = recordClassifications.isNotEmpty ? recordClassifications : classifications;
    final snapIschemia = recordIschemia.isNotEmpty ? recordIschemia : (wound['ischemia'] is Map ? Map<String, dynamic>.from(wound['ischemia']) : <String, dynamic>{});
    final snapInfection = recordInfection.isNotEmpty ? recordInfection : <String, dynamic>{};
    final snapNeuropathy = recordNeuropathy.isNotEmpty ? recordNeuropathy : <String, dynamic>{};
    final snapSinbad = recordSinbad.isNotEmpty ? recordSinbad : (snapClassifications['SINBAD'] is Map ? Map<String, dynamic>.from(snapClassifications['SINBAD']) : <String, dynamic>{});
    final snapLabs = recordLabs.isNotEmpty ? recordLabs : <String, dynamic>{};
    final snapVascular = recordVascular.isNotEmpty ? recordVascular : <String, dynamic>{};
    final snapGangrene = recordGangrene ?? snapWound['gangrene_extent'] ?? "-";

    final snapWIfi = (snapClassifications['WIfI'] is Map)
        ? Map<String, dynamic>.from(snapClassifications['WIfI'])
        : <String, dynamic>{};
    final wIfiText =
        "W:${snapWIfi['wound_grade'] ?? '-'} I:${snapWIfi['ischemia_grade'] ?? '-'} fI:${snapWIfi['foot_infection_grade'] ?? '-'}";

    // Safely parse tissue bed percentages
    final bed = (snapWound['bed'] is Map) ? Map<String, dynamic>.from(snapWound['bed']) : <String, dynamic>{};
    final discharge = (snapWound['discharge'] is Map) ? Map<String, dynamic>.from(snapWound['discharge']) : <String, dynamic>{};
    final size = (snapWound['size'] is Map) ? Map<String, dynamic>.from(snapWound['size']) : <String, dynamic>{};
    int slough = int.tryParse(bed['slough_pct']?.toString() ?? '0') ?? 0;
    int necrotic = int.tryParse(bed['necrotic_pct']?.toString() ?? '0') ?? 0;
    int granulation = (100 - slough - necrotic).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CLINICAL SNAPSHOT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(child: _buildDetailData("Wound Size", "${size['width_cm'] ?? '-'} × ${size['length_cm'] ?? '-'} cm")),
              Expanded(child: _buildDetailData("Depth", snapWound['depth_category'] ?? "-")),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDetailData("Pain Level", "${snapWound['pain_score'] ?? '-'}/10")),
              Expanded(child: _buildDetailData("Exudate", discharge['type'] ?? "-")),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text("TISSUE COMPOSITION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          
          // Tissue Composition Bar
          Container(
            height: 12,
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99)),
            child: Row(
              children: [
                if (granulation > 0) Expanded(flex: granulation, child: Container(color: const Color(0xFF10B981))),
                if (slough > 0) Expanded(flex: slough, child: Container(color: const Color(0xFFF59E0B))),
                if (necrotic > 0) Expanded(flex: necrotic, child: Container(color: const Color(0xFF1E293B))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Granulation: $granulation%", style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              Text("Slough: $slough%", style: const TextStyle(fontSize: 9, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
              Text("Necrotic: $necrotic%", style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => setState(() => _caseDetailShowWoundDetails = !_caseDetailShowWoundDetails),
              child: Text(
                _caseDetailShowWoundDetails ? "Details ▼" : "Details ▶",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0D9488)),
              ),
            ),
          ),
          if (_caseDetailShowWoundDetails) ...[
            const SizedBox(height: 12),
            _detailDropdown(
              "Wound Details",
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _detailCard("Wound Basics", [
                    _detailRow("Location Primary", fmt(snapWound['location_primary'])),
                    _detailRow("Location Detail", fmt(snapWound['location_detail'])),
                    _detailRow("Wound Type", fmt(snapWound['wound_type'])),
                    _detailRow("Shape", fmt(snapWound['shape'])),
                  ]),
                  _detailCard("Size & Depth", [
                    _detailRow("Width (cm)", fmt(size['width_cm'])),
                    _detailRow("Length (cm)", fmt(size['length_cm'])),
                    _detailRow("Depth Category", fmt(snapWound['depth_category'])),
                  ]),
                  _detailCard("Tissue & Edge", [
                    _detailRow("Slough %", fmt(bed['slough_pct'])),
                    _detailRow("Necrotic %", fmt(bed['necrotic_pct'])),
                    _detailRow("Edge Description", fmt(snapWound['edge_description'])),
                    _detailRow("Periwound Status", fmt(snapWound['periwound_status'])),
                  ]),
                  _detailCard("Discharge & Symptoms", [
                    _detailRow("Discharge Volume", fmt(discharge['volume'])),
                    _detailRow("Discharge Type", fmt(discharge['type'])),
                    _detailRow("Odor Presence", fmt(snapWound['odor_presence'])),
                    _detailRow("Pain Score", fmt(snapWound['pain_score'])),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _detailDropdown(
              "Advanced Input (WIfI/IDSA)",
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _detailCard("Infection", [
                    _detailRow("Has Infection", fmt(snapWound['has_infection'])),
                    _detailRow("Probe to Bone", fmt(snapInfection['probe_to_bone_test'])),
                    _detailRow("Erythema Extent", fmt(snapInfection['erythema_extent'])),
                    _detailRow("Checklist", fmt(snapInfection['checklist'])),
                  ]),
                  _detailCard("Ischemia", [
                    _detailRow("Pulse", fmt(snapIschemia['pulse'])),
                    _detailRow("Checklist", fmt(snapIschemia['checklist'])),
                    _detailRow("Points", fmt(snapIschemia['points'])),
                  ]),
                  _detailCard("Neuropathy", [
                    _detailRow("Points", fmt(snapNeuropathy['points'])),
                  ]),
                  _detailCard("SINBAD", [
                    _detailRow("Site", fmt(snapSinbad['site'])),
                    _detailRow("Ischemia", fmt(snapSinbad['ischemia'])),
                    _detailRow("Neuropathy", fmt(snapSinbad['neuropathy'])),
                    _detailRow("Infection", fmt(snapSinbad['infection'] ?? snapSinbad['bacterial_infection'])),
                    _detailRow("Area", fmt(snapSinbad['area'])),
                    _detailRow("Depth", fmt(snapSinbad['depth'])),
                    _detailRow("Total", fmt(snapSinbad['total'])),
                  ]),
                  _detailCard("Lab Results", [
                    _detailRow("WBC", fmt(snapLabs['wbc_count'])),
                    _detailRow("CRP", fmt(snapLabs['crp'])),
                    _detailRow("ESR", fmt(snapLabs['esr'])),
                    _detailRow("Procalcitonin", fmt(snapLabs['procalcitonin'])),
                  ]),
                  _detailCard("Vascular", [
                    _detailRow("ABI", fmt(snapVascular['abi_value'])),
                    _detailRow("Ankle Pressure", fmt(snapVascular['ankle_pressure_mmHg'])),
                    _detailRow("Toe Pressure", fmt(snapVascular['toe_pressure_mmHg'])),
                    _detailRow("TcPO2", fmt(snapVascular['tcpo2_mmHg'])),
                  ]),
                  _detailCard("Gangrene", [
                    _detailRow("Extent", fmt(snapGangrene)),
                  ]),
                ],
              ),
            ),
          ],

          const Divider(height: 40, color: Color(0xFFF1F5F9), thickness: 1.5),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scorePill("SINBAD", snapClassifications['SINBAD']?['total']),
              _scorePill("WIfI", wIfiText),
              _scorePill("IDSA", snapClassifications['IDSA_infection_stage']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailData(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(String title, List<Widget> rows) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _detailDropdown(String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        children: [child],
      ),
    );
  }

  Widget _buildAppointmentCard(String appointmentAt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.calendarCheck, color: Color(0xFF0284C7), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("APPOINTMENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(appointmentAt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentPlanCard(Map<String, dynamic> plan, List<Map<String, dynamic>> tasks, String Function(String?) fmtDate, Map<String, dynamic> c) {
    final planText = plan['plan_text']?.toString() ?? "No plan provided.";
    final followup = plan['followup_days']?.toString();
    final status = plan['status']?.toString();
    final caseId = (c['case_id'] ?? '').toString();
    final taskIndex = tasks.isNotEmpty ? 0 : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TREATMENT PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              planText,
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
            ),
          ),
          if (followup != null || status != null) ...[
            const SizedBox(height: 8),
            _detailRow("Follow-up (days)", followup ?? "-"),
            _detailRow("Plan Status", status ?? "-"),
          ],
          if (caseId.isNotEmpty && taskIndex != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  _taskDetailReturnStep = _currentStep;
                  _taskDetailReturnTab = _activeTab;
                  final ok = await _fetchTaskDetail(caseId: caseId, taskIndex: taskIndex);
                  if (!ok) return;
                  if (!mounted) return;
                  setState(() => _currentStep = 'task_detail');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Open Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text("Task List", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 6),
          if (tasks.isEmpty)
            const Text("No tasks.", style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            ...tasks.map((t) {
              final text = t['task_text']?.toString() ?? "(task)";
              final due = fmtDate(t['task_due']?.toString());
              final tStatus = t['status']?.toString() ?? "Pending";
              return Container(
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
                        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          "Due: $due || Status: $tStatus",
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ]),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _scorePill(String label, dynamic value) {
    final isWide = label == "WIfI" || (value?.toString().length ?? 0) > 3;
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 6),
        Container(
          width: isWide ? 140 : 60,
          padding: EdgeInsets.symmetric(vertical: isWide ? 8 : 10, horizontal: isWide ? 8 : 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCCFBF1))),
          child: Text(
            value?.toString() ?? "-",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isWide ? 12 : 16,
              color: const Color(0xFF0D9488),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // COMPARISON MODAL LOGIC
  // =========================================================================

  void _showComparisonDialog(BuildContext context, Map<String, dynamic>? baseline, Map<String, dynamic>? current) {
    if (baseline == null || current == null) return;

    Widget buildCompareCard(String title, Map<String, dynamic> record, Color themeColor) {
      final img = record['image']?['image_folder_url']?.toString();
      final wound = (record['wound_detail'] is Map) ? Map<String, dynamic>.from(record['wound_detail']) : {};
      
      // FIXED STRING INTERPOLATION HERE
      final size = "${wound['size']?['width_cm'] ?? '-'}x${wound['size']?['length_cm'] ?? '-'}cm";
      
      final pain = wound['pain_score']?.toString() ?? "-";
      final hasInf = wound['has_infection'] == true || wound['has_infection']?.toString().toLowerCase() == 'true';

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Dark slate
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(99)),
              child: Text(title, style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                image: img != null ? DecorationImage(image: NetworkImage(img), fit: BoxFit.cover) : null,
              ),
              child: img == null ? const Center(child: Icon(LucideIcons.image, color: Colors.white54)) : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SIZE", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text(size, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PAIN", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text(pain, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("INFECTION", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    Text(hasInf ? "YES" : "NO", style: TextStyle(color: hasInf ? Colors.redAccent : Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            )
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A), // Very dark slate
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("COMPARISON", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white54),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildCompareCard("BASELINE (REC-00001)", baseline, Colors.white),
                  const Icon(LucideIcons.arrowDown, color: Colors.white24, size: 24),
                  const SizedBox(height: 16),
                  buildCompareCard("CURRENT (${current['record_id'] ?? 'Latest'})", current, const Color(0xFF0D9488)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
