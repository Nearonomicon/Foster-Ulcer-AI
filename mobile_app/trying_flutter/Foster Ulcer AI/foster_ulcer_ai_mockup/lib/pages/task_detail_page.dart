part of '../widgets/main_navigation_screen.dart';

extension _TaskDetailPage on _MainNavigationScreenState {
  Widget _buildTaskDetailPage() {
    final t = _getSelectedTask();
    final p = _getSelectedTaskPatient();

    if (t == null || p == null) {
      return Column(
        children: [
          _buildHeader("Task Detail", onBack: () {
            setState(() {
              _currentStep = 'dashboard';
              _activeTab = 1; // back to Tasks tab
            });
          }),
          const Expanded(child: Center(child: Text("Task not found."))),
        ],
      );
    }

    String fmtDueFull(String? iso) {
      if (iso == null || iso.isEmpty) return "TBD";
      try {
        final dt = DateTime.parse(iso).toLocal();
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm";
      } catch (_) {
        return iso;
      }
    }

    final status = (t['status'] ?? 'Pending').toString();
    final due = fmtDueFull(t['task_due']?.toString());
    final evidencePath = (t['evidence_path'] ?? '').toString();
    final Uint8List? evidenceBytes = t['evidence_bytes'] is Uint8List ? t['evidence_bytes'] as Uint8List : null;

    final bool canComplete = evidencePath.isNotEmpty;

    return Column(
      children: [
        _buildHeader("Task Detail", onBack: () {
          setState(() {
            _currentStep = 'dashboard';
            _activeTab = 1; // back to Tasks tab
          });
        }),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Patient Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.user, size: 18, color: Color(0xFF0D9488)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text((p['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          "ID: ${(p['id'] ?? '-')} • Status: ${(p['status'] ?? '-')}",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionTitle(LucideIcons.clipboardCheck, "Task"),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    (t['task_text'] ?? '(task)').toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),
                  _kv("Due", due),
                  _kv("Status", status),
                  if ((t['completed_at'] ?? '').toString().isNotEmpty) _kv("Completed At", (t['completed_at']).toString()),
                ]),
              ),

              const SizedBox(height: 20),

              _buildSectionTitle(LucideIcons.camera, "Evidence Photo"),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    if (evidencePath.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildEvidenceImage(
                          evidencePath,
                          bytes: evidenceBytes,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(LucideIcons.image, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("No evidence photo yet", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTaskEvidencePhoto(ImageSource.camera),
                            icon: const Icon(LucideIcons.camera, size: 18),
                            label: const Text("Take Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D9488),
                              side: const BorderSide(color: Color(0xFF0D9488)),
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickTaskEvidencePhoto(ImageSource.gallery),
                            icon: const Icon(LucideIcons.folderOpen, size: 18),
                            label: const Text("Browse", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D9488),
                              side: const BorderSide(color: Color(0xFF0D9488)),
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if ((t['evidence_captured_at'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _kv("Captured At", (t['evidence_captured_at']).toString()),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 140),
            ],
          ),
        ),

        // Bottom action: complete task
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
          child: ElevatedButton.icon(
            onPressed: status == "Completed" ? null : (canComplete ? _completeSelectedTask : _completeSelectedTask),
            icon: const Icon(LucideIcons.circleCheck),
            label: Text(
              status == "Completed" ? "Completed" : (canComplete ? "Mark Completed" : "Take Evidence to Complete"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canComplete ? const Color(0xFF0D9488) : TWColors.slate.shade300,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
