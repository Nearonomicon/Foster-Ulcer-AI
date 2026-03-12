part of '../widgets/main_navigation_screen.dart';

extension _CasesPage on _MainNavigationScreenState {
  Widget _buildCasesTab() {
    if (_caseItems.isEmpty && !_casesLoading && _casesError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCasesList());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              "Patient Cases",
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const Text("Raipur Unit 4 progress", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ]),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_casesLoading) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
              }
              if (_casesError != null) {
                return Center(child: Text(_casesError!, style: const TextStyle(color: Colors.redAccent)));
              }
              if (_caseItems.isEmpty) {
                return const Center(child: Text("No cases found."));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _caseItems.length,
                itemBuilder: (context, index) => _buildPatientListTile(_caseItems[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCasesPage() {
    final pid = _patientProfile['patient_id']?.toString() ?? _selectedPatient?['patient_id']?.toString();
    if (!_casesLoading && _casesError == null) {
      final needsFetch = pid != null && pid.isNotEmpty && _casesFilterPatientId != pid;
      if (needsFetch) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _caseItems = [];
          _fetchCasesList(patientId: pid);
        });
      }
    }
    return Column(
      children: [
        _buildHeader("Patient Cases", onBack: () => _navigateTo('patient_search')),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_casesLoading) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
              }
              if (_casesError != null) {
                return Center(child: Text(_casesError!, style: const TextStyle(color: Colors.redAccent)));
              }
              if (pid == null || pid.isEmpty) {
                return const Center(child: Text("No patient selected."));
              }
              if (_caseItems.isEmpty) {
                return const Center(child: Text("No cases found for this patient."));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _caseItems.length,
                itemBuilder: (context, index) => _buildPatientListTile(
                  _caseItems[index],
                  onTap: () => _enterFollowUpVitals(_caseItems[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
