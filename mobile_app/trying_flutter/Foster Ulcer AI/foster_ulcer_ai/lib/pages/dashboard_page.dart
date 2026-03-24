part of '../widgets/main_navigation_screen.dart';

extension _DashboardPage on _MainNavigationScreenState {
  Widget _buildDashboard() {
    if (!_dashboardFetchedOnce && !_dashboardLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDashboard());
    }

    final activePatientsCount = (_dashboardTotalActivePatient ?? 0).toString();
    final todayTaskText = (_dashboardTodayTaskNo ?? 0).toString();
    final upcomingPlans = _dashboardUpcomingPlan.take(4).toList();

    return RefreshIndicator(
      color: const Color(0xFF0D9488),
      onRefresh: _fetchDashboard,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_dashboardLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(color: Color(0xFF0D9488), minHeight: 2),
            ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  "Hello!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Text("ABC Clinic • Unit 4", style: TextStyle(fontSize: 14, color: Colors.grey)),
              ]),
              Row(
                children: [
                  _buildNotificationButton(),
                  const SizedBox(width: 12),
                  _buildProfileAvatar(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatCard(
            icon: LucideIcons.users,
            label: "Active Patients",
            value: activePatientsCount,
            subValue: "",
            color: Colors.blue.shade50,
            iconColor: Colors.blue.shade600,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              setState(() {
                _activeTab = 1;
                _currentStep = 'dashboard';
                _tasksFetchedOnce = false;
              });
              _fetchTasksList();
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  const Icon(LucideIcons.listTodo, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayTaskText,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Text(
                          "TASKS DUE TODAY",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: Colors.white70),
                ],
              ),
            ),
          ),
          if (_dashboardError != null) ...[
            const SizedBox(height: 16),
            Text(_dashboardError!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _followUpFlow = false;
              _resetCaseInputs();
              _navigateTo('patient_search');
            },
            icon: const Icon(LucideIcons.circlePlus, size: 25),
            label: const Text("Create Case", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              _patientProfile
                ..clear()
                ..addAll({
                  'patient_name': null,
                  'phone_no': '0000000000',
                  'dob': null,
                  'gender': null,
                  'height_cm': null,
                  'weight_kg': null,
                  'medical_history': null,
                });
              setState(() {
                _patientProfileSaved = true;
                _emergencyBypassProfile = true;
              });
              _navigateTo('camera');
            },
            icon: const Icon(LucideIcons.triangleAlert),
            label: const Text("Emergency Escalate", style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              _followUpFlow = true;
              _resetCaseInputs();
              _clearVitalsInfo();
              _resetAssessmentInputs();
              _navigateTo('patient_search');
            },
            icon: const Icon(LucideIcons.search),
            label: const Text("Follow-up Case", style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D9488),
              side: const BorderSide(color: Color(0xFF0D9488)),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 32),
          const Text("Upcoming Care Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (upcomingPlans.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                "No upcoming care schedule.",
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
            )
          else
            ...upcomingPlans.map(_buildDashboardUpcomingCard),
        ],
      ),
    );
  }

  Widget _buildDashboardUpcomingCard(Map<String, dynamic> p) {
    final urgencyColor = _urgencyColor(p['urgency']?.toString());
    final image = p['image'] ?? p['image_url'] ?? p['patient_photo_url'] ?? '';
    final patientName = (p['patient_name'] ?? p['name'] ?? 'Unknown').toString();
    final caseId = (p['case_id'] ?? '-').toString();
    final status = p['status']?.toString() ?? "unknown";
    final dueRaw = (p['task_due'] ?? p['due_date'] ?? '').toString();

    String formatDue(dynamic raw) {
      if (raw == null || raw.toString().isEmpty) return "-";
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return "$y-$m-$d";
      } catch (_) {
        return raw.toString();
      }
    }

    return GestureDetector(
      onTap: () async {
        if (caseId.isEmpty || caseId == '-') return;
        _previousStep = 'dashboard';
        _previousTab = _activeTab;
        final ok = await _fetchCaseDetail(caseId);
        if (!ok || !mounted) return;
        _navigateTo('case_detail', patient: p);
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (image is String && image.isNotEmpty)
                      ? Image.network(
                          image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 50,
                            height: 50,
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.broken_image, size: 18),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.person, size: 18),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Due: ${formatDue(dueRaw)}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Case: $caseId",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _urgencyLabel(p['urgency']?.toString()),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: urgencyColor,
                ),
              ),
            ),
          ),
          Positioned(
            top: 36,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBgColor(status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _statusFgColor(status),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
