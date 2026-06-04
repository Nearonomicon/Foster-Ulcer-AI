part of '../widgets/main_navigation_screen.dart';

extension _DashboardPage on _MainNavigationScreenState {
  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Hello, Nurse",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Text("Raipur Rural Clinic • Unit 4", style: TextStyle(fontSize: 14, color: Colors.grey)),
            ]),
            _buildProfileAvatar(),
          ],
        ),
        const SizedBox(height: 24),
        _buildStatCard(
          icon: LucideIcons.users,
          label: "Total Patients",
          value: "48",
          subValue: "3 Active",
          color: Colors.blue.shade50,
          iconColor: Colors.blue.shade600,
        ),
        const SizedBox(height: 16),
        _buildActionCard(),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _navigateTo('patient_search'),
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
        const SizedBox(height: 32),
        const Text("Upcoming Care Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._patients.take(3).map((p) => _buildPatientListTile(p)),
      ],
    );
  }
}
