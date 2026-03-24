part of '../widgets/main_navigation_screen.dart';

extension _ProfilePage on _MainNavigationScreenState {
  Widget _buildProfileTab() => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
}
