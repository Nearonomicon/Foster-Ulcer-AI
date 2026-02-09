part of '../widgets/main_navigation_screen.dart';

extension _TasksPage on _MainNavigationScreenState {
  Widget _buildTasksTab() {
    // Flatten tasks from all patients for combined view
    List<Map<String, dynamic>> allTasks = [];
    for (int pi = 0; pi < _patients.length; pi++) {
      final p = _patients[pi];
      final aiJson = p['ai_wound_json'];
      if (aiJson != null) {
        final plan = aiJson['treatment_plan'];
        if (plan != null && plan['plan_tasks'] != null) {
          final taskList = plan['plan_tasks'];
          if (taskList is List) {
            for (int ti = 0; ti < taskList.length; ti++) {
              final t = taskList[ti];
              if (t is Map) {
                allTasks.add({
                  ...Map<String, dynamic>.from(t),
                  'patient_name': p['name'],
                  'patient_id': p['id'],
                  '_pi': pi,
                  '_ti': ti,
                });
              }
            }
          }
        }
      }
    }

    String fmtDue(String? iso) {
      if (iso == null || iso.isEmpty) return "TBD";
      try {
        final dt = DateTime.parse(iso).toLocal();
        return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        return iso;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Care Tasks", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            Text("${allTasks.length} Active Clinical Tasks", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ]),
        ),
        // Filter bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildFilterChip("All Tasks", true),
              const SizedBox(width: 8),
              _buildFilterChip("Urgent", false),
              const SizedBox(width: 8),
              _buildFilterChip("Pending", false),
              const SizedBox(width: 8),
              _buildFilterChip("Completed", false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: allTasks.length,
            itemBuilder: (context, index) {
              final task = allTasks[index];
              final isUrgent = task['status'] == 'Urgent';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTaskPatientIndex = task['_pi'] as int;
                    _selectedTaskIndex = task['_ti'] as int;
                    _currentStep = 'task_detail';
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isUrgent ? Colors.red.withOpacity(0.2) : const Color(0xFFF1F5F9)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUrgent ? Colors.red.shade50 : const Color(0xFFF0FDFA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUrgent ? LucideIcons.triangleAlert : LucideIcons.circleCheck,
                          size: 20,
                          color: isUrgent ? Colors.red : const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(task['patient_name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text(
                                  fmtDue(task['task_due']),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(task['task_text'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent ? Colors.red.shade50 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task['status'].toString().toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : Colors.blueGrey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: 16, color: TWColors.slate.shade300),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.blueGrey),
      ),
    );
  }
}
