part of '../widgets/main_navigation_screen.dart';

extension _CasesPage on _MainNavigationScreenState {
  Widget _buildCasesTab() {
    if (!_casesFetchedOnce && !_casesLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCasesList());
    }
    final q = _patientSearchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _caseItems
        : _caseItems.where((c) {
            final id = (c['case_id'] ?? c['id'] ?? '').toString().toLowerCase();
            final pid = (c['patient_id'] ?? '').toString().toLowerCase();
            final status = (c['status'] ?? '').toString().toLowerCase();
            return id.contains(q) || pid.contains(q) || status.contains(q);
          }).toList();
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
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
                      decoration: const InputDecoration(hintText: "Search by Case ID, Patient ID, Status", border: InputBorder.none),
                      onChanged: (v) => setState(() => _patientSearchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0D9488),
            onRefresh: () async {
              await _fetchCasesList();
            },
            child: Builder(
              builder: (context) {
                if (_casesLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
                }
                if (_casesError != null) {
                  return Center(child: Text(_casesError!, style: const TextStyle(color: Colors.redAccent)));
                }
                if (_caseItems.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [Center(child: Padding(padding: EdgeInsets.only(top: 80), child: Text("No cases found.")))],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildPatientListTile(
                    filtered[index],
                    onTap: () async {
                      final caseId = filtered[index]['case_id'] ?? filtered[index]['id'];
                      if (caseId == null) return;
                      _previousStep = 'dashboard';
                      _previousTab = _activeTab;
                      final ok = await _fetchCaseDetail(caseId.toString());
                      if (!ok || !mounted) return;
                      _navigateTo('case_detail', patient: filtered[index]);
                    },
                  ),
                );
              },
            ),
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
