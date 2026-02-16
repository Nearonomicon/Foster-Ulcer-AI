part of '../widgets/main_navigation_screen.dart';

extension _PatientSearchPage on _MainNavigationScreenState {
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(14)),
                          child: const Center(child: Icon(LucideIcons.user, size: 18, color: Color(0xFF0D9488))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((p['name'] ?? '').toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text((p['id'] ?? '').toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedPatient == null) return;
                  // Prepare profile for the follow-up case and navigate directly to camera
                  _patientProfile
                    ..clear()
                    ..addAll({
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _patientProfile.clear();
                  _patientProfileSaved = false;
                  _selectedPatient = null;
                  _patientNameCtrl.clear();
                  _dobCtrl.clear();
                  _patientPhoneCtrl.clear();
                  _patientHeightCtrl.clear();
                  _patientWeightCtrl.clear();
                  _patientHistoryCtrl.clear();
                  _patientPhoto = null;
                  _navigateTo('intake');
                },
                icon: const Icon(LucideIcons.userPlus),
                label: const Text("Register New Patient", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
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
