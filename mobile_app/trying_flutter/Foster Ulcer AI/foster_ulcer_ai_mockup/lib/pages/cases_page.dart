part of '../widgets/main_navigation_screen.dart';

extension _CasesPage on _MainNavigationScreenState {
  Widget _buildCasesTab() {
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _patients.length,
            itemBuilder: (context, index) => _buildPatientListTile(_patients[index]),
          ),
        ),
      ],
    );
  }
}
