part of '../widgets/main_navigation_screen.dart';

extension _ResponseViewPage on _MainNavigationScreenState {
  Widget _buildResponseView() {
    final bool isFillin = _responseMode == 'fillin';
    return Column(
      children: [
        _buildHeader(
          isFillin ? "AI Extraction" : "Clinical Summary",
          onBack: () => isFillin ? _navigateTo('camera') : _navigateTo('assessment'),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(LucideIcons.code, size: 18, color: Color(0xFF0D9488)),
                  const SizedBox(width: 10),
                  Text(
                    isFillin ? "RAW JSON" : "RAW TEXT",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1, color: Color(0xFF0D9488)),
                  )
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: SelectableText(
                    _rawResponse ?? "No data available.",
                    style: GoogleFonts.firaCode(fontSize: 13, color: Colors.blueGrey.shade800),
                  ),
                ),
              ]),
            ),
          ),
        ),
        isFillin
            ? _buildFixedBottomButton("Proceed to Checklist", LucideIcons.arrowRight, () => _navigateTo('assessment'))
            : _buildFixedBottomButton("Back to Dashboard", LucideIcons.house, () => _navigateTo('dashboard')),
      ],
    );
  }
}
