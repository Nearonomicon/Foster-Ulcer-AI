part of '../widgets/main_navigation_screen.dart';

extension _CasesPage on _MainNavigationScreenState {
  Widget _buildCasesTab() {
    if (!_casesFetchedOnce && !_casesLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCasesList());
    }

    final q = _casesSearchQuery.trim().toLowerCase();
    final statusFilter = _casesStatusFilter.toLowerCase();
    final urgencyFilter = _casesUrgencyFilter.toLowerCase();

    final filtered = _caseItems.where((c) {
      final id = (c['case_id'] ?? c['id'] ?? '').toString().toLowerCase();
      final pid = (c['patient_id'] ?? '').toString().toLowerCase();
      final patientName = (c['patient_name'] ?? c['name'] ?? '').toString().toLowerCase();
      final status = (c['status'] ?? '').toString().toLowerCase();
      final urgency = (c['urgency'] ?? '').toString().toLowerCase();

      final matchesSearch = q.isEmpty || id.contains(q) || pid.contains(q) || patientName.contains(q) || status.contains(q);
      final matchesStatus = statusFilter == 'all' || status == statusFilter;
      final matchesUrgency = urgencyFilter == 'all' || urgency == urgencyFilter;

      return matchesSearch && matchesStatus && matchesUrgency;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      "Patient Cases",
                      style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    const Text("Raipur Unit 4 progress", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ]),
                ),
                const SizedBox(width: 12),
                _buildNotificationButton(),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _casesSearchQuery = v),
              decoration: InputDecoration(
                hintText: "Search by Case ID, Patient ID, Patient Name, Status",
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.blueGrey),
                suffixIcon: _casesSearchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: Colors.blueGrey),
                        onPressed: () => setState(() => _casesSearchQuery = ''),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCasesFilterDropdown(
                    label: "Status",
                    value: _casesStatusFilter,
                    items: const [
                      "ALL",
                      "CREATION",
                      "ANALYZING",
                      "DOCTOR_REVIEW",
                      "PLAN_ISSUED",
                      "APPOINTMENT",
                      "REQUEST_CLOSE",
                      "COMPLETED",
                    ],
                    onChanged: (value) => setState(() => _casesStatusFilter = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCasesFilterDropdown(
                    label: "Urgency",
                    value: _casesUrgencyFilter,
                    items: const ["ALL", "URGENT", "MEDIUM", "ROUTINE"],
                    onChanged: (value) => setState(() => _casesUrgencyFilter = value),
                  ),
                ),
              ],
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
                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [Center(child: Padding(padding: EdgeInsets.only(top: 80), child: Text("No cases match the current filters.")))],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final currentImage = item['current_image'] is Map
                        ? Map<String, dynamic>.from(item['current_image'])
                        : <String, dynamic>{};
                    final displayItem = Map<String, dynamic>.from(item);
                    final currentImageUrl = currentImage['image_folder_url']?.toString();
                    if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
                      displayItem['image_url'] = currentImageUrl;
                    }
                    return _buildPatientListTile(
                      displayItem,
                      onTap: () async {
                        final caseId = item['case_id'] ?? item['id'];
                        if (caseId == null) return;
                        _previousStep = 'dashboard';
                        _previousTab = _activeTab;
                        final ok = await _fetchCaseDetail(caseId.toString());
                        if (!ok || !mounted) return;
                        _navigateTo('case_detail', patient: item);
                      },
                    );
                  },
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

  Widget _buildCasesFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.blueGrey),
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      "$label: $e",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }
}
