part of '../widgets/main_navigation_screen.dart';

extension _PatientSearchPage on _MainNavigationScreenState {
  Widget _buildPatientSearch() {
    if (_patientItems.isEmpty && !_patientsLoading && _patientsError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPatientList());
    }
    final q = _patientSearchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _patientItems
        : _patientItems.where((p) {
            final name = (p['patient_name'] ?? '').toString().toLowerCase();
            final id = (p['patient_id'] ?? '').toString().toLowerCase();
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
              if (_patientsLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
              else if (_patientsError != null)
                Center(child: Text(_patientsError!, style: const TextStyle(color: Colors.redAccent)))
              else if (filtered.isEmpty)
                const Center(child: Text("No active patients found.")),
              ...filtered.map((p) {
                final bool selected = _selectedPatient != null && _selectedPatient!['patient_id'] == p['patient_id'];
                final photoUrl = p['photo_url']?.toString() ?? '';
                return GestureDetector(
                  onTap: () => setState(() {
                    if (_selectedPatient != null && _selectedPatient!['patient_id'] == p['patient_id']) {
                      _selectedPatient = null;
                    } else {
                      _selectedPatient = p;
                    }
                  }),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(14)),
                          child: photoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    photoUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(
                                      child: Icon(LucideIcons.user, size: 18, color: Color(0xFF0D9488)),
                                    ),
                                  ),
                                )
                              : const Center(child: Icon(LucideIcons.user, size: 18, color: Color(0xFF0D9488))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((p['patient_name'] ?? '').toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text((p['patient_id'] ?? '').toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                        ),
                        if (selected) const Icon(LucideIcons.circleCheck, color: Color(0xFF0D9488), size: 18)
                        else
                          Icon(LucideIcons.circle, color: TWColors.slate.shade300, size: 18),
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
              OutlinedButton.icon(
                onPressed: () {
                  if (_selectedPatient != null) {
                    _prefillIntakeFromSelectedPatient(_selectedPatient!);
                    _patientProfileSaved = false;
                    _navigateTo('intake');
                    return;
                  }
                  _followUpFlow = false;
                  _patientProfile.clear();
                  _patientProfileSaved = false;
                  _selectedPatient = null;
                  _patientNameCtrl.clear();
                  _nrcIdCtrl.clear();
                  _dobCtrl.clear();
                  _patientPhoneCtrl.clear();
                  _patientHeightCtrl.clear();
                  _patientWeightCtrl.clear();
                  _patientHistoryCtrl.clear();
                  _patientPhoto = null;
                  _navigateTo('intake');
                },
                icon: Icon(_selectedPatient != null ? LucideIcons.arrowRight : LucideIcons.userPlus),
                label: Text(
                  _selectedPatient != null ? "Proceed to Patient Profile" : "Register New Patient",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _selectedPatient != null ? Colors.white : const Color(0xFF0D9488),
                  backgroundColor: _selectedPatient != null ? const Color(0xFF0D9488) : Colors.transparent,
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
