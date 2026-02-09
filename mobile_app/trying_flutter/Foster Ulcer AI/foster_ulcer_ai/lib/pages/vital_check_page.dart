part of '../widgets/main_navigation_screen.dart';

extension _VitalCheckPage on _MainNavigationScreenState {
  Widget _buildVitalCheckPage() {
    return Column(
      children: [
        _buildHeader("Vital Check", onBack: () => _navigateTo('intake')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle(LucideIcons.heartPulse, "Blood Pressure"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ["Low", "< 90/60"],
                  ["Normal", "90/60 - 120/80"],
                  ["High", "130-139/80-89"],
                  ["Very High", ">= 140/90"],
                ].map((parts) {
                  final label = parts[0] as String;
                  final range = parts[1] as String;
                  final selected = _bpLevel == label;
                  return FilterChip(
                    label: SizedBox(
                      width: 120,
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w800 : FontWeight.bold,
                              color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                            ),
                            children: [
                              TextSpan(text: label),
                              const TextSpan(text: "\n"),
                              TextSpan(
                                text: range,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 11,
                                  color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _bpLevel = label),
                    selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF0D9488),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(LucideIcons.droplet, "Blood Sugar"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ["Low", "< 70"],
                  ["Normal", "70 - 140"],
                  ["High", "141 - 200"],
                  ["Very High", "> 200"],
                ].map((parts) {
                  final label = parts[0] as String;
                  final range = parts[1] as String;
                  final selected = _sugarLevel == label;
                  return FilterChip(
                    label: SizedBox(
                      width: 120,
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w800 : FontWeight.bold,
                              color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                            ),
                            children: [
                              TextSpan(text: label),
                              const TextSpan(text: "\n"),
                              TextSpan(
                                text: range,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 11,
                                  color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _sugarLevel = label),
                    selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF0D9488),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(LucideIcons.heart, "Heart Rate"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ["Low", "< 60"],
                  ["Normal", "60 - 100"],
                  ["High", "> 100"],
                ].map((parts) {
                  final label = parts[0] as String;
                  final range = parts[1] as String;
                  final selected = _heartRateLevel == label;
                  return FilterChip(
                    label: SizedBox(
                      width: 120,
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w800 : FontWeight.bold,
                              color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                            ),
                            children: [
                              TextSpan(text: label),
                              const TextSpan(text: "\n"),
                              TextSpan(
                                text: range,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 11,
                                  color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _heartRateLevel = label),
                    selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF0D9488),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(LucideIcons.thermometer, "Body Temp"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ["Normal", "36.1 - 37.2°C"],
                  ["Warm", "37.3 - 37.9°C"],
                  ["High", "> 38°C"],
                ].map((parts) {
                  final label = parts[0] as String;
                  final range = parts[1] as String;
                  final selected = _tempLevel == label;
                  return FilterChip(
                    label: SizedBox(
                      width: 120,
                      child: Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w800 : FontWeight.bold,
                              color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                            ),
                            children: [
                              TextSpan(text: label),
                              const TextSpan(text: "\n"),
                              TextSpan(
                                text: range,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 11,
                                  color: selected ? const Color(0xFF0D9488) : Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _tempLevel = label),
                    selectedColor: const Color(0xFF0D9488).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF0D9488),
                  );
                }).toList(),
              ),
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
                onPressed: () => _navigateTo('camera'),
                icon: const Icon(LucideIcons.camera),
                label: const Text("Wound is present", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _navigateTo('dashboard'),
                icon: const Icon(LucideIcons.house),
                label: const Text("Wound is not present", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  minimumSize: const Size(double.infinity, 56),
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
