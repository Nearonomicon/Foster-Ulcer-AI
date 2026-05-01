part of '../widgets/main_navigation_screen.dart';

extension _IntakePage on _MainNavigationScreenState {
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
                  onTap: () => _showPhotoSourceSheet(_pickPatientPhoto),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.2), width: 3),
                    ),
                    child: _patientPhoto != null
                        ? ClipOval(child: Image.file(File(_patientPhoto!.path), fit: BoxFit.cover))
                        : (_patientPhotoUrl != null && _patientPhotoUrl!.isNotEmpty)
                            ? ClipOval(child: Image.network(_patientPhotoUrl!, fit: BoxFit.cover))
                            : Icon(LucideIcons.user, size: 48, color: TWColors.slate.shade300),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showPhotoSourceSheet(_pickPatientPhoto),
                  icon: const Icon(LucideIcons.imagePlus, size: 16),
                  label: Text(
                    (_patientPhoto == null && (_patientPhotoUrl == null || _patientPhotoUrl!.isEmpty)) ? "Add Patient Photo" : "Change Photo",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      _buildFormLabel("NRC ID"),
      TextFormField(
        controller: _nrcIdCtrl,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: _inputDeco(LucideIcons.idCard, "NRC ID"),
      ),
      const SizedBox(height: 20),
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
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildFormLabel("PHONE NO"),
          TextFormField(
            controller: _patientPhoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: _inputDeco(LucideIcons.phone, "+91 00000 00000"),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildFormLabel("HEIGHT (CM)"),
                TextFormField(controller: _patientHeightCtrl, decoration: _inputDeco(LucideIcons.ruler, "Height"))
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildFormLabel("WEIGHT (KG)"),
                TextFormField(controller: _patientWeightCtrl, decoration: _inputDeco(LucideIcons.scale, "Weight"))
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          _buildFormLabel("DIABETES"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ["Yes", "No"].map((label) {
                    final bool selected = _hasDiabetes == label;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _hasDiabetes = label;
                          if (label == "No") {
                            _diabetesYears = null;
                            _riskHistory.clear();
                            _complications.clear();
                            _otherCompCtrl.clear();
                          }
                        });
                      },
                      selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                      ),
                    );
                  }).toList(),
                ),
                if (_hasDiabetes == "Yes") ...[
                  const SizedBox(height: 16),
                  const Text("Years of Diabetes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["<1y", "1-5y", "5-10y", ">10y"].map((label) {
                      final bool selected = _diabetesYears == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _diabetesYears = label),
                        selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Risk History", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["Past Ulcer", "Prior Amputation"].map((label) {
                      final bool selected = _riskHistory.contains(label);
                      return FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _riskHistory.add(label);
                          } else {
                            _riskHistory.remove(label);
                          }
                        }),
                        selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF0D9488),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Complications", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["Eyes (Retinopathy)", "Heart", "Kidney"].map((label) {
                      final bool selected = _complications.contains(label);
                      return FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _complications.add(label);
                          } else {
                            _complications.remove(label);
                          }
                        }),
                        selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF0D9488),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildFormLabel("OTHER MEDICAL HISTORY"),
          TextFormField(
            controller: _otherCompCtrl,
            decoration: _inputDeco(LucideIcons.clipboard, "Add other medical history"),
          ),
          if (_patientProfileSaved) _buildSuccessBanner(),
          const SizedBox(height: 120),
        ]),
      ),
      _buildIntakeFooter(),
    ]);
  }
}
