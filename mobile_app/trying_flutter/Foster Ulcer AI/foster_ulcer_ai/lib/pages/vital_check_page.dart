part of '../widgets/main_navigation_screen.dart';

extension _VitalCheckPage on _MainNavigationScreenState {
  Widget _buildVitalCheckPage() {
    return Column(
      children: [
        _buildHeader("Vital Check", onBack: () => _navigateTo('intake')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle(LucideIcons.heartPulse, "Blood Pressure"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildVitalInputCard(
                      label: "Systolic",
                      hint: "120",
                      unit: "mmHg",
                      icon: LucideIcons.heartPulse,
                      keyboardType: TextInputType.number,
                      bindKey: "blood_pressure_systolic",
                      onChanged: (_) => setState(_syncBloodPressureValue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVitalInputCard(
                      label: "Diastolic",
                      hint: "80",
                      unit: "mmHg",
                      icon: LucideIcons.activity,
                      keyboardType: TextInputType.number,
                      bindKey: "blood_pressure_diastolic",
                      onChanged: (_) => setState(_syncBloodPressureValue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  "Saved as: ${_reviewed['blood_pressure']?.toString().isNotEmpty == true ? _reviewed['blood_pressure'] : '--/--'}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(LucideIcons.droplet, "Blood Sugar"),
              const SizedBox(height: 12),
              _buildVitalInputCard(
                label: "Blood Sugar",
                hint: "110",
                unit: "mg/dL",
                icon: LucideIcons.droplet,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                bindKey: "blood_sugar",
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(LucideIcons.heart, "Heart Rate"),
              const SizedBox(height: 12),
              _buildVitalInputCard(
                label: "Heart Rate",
                hint: "72",
                unit: "bpm",
                icon: LucideIcons.heart,
                keyboardType: TextInputType.number,
                bindKey: "heart_rate",
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(LucideIcons.wind, "Respiratory Rate"),
              const SizedBox(height: 12),
              _buildVitalInputCard(
                label: "Respiratory Rate",
                hint: "16",
                unit: "breaths/min",
                icon: LucideIcons.wind,
                keyboardType: TextInputType.number,
                bindKey: "respiratory_rate",
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(LucideIcons.thermometer, "Body Temp"),
              const SizedBox(height: 12),
              _buildVitalInputCard(
                label: "Temperature",
                hint: "36.8",
                unit: "°C",
                icon: LucideIcons.thermometer,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                bindKey: "temperature",
              ),
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
                onPressed: () async {
                  final ok = await _createCaseFromVitals();
                  if (!mounted || !ok) return;
                  setState(() => _woundNotPresentFlow = false);
                  _navigateTo('camera');
                },
                icon: const Icon(LucideIcons.camera),
                label: const Text("Wound is present", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await _createCaseFromVitals();
                  if (!mounted || !ok) return;
                  setState(() => _woundNotPresentFlow = true);
                  _navigateTo('assessment');
                },
                icon: const Icon(LucideIcons.house),
                label: const Text("Wound is not present", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _syncBloodPressureValue() {
    final systolic = _reviewed['blood_pressure_systolic']?.toString().trim() ?? '';
    final diastolic = _reviewed['blood_pressure_diastolic']?.toString().trim() ?? '';
    if (systolic.isEmpty && diastolic.isEmpty) {
      _reviewed.remove('blood_pressure');
      return;
    }
    _reviewed['blood_pressure'] = "$systolic/$diastolic";
  }

  Widget _buildVitalInputCard({
    required String label,
    required String hint,
    required String unit,
    required IconData icon,
    required TextInputType keyboardType,
    required String bindKey,
    ValueChanged<String>? onChanged,
  }) {
    final initialValue = _reviewed[bindKey]?.toString().trim() ?? '';
    final controller = _ctrl(bindKey, initial: initialValue);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final isPrefilled = initialValue.isNotEmpty && !_editedPrefillFields.contains(bindKey);
              return TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                onChanged: (text) {
                  _editedPrefillFields.add(bindKey);
                  _reviewed[bindKey] = text.trim();
                  onChanged?.call(text);
                },
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isPrefilled ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  suffixText: unit,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
