part of '../widgets/main_navigation_screen.dart';

extension _ProfilePage on _MainNavigationScreenState {
  Widget _buildProfileTab() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAboutUsButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(height: 16),
                      const Text("Nurse Ananya Sharma", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text("Registered Nurse • Senior Lead", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildNotificationButton(),
            ],
          ),
          const SizedBox(height: 40),
          _buildProfileTile(LucideIcons.user, "Personal Information"),
          _buildProfileTile(LucideIcons.shieldCheck, "Security & Pin"),
          _buildProfileTile(LucideIcons.settings, "App Settings"),
          _buildProfileTile(LucideIcons.logOut, "Logout", color: Colors.redAccent),
        ],
      );

  Widget _buildAboutUsButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAboutUsDialog,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAboutUsDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "About us",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'pic/app_logo_bg.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 20),
                  Image.asset(
                    'pic/ygh_logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "This application is developed in collaboration between Foster Institute and Yangon General Hospital to enhance detection, monitoring and management of DFUs using AI and digital health technologies.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
