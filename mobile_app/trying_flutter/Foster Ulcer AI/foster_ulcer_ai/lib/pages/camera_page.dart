part of '../widgets/main_navigation_screen.dart';

extension _CameraPage on _MainNavigationScreenState {
  Widget _buildARCamera() {
    return Container(
      color: Colors.black,
      child: Stack(children: [
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 2), borderRadius: BorderRadius.circular(32)),
            child: const Center(
              child: Text(
                "ALIGN WOUND",
                style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(icon: const Icon(LucideIcons.x, color: Colors.white), onPressed: () => _navigateTo('vital_check_page')),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(LucideIcons.folderOpen, size: 16),
                label: const Text("BROWSE"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, shape: const StadiumBorder()),
              )
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "LIGHTING OPTIMAL",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
