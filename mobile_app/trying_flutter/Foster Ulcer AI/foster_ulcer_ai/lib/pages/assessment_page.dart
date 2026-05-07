part of '../widgets/main_navigation_screen.dart';

const List<Offset> _neuropathyPointAnchors = [
  Offset(0.62, 0.18),
  Offset(0.47, 0.19),
  Offset(0.38, 0.28),
  Offset(0.62, 0.30),
  Offset(0.50, 0.32),
  Offset(0.38, 0.36),
  Offset(0.55, 0.56),
  Offset(0.40, 0.58),
  Offset(0.53, 0.85),
];

extension _AssessmentPage on _MainNavigationScreenState {
  int _calcSinbadScore() {
    var score = 0;
    if (_sinbadSite == "Midfoot/Hindfoot") score++;
    if (_sinbadIschemia == "Yes") score++;
    if (_sinbadNeuropathy == "Yes") score++;
    if (_sinbadInfection == "Yes") score++;
    if (_sinbadArea == kSinbadAreaLarge) score++;
    if (_sinbadDepth == "Deep/Bone") score++;
    return score;
  }

  Color _scoreColor(int score) {
    if (score >= 3) return Colors.red;
    if (score == 2) return Colors.amber;
    return const Color(0xFF0D9488);
  }

  void _maybeShowHighRisk(int newScore) {
    if (newScore >= 3 && _sinbadScoreLast < 3) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("High Risk Case"),
          content: const Text("Referral recommended."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
    _sinbadScoreLast = newScore;
  }

  Widget _buildWoundAssessmentForm() {
    final score = _calcSinbadScore();
    final scoreColor = _scoreColor(score);
    final reviewSkipped = _woundNotPresentFlow;
    return Column(
      children: [
        _buildHeader("Wound Assessment", onBack: () => _navigateTo(reviewSkipped ? 'vital_check_page' : 'response_view')),
        Expanded(
          child: SingleChildScrollView(
            controller: _assessmentScrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                if (_capturedImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(_capturedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    childrenPadding: const EdgeInsets.only(bottom: 16),
                    collapsedBackgroundColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    title: const Text(
                      "Voice Assessment",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey),
                    children: [
                      _buildAssessmentVoiceCard(),
                    ],
                  ),
                ),
                if (reviewSkipped)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_circle_outline, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Fill-in Answers (Review)",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Skipped because wound is not present. Complete the SINBAD section below.",
                                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Text(
                            "Skipped",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: ValueKey('fillin_review_$_fillinExpanded'),
                      initiallyExpanded: _fillinExpanded,
                      onExpansionChanged: (v) => setState(() => _fillinExpanded = v),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Fill-in Answers (Review)",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _fillinReviewed = !_fillinReviewed),
                            icon: Icon(
                              _fillinReviewed ? Icons.check_circle : Icons.check_circle,
                              color: _fillinReviewed ? const Color(0xFF0D9488) : Colors.blueGrey,
                              size: 18,
                            ),
                            label: Text(
                              _fillinReviewed ? "Reviewed" : "Review",
                              style: TextStyle(
                                color: _fillinReviewed ? const Color(0xFF0D9488) : Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        _fillinExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                        color: Colors.blueGrey,
                      ),
                      children: [
                        _buildDropdownField(
                          label: "Location Primary",
                          options: const [
                            "toe",
                            "sole",
                            "side",
                            "heel",
                            "dorsal_aspect",
                            "medial_malleolus",
                            "lateral_malleolus",
                          ],
                          value: _reviewed['location_primary']?.toString(),
                          bindKey: "location_primary",
                        ),
                        _buildTextField(
                          label: "Location Detail",
                          placeholder: "Enter detail",
                          bindKey: "location_detail",
                        ),
                        _buildDropdownField(
                          label: "Wound Type",
                          options: const [
                            "ulcer",
                            "surgical",
                            "traumatic",
                            "pressure",
                            "burn",
                            "other",
                          ],
                          value: _reviewed['wound_type']?.toString(),
                          bindKey: "wound_type",
                        ),
                        _buildDropdownField(
                          label: "Shape",
                          options: const ["round", "oval", "irregular", "linear", "punched_out"],
                          value: _reviewed['shape']?.toString(),
                          bindKey: "shape",
                        ),
                        _buildTextField(
                          label: "Width (cm)",
                          placeholder: "e.g. 2.5",
                          keyboardType: TextInputType.number,
                          bindKey: "size_width_cm",
                        ),
                        _buildTextField(
                          label: "Length (cm)",
                          placeholder: "e.g. 3.0",
                          keyboardType: TextInputType.number,
                          bindKey: "size_length_cm",
                        ),
                        _buildDropdownField(
                          label: "Depth Category",
                          options: const [
                            "superficial",
                            "partial_thickness",
                            "full_thickness",
                            "deep",
                            "very_deep_exposed_bone_tendon",
                          ],
                          value: _reviewed['depth_category']?.toString(),
                          bindKey: "depth_category",
                        ),
                        _buildTextField(
                          label: "Bed Slough (%)",
                          placeholder: "0-100",
                          keyboardType: TextInputType.number,
                          bindKey: "bed_slough_pct",
                        ),
                        _buildTextField(
                          label: "Bed Necrotic (%)",
                          placeholder: "0-100",
                          keyboardType: TextInputType.number,
                          bindKey: "bed_necrotic_pct",
                        ),
                        _buildDropdownField(
                          label: "Edge Description",
                          options: const ["smooth", "thickened", "irregular", "rolled_epibole", "undermined", "calloused"],
                          value: _reviewed['edge_description']?.toString(),
                          bindKey: "edge_description",
                        ),
                        _buildDropdownField(
                          label: "Periwound Status",
                          options: const [
                            "normal",
                            "erythematous",
                            "edematous",
                            "indurated",
                            "macerated",
                            "fluctuant",
                            "hyperpigmented",
                          ],
                          value: _reviewed['periwound_status']?.toString(),
                          bindKey: "periwound_status",
                        ),
                        _buildDropdownField(
                          label: "Discharge Volume",
                          options: const ["none", "minimal", "moderate", "heavy"],
                          value: _reviewed['discharge_volume']?.toString(),
                          bindKey: "discharge_volume",
                        ),
                        _buildDropdownField(
                          label: "Discharge Type",
                          options: const [
                            "serous (clear)",
                            "sanguineous (bloody)",
                            "serosanguineous (pink)",
                            "purulent (yellow/pus)",
                            "seropurulent (cloudy yellow)",
                          ],
                          value: _reviewed['discharge_type']?.toString(),
                          bindKey: "discharge_type",
                        ),
                        _buildDropdownField(
                          label: "Odor Presence",
                          options: const ["none", "faint", "moderate", "foul", "putrid"],
                          value: _reviewed['odor_presence']?.toString(),
                          bindKey: "odor_presence",
                        ),
                        _buildPainScoreSlider(),
                        _buildDropdownField(
                          label: "Has Infection",
                          options: const ["true", "false"],
                          value: _reviewed['has_infection']?.toString(),
                          bindKey: "has_infection",
                        ),
                        _buildDropdownField(
                          label: "Skin Condition",
                          options: const ["healthy", "dry", "cracked", "macerated", "fragile", "scaling"],
                          value: _reviewed['skin_condition']?.toString(),
                          bindKey: "skin_condition",
                        ),
                      ],
                    ),
                  ),
                _buildSinbadCard(
                  icon: LucideIcons.mapPin,
                  title: "Site",
                  subtitle: "Where is it?",
                  helpText: null,
                  group: "site",
                  options: const [
                    _SinbadOption(label: "Forefoot", isRisk: false),
                    _SinbadOption(label: "Midfoot/Hindfoot", isRisk: true),
                  ],
                ),
                _buildSinbadCard(
                  icon: LucideIcons.triangleAlert,
                  title: "Ischemia",
                  subtitle: "Is the pulse weak?",
                  helpText: null,
                  helpWidget: _buildIschemiaGuide(),
                  group: "ischemia",
                  options: const [
                    _SinbadOption(label: "No", isRisk: false),
                    _SinbadOption(label: "Yes", isRisk: true),
                  ],
                ),
                _buildSinbadCard(
                  icon: LucideIcons.zap,
                  title: "Neuropathy",
                  subtitle: "Loss of feeling?",
                  helpText: null,
                  helpWidget: _buildNeuropathyGuide(),
                  group: "neuropathy",
                  options: const [
                    _SinbadOption(label: "No", isRisk: false),
                    _SinbadOption(label: "Yes", isRisk: true),
                  ],
                ),
                _buildSinbadCard(
                  icon: LucideIcons.bandage,
                  title: "Bacterial",
                  subtitle: "Signs of infection?",
                  helpText: null,
                  helpWidget: _buildBacterialGuide(),
                  group: "infection",
                  options: const [
                    _SinbadOption(label: "No", isRisk: false),
                    _SinbadOption(label: "Yes", isRisk: true),
                  ],
                ),
                _buildSinbadCard(
                  icon: LucideIcons.maximize2,
                  title: "Area",
                  subtitle: "Size of the wound?",
                  helpText: null,
                  group: "area",
                  options: const [
                    _SinbadOption(label: kSinbadAreaSmall, isRisk: false),
                    _SinbadOption(label: kSinbadAreaLarge, isRisk: true),
                  ],
                ),
                _buildSinbadCard(
                  icon: Icons.layers,
                  title: "Depth",
                  subtitle: "How deep is it?",
                  helpText: null,
                  group: "depth",
                  options: const [
                    _SinbadOption(label: "Skin only", isRisk: false),
                    _SinbadOption(label: "Deep/Bone", isRisk: true),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSinbadMeter(score, scoreColor),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildFixedBottomButton(
          reviewSkipped ? "Send SINBAD Assessment" : "Submit Assessment",
          LucideIcons.circleCheck,
          _submitToAnalyzeWound,
        ),
      ],
    );
  }

  Widget _buildAssessmentVoiceCard() {
    final hasAudio = _assessmentAudioPath != null && _assessmentAudioPath!.isNotEmpty;
    final fileName = hasAudio ? File(_assessmentAudioPath!).uri.pathSegments.last : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _assessmentAudioRecording ? Icons.mic_off_rounded : LucideIcons.mic,
                  size: 18,
                  color: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Voice Assessment",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Record, preview, then transcribe to prefill the form.",
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (fileName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
                child: Row(
                  children: [
                  const Icon(LucideIcons.fileText, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _assessmentAudioTranscribing ? null : _toggleAssessmentRecording,
                  icon: Icon(_assessmentAudioRecording ? Icons.stop_rounded : LucideIcons.mic, size: 16),
                  label: Text(_assessmentAudioRecording ? "Stop Recording" : "Record"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _assessmentAudioRecording ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasAudio && !_assessmentAudioTranscribing ? _toggleAssessmentPlayback : null,
                  icon: Icon(_assessmentAudioPlaying ? LucideIcons.pause : LucideIcons.play, size: 16),
                  label: Text(_assessmentAudioPlaying ? "Stop Preview" : "Preview"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasAudio && !_assessmentAudioTranscribing && !_assessmentAudioRecording
                  ? _transcribeAssessmentAudio
                  : null,
              icon: _assessmentAudioTranscribing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.send, size: 16),
              label: Text(_assessmentAudioTranscribing ? "Transcribing..." : "Send Transcribe"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinbadCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? helpText,
    Widget? helpWidget,
    required String group,
    required List<_SinbadOption> options,
  }) {
    final invalidKey = 'sinbad_$group';
    final isInvalid = _assessmentInvalidKeys.contains(invalidKey);
    final hasHelp = (helpText != null && helpText.isNotEmpty) || helpWidget != null;
    final isExpanded = _sinbadHelpExpanded[group] == true;
    return Container(
      key: _assessmentFieldKey(invalidKey),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInvalid ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInvalid ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          width: isInvalid ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isInvalid ? const Color(0xFFEF4444) : const Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  ],
                ),
              ),
              if (hasHelp)
                InkWell(
                  onTap: () => setState(() => _sinbadHelpExpanded[group] = !isExpanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                      size: 24,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
            ],
          ),
          if (isInvalid) ...[
            const SizedBox(height: 8),
            const Text(
              "Required. Please choose one option.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C)),
            ),
          ],
          if (hasHelp) ...[
            const SizedBox(height: 8),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (helpText != null && helpText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(helpText, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ),
                  if (helpWidget != null) helpWidget,
                ],
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options
                .map((opt) => _sinbadChoice(label: opt.label, group: group, isRisk: opt.isRisk))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSinbadMeter(int score, Color scoreColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SINBAD score: $score / 6", style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 6,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score >= 3 ? "High risk: referral recommended." : "Low risk: continue assessment.",
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPainScoreSlider() {
    final raw = _reviewed['pain_score']?.toString();
    final parsed = int.tryParse(raw ?? '');
    final value = parsed == null ? 0 : parsed.clamp(0, 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pain Score (0-10)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: value.toString(),
          onChanged: (v) {
            setState(() {
              _reviewed['pain_score'] = v.round().toString();
            });
          },
        ),
        Text("Selected: $value/10", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProbeToBoneButtons() {
    final value = _reviewed['probe_to_bone_test']?.toString();
    final isYes = value == 'positive' || value == 'yes';
    final isNo = value == 'negative' || value == 'no';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Probe-to-Bone",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _reviewed['probe_to_bone_test'] = isNo ? 'not_performed' : 'negative';
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: isNo ? Colors.blueGrey.withOpacity(0.12) : Colors.white,
                side: BorderSide(color: isNo ? Colors.blueGrey : const Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                "No",
                style: TextStyle(color: isNo ? Colors.blueGrey : Colors.blueGrey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _reviewed['probe_to_bone_test'] = isYes ? 'not_performed' : 'positive';
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: isYes ? Colors.red.withOpacity(0.12) : Colors.white,
                side: BorderSide(color: isYes ? Colors.red : const Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                "Yes",
                style: TextStyle(color: isYes ? Colors.red : Colors.blueGrey, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeepAbscessButtons() {
    final value = _reviewed['has_deep_abscess_or_fasciitis']?.toString();
    final isYes = value == 'true' || value == 'yes';
    final isNo = value == 'false' || value == 'no';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Deep Abscess/Fasciitis",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _reviewed['has_deep_abscess_or_fasciitis'] = isNo ? null : 'false';
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: isNo ? Colors.blueGrey.withOpacity(0.12) : Colors.white,
                side: BorderSide(color: isNo ? Colors.blueGrey : const Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                "No",
                style: TextStyle(color: isNo ? Colors.blueGrey : Colors.blueGrey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _reviewed['has_deep_abscess_or_fasciitis'] = isYes ? null : 'true';
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: isYes ? Colors.red.withOpacity(0.12) : Colors.white,
                side: BorderSide(color: isYes ? Colors.red : const Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(
                "Yes",
                style: TextStyle(color: isYes ? Colors.red : Colors.blueGrey, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIschemiaGuide() {
    const checklist = [
      "Color (pale/blue)",
      "Cold foot",
      "Black tissue (tissue loss)",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tap pulse points you cannot feel.", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.asset("pic/palpation.png", fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        const Text("Pulse points you cannot feel:", style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Column(
          children: List.generate(2, (i) {
            final selected = _ischemiaPoints.contains(i);
            return Padding(
              padding: EdgeInsets.only(bottom: i == 1 ? 0 : 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _ischemiaPoints.remove(i);
                    } else {
                      _ischemiaPoints.add(i);
                    }
                    _reviewed['ischemia_points'] = _ischemiaPoints.toList()..sort();
                    if (_ischemiaPoints.length == 2 || _ischemiaChecklist.isNotEmpty || _ischemiaPulse == "yes") {
                      _sinbadIschemia = "Yes";
                      _reviewed['sinbad_ischemia'] = "Yes";
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? Colors.red.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? Colors.red : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: selected ? Colors.red : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.place, size: 16, color: selected ? Colors.white : Colors.blueGrey),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          i == 0 ? "Posterior Tibial Artery" : "Dorsalis Pedis Artery",
                          style: TextStyle(color: selected ? Colors.red : Colors.blueGrey, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (selected) const Icon(Icons.check_circle, size: 18, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        const Text("Checklist:", style: TextStyle(color: Colors.blueGrey)),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text("No/Weak Pulse"),
          value: _ischemiaPulse == "yes",
          onChanged: (v) {
            setState(() {
              _ischemiaPulse = v == true ? "yes" : null;
              _reviewed['ischemia_pulse'] = _ischemiaPulse;
              if (_ischemiaPulse == "yes" || _ischemiaChecklist.isNotEmpty || _ischemiaPoints.length == 2) {
                _sinbadIschemia = "Yes";
                _reviewed['sinbad_ischemia'] = "Yes";
              }
            });
          },
        ),
        for (final item in checklist)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(item),
            value: _ischemiaChecklist.contains(item),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _ischemiaChecklist.add(item);
                } else {
                  _ischemiaChecklist.remove(item);
                }
                _reviewed['ischemia_checklist'] = _ischemiaChecklist.toList()..sort();
                if (_ischemiaChecklist.isNotEmpty || _ischemiaPoints.length == 2) {
                  _sinbadIschemia = "Yes";
                  _reviewed['sinbad_ischemia'] = "Yes";
                }
              });
            },
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Objective Ischemia Measures", style: TextStyle(color: Colors.blueGrey)),
            TextButton(
              onPressed: () => setState(() => _showObjectiveIschemia = !_showObjectiveIschemia),
              child: Text(_showObjectiveIschemia ? "Hide" : "Show"),
            ),
          ],
        ),
        if (_showObjectiveIschemia) ...[
          const SizedBox(height: 8),
          _buildTextField(
            label: "ABI Value",
            placeholder: "e.g. 0.9",
            keyboardType: TextInputType.number,
            bindKey: "vascular_abi_value",
          ),
          _buildTextField(
            label: "Ankle Pressure (mmHg)",
            placeholder: "e.g. 70",
            keyboardType: TextInputType.number,
            bindKey: "vascular_ankle_pressure_mmHg",
          ),
          _buildTextField(
            label: "Toe Pressure (mmHg)",
            placeholder: "e.g. 45",
            keyboardType: TextInputType.number,
            bindKey: "vascular_toe_pressure_mmHg",
          ),
          _buildTextField(
            label: "TcPO2 (mmHg)",
            placeholder: "e.g. 30",
            keyboardType: TextInputType.number,
            bindKey: "vascular_tcpo2_mmHg",
          ),
          _buildDropdownField(
            label: "Gangrene Extent",
            options: const ["none", "digits_only", "forefoot_midfoot", "heel_full_thickness"],
            value: _reviewed['gangrene_extent']?.toString(),
            bindKey: "gangrene_extent",
          ),
        ],
      ],
    );
  }

  Widget _buildBacterialGuide() {
    const items = [
      "Pus / Goo (Purulent discharge)",
      "Warmth (hotter than other foot)",
      "Swelling (puffy, tight, hard)",
      "Pain (tender or hurts to touch)",
    ];
    const notes = [
      "Thick white/yellow/bloody liquid from wound.",
      "Use back of hand to compare both feet.",
      "Local swelling or induration.",
      "May be absent with neuropathy; don’t rely on pain alone.",
    ];
    final String erythemaExtent = (_reviewed['erythema_extent'] ?? 'none').toString();
    int erythemaIndex;
    switch (erythemaExtent) {
      case 'gt_0_5_cm':
        erythemaIndex = 1;
        break;
      case 'gt_2_cm':
        erythemaIndex = 2;
        break;
      case 'none':
      default:
        erythemaIndex = 0;
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Check all that apply.", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        const Text("Erythema (Redness) Extent", style: TextStyle(color: Colors.blueGrey)),
        Slider(
          value: erythemaIndex.toDouble(),
          min: 0,
          max: 2,
          divisions: 2,
          label: erythemaIndex == 0
              ? "None"
              : (erythemaIndex == 1 ? "> 0.5 cm" : "> 2 cm"),
          onChanged: (v) {
            final idx = v.round();
            String extent;
            switch (idx) {
              case 1:
                extent = 'gt_0_5_cm';
                break;
              case 2:
                extent = 'gt_2_cm';
                break;
              case 0:
              default:
                extent = 'none';
                break;
            }
            setState(() {
              _reviewed['erythema_extent'] = extent;
            });
          },
        ),
        Text(
          erythemaIndex == 0 ? "None" : (erythemaIndex == 1 ? "> 0.5 cm" : "> 2 cm"),
          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
        ),
        for (var i = 0; i < items.length; i++)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(items[i]),
            subtitle: Text(notes[i]),
            value: _infectionChecklist.contains(items[i]),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _infectionChecklist.add(items[i]);
                } else {
                  _infectionChecklist.remove(items[i]);
                }
                _reviewed['infection_checklist'] = _infectionChecklist.toList()..sort();
                if (_infectionChecklist.length >= 2) {
                  _sinbadInfection = "Yes";
                  _reviewed['sinbad_infection'] = "Yes";
                }
              });
            },
          ),
        const SizedBox(height: 4),
        Text("Selected: ${_infectionChecklist.length}/4", style: const TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Deep Infection Indicators", style: TextStyle(color: Colors.blueGrey)),
            TextButton(
              onPressed: () => setState(() => _showDeepInfectionIndicators = !_showDeepInfectionIndicators),
              child: Text(_showDeepInfectionIndicators ? "Hide" : "Show"),
            ),
          ],
        ),
        if (_showDeepInfectionIndicators) ...[
          const SizedBox(height: 8),
          _buildProbeToBoneButtons(),
          _buildDeepAbscessButtons(),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Inflammatory Labs", style: TextStyle(color: Colors.blueGrey)),
            TextButton(
              onPressed: () => setState(() => _showInflammatoryLabs = !_showInflammatoryLabs),
              child: Text(_showInflammatoryLabs ? "Hide" : "Show"),
            ),
          ],
        ),
        if (_showInflammatoryLabs) ...[
          const SizedBox(height: 8),
          _buildTextField(
            label: "WBC Count (cells/µL)",
            placeholder: "e.g. 6500",
            keyboardType: TextInputType.number,
            bindKey: "lab_wbc_count",
          ),
          _buildTextField(
            label: "CRP (mg/L)",
            placeholder: "e.g. 5",
            keyboardType: TextInputType.number,
            bindKey: "lab_crp",
          ),
          _buildTextField(
            label: "ESR (mm/hr)",
            placeholder: "e.g. 20",
            keyboardType: TextInputType.number,
            bindKey: "lab_esr",
          ),
          _buildTextField(
            label: "Procalcitonin (ng/mL)",
            placeholder: "e.g. 0.2",
            keyboardType: TextInputType.number,
            bindKey: "lab_procalcitonin",
          ),
        ],
      ],
    );
  }

  Widget _buildNeuropathyGuide() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Tap the points the patient cannot feel.", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              const r = 12.0;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      "pic/right_foot_numbtest.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  for (var i = 0; i < _neuropathyPointAnchors.length; i++)
                    Positioned(
                      left: (w * _neuropathyPointAnchors[i].dx) - r,
                      top: (h * _neuropathyPointAnchors[i].dy) - r,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_neuropathyPoints.contains(i)) {
                              _neuropathyPoints.remove(i);
                            } else {
                              _neuropathyPoints.add(i);
                            }
                            if (_neuropathyPoints.isNotEmpty) {
                              _sinbadNeuropathy = "Yes";
                              _reviewed['sinbad_neuropathy'] = "Yes";
                            }
                            _reviewed['neuropathy_points'] = _neuropathyPoints.toList()..sort();
                          });
                        },
                        child: Container(
                          width: r * 2,
                          height: r * 2,
                          decoration: BoxDecoration(
                            color: _neuropathyPoints.contains(i) ? Colors.red : Colors.white,
                            border: Border.all(color: Colors.red, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "${i + 1}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _neuropathyPoints.contains(i) ? Colors.white : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text("Selected: ${_neuropathyPoints.length}/9", style: const TextStyle(color: Colors.blueGrey)),
      ],
    );
  }

  void _showHelp(String text) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Help"),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showIschemiaHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pulse Check"),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              final checklist = const [
                "Color (pale/blue)",
                "Cold foot",
                "Black tissue (tissue loss)",
              ];
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text("Tap pulse points you cannot feel."),
                        const SizedBox(height: 4),
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.asset(
                            "pic/palpation.png",
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 4),
                    const Text("Pulse points you cannot feel:", style: TextStyle(color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                        Column(
                          children: List.generate(2, (i) {
                            final selected = _ischemiaPoints.contains(i);
                            return Padding(
                              padding: EdgeInsets.only(bottom: i == 1 ? 0 : 10),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _ischemiaPoints.remove(i);
                                    } else {
                                      _ischemiaPoints.add(i);
                                    }
                                    _reviewed['ischemia_points'] = _ischemiaPoints.toList()..sort();
                                    if (_ischemiaPoints.length == 2 || _ischemiaChecklist.isNotEmpty || _ischemiaPulse == "yes") {
                                      _sinbadIschemia = "Yes";
                                      _reviewed['sinbad_ischemia'] = "Yes";
                                    }
                                  });
                                  setLocal(() {});
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.red.withOpacity(0.12) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: selected ? Colors.red : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: selected ? Colors.red : const Color(0xFFE2E8F0),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.place, size: 16, color: selected ? Colors.white : Colors.blueGrey),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          i == 0 ? "Posterior Tibial Artery" : "Dorsalis Pedis Artery",
                                          style: TextStyle(color: selected ? Colors.red : Colors.blueGrey, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(Icons.check_circle, size: 18, color: Colors.red),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                    const SizedBox(height: 12),
                        const Text("Checklist:", style: TextStyle(color: Colors.blueGrey)),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text("No/Weak Pulse"),
                          value: _ischemiaPulse == "yes",
                          onChanged: (v) {
                            setState(() {
                              _ischemiaPulse = v == true ? "yes" : null;
                          _reviewed['ischemia_pulse'] = _ischemiaPulse;
                          if (_ischemiaPulse == "yes" || _ischemiaChecklist.isNotEmpty || _ischemiaPoints.length == 2) {
                            _sinbadIschemia = "Yes";
                            _reviewed['sinbad_ischemia'] = "Yes";
                          }
                        });
                        setLocal(() {});
                      },
                        ),
                    for (final item in checklist)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item),
                        value: _ischemiaChecklist.contains(item),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _ischemiaChecklist.add(item);
                            } else {
                              _ischemiaChecklist.remove(item);
                            }
                            _reviewed['ischemia_checklist'] = _ischemiaChecklist.toList()..sort();
                            if (_ischemiaChecklist.isNotEmpty || _ischemiaPoints.length == 2) {
                              _sinbadIschemia = "Yes";
                              _reviewed['sinbad_ischemia'] = "Yes";
                            }
                          });
                          setLocal(() {});
                        },
                      ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  void _showBacterialHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Infection Checklist"),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              final items = const [
                "Pus / Goo (Purulent discharge)",
                "Redness (Erythema > 0.5 cm)",
                "Warmth (hotter than other foot)",
                "Swelling (puffy, tight, hard)",
                "Pain (tender or hurts to touch)",
              ];
              final notes = const [
                "Thick white/yellow/bloody liquid from wound.",
                "Red skin spreading around the sore.",
                "Use back of hand to compare both feet.",
                "Local swelling or induration.",
                "May be absent with neuropathy; don’t rely on pain alone.",
              ];
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Check all that apply."),
                        const SizedBox(height: 8),
                        for (var i = 0; i < items.length; i++)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(items[i]),
                            subtitle: Text(notes[i]),
                            value: _infectionChecklist.contains(items[i]),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _infectionChecklist.add(items[i]);
                                } else {
                                  _infectionChecklist.remove(items[i]);
                                }
                                _reviewed['infection_checklist'] = _infectionChecklist.toList()..sort();
                                if (_infectionChecklist.length >= 2) {
                                  _sinbadInfection = "Yes";
                                  _reviewed['sinbad_infection'] = "Yes";
                                  _reviewed['has_infection'] = 'true';
                                } else {
                                  _sinbadInfection = "No";
                                  _reviewed['sinbad_infection'] = "No";
                                  _reviewed['has_infection'] = 'false';
                                }
                              });
                              setLocal(() {});
                            },
                          ),
                        const SizedBox(height: 4),
                        Text(
                          "Selected: ${_infectionChecklist.length}/5",
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  void _showNeuropathyHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Touch Test"),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    const Text("Tap the points the patient cannot feel."),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          const r = 12.0;
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  "pic/right_foot_numbtest.png",
                                  fit: BoxFit.contain,
                                ),
                              ),
                              for (var i = 0; i < _neuropathyPointAnchors.length; i++)
                                Positioned(
                                  left: (w * _neuropathyPointAnchors[i].dx) - r,
                                  top: (h * _neuropathyPointAnchors[i].dy) - r,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_neuropathyPoints.contains(i)) {
                                          _neuropathyPoints.remove(i);
                                        } else {
                                          _neuropathyPoints.add(i);
                                        }
                                        if (_neuropathyPoints.isNotEmpty) {
                                          _sinbadNeuropathy = "Yes";
                                          _reviewed['sinbad_neuropathy'] = "Yes";
                                        }
                                        _reviewed['neuropathy_points'] = _neuropathyPoints.toList()..sort();
                                      });
                                      setLocal(() {});
                                    },
                                    child: Container(
                                      width: r * 2,
                                      height: r * 2,
                                      decoration: BoxDecoration(
                                        color: _neuropathyPoints.contains(i) ? Colors.red : Colors.white,
                                        border: Border.all(color: Colors.red, width: 2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${i + 1}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _neuropathyPoints.contains(i) ? Colors.white : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Selected: ${_neuropathyPoints.length}/9", style: const TextStyle(color: Colors.blueGrey)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  Widget _sinbadChoice({required String label, required String group, required bool isRisk}) {
    bool selected;
    switch (group) {
      case "site":
        selected = _sinbadSite == label;
        break;
      case "ischemia":
        selected = _sinbadIschemia == label;
        break;
      case "neuropathy":
        selected = _sinbadNeuropathy == label;
        break;
      case "infection":
        selected = _sinbadInfection == label;
        break;
      case "area":
        selected = _sinbadArea == label;
        break;
      case "depth":
        selected = _sinbadDepth == label;
        break;
      default:
        selected = false;
    }

    final Color selectedColor = isRisk ? Colors.red : const Color(0xFF0D9488);
    final Color bg = selected ? selectedColor.withOpacity(0.12) : Colors.white;
    final Color border = selected ? selectedColor : const Color(0xFFE2E8F0);
    final Color textColor = selected ? selectedColor : Colors.blueGrey;

    return InkWell(
      onTap: () {
        setState(() {
          switch (group) {
            case "site":
              _sinbadSite = label;
              _reviewed['sinbad_site'] = label;
              break;
            case "ischemia":
              _sinbadIschemia = label;
              _reviewed['sinbad_ischemia'] = label;
              break;
            case "neuropathy":
              _sinbadNeuropathy = label;
              _reviewed['sinbad_neuropathy'] = label;
              break;
            case "infection":
              _sinbadInfection = label;
              _reviewed['sinbad_infection'] = label;
              _reviewed['has_infection'] = (label == 'Yes') ? 'true' : 'false';
              break;
            case "area":
              _sinbadArea = label;
              _reviewed['sinbad_area'] = label;
              break;
            case "depth":
              _sinbadDepth = label;
              _reviewed['sinbad_depth'] = label;
              break;
          }
          _assessmentInvalidKeys.remove('sinbad_$group');
          _maybeShowHighRisk(_calcSinbadScore());
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRisk ? Icons.warning_amber_rounded : LucideIcons.circleCheck,
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _SinbadOption {
  final String label;
  final bool isRisk;
  const _SinbadOption({required this.label, required this.isRisk});
}
