part of '../widgets/main_navigation_screen.dart';

extension _TasksPage on _MainNavigationScreenState {
  Widget _buildTasksTab() {
    if (!_tasksFetchedOnce && !_tasksLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTasksList());
    }
    String fmtDateLong(DateTime dt) {
      const months = [
        "January","February","March","April","May","June","July","August","September","October","November","December"
      ];
      return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
    }

    String fmtTime(String? iso) {
      if (iso == null || iso.isEmpty) return "No Time";
      try {
        final dt = DateTime.parse(iso).toLocal();
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return "$hh:$mm";
      } catch (_) {
        return "No Time";
      }
    }

    List<Map<String, dynamic>> planCases = [];
    if (_tasksItems.isNotEmpty) {
      planCases = _tasksItems.map((t) {
        final plan = (t['current_treatment'] is Map)
            ? Map<String, dynamic>.from(t['current_treatment'])
            : <String, dynamic>{};
        final tasks = (plan['plan_tasks'] is List)
            ? List<Map<String, dynamic>>.from(plan['plan_tasks'])
            : <Map<String, dynamic>>[];
        return {
          'case_id': (t['case_id'] ?? '').toString(),
          'patient_name': (t['patient_name'] ?? 'Patient').toString(),
          'patient_id': (t['patient_id'] ?? '').toString(),
          'plan': plan,
          'tasks': tasks,
        };
      }).toList();
    }

    final today = DateTime.now();
    final searchQuery = _tasksSearchQuery.trim().toLowerCase();
    final treatmentFilter = _tasksTreatmentStatus.toLowerCase();
    final taskStatusFilter = _tasksTaskStatus.toLowerCase();
    final filteredPlanCases = planCases.where((c) {
      final plan = c['plan'] as Map<String, dynamic>;
      final status = (plan['status'] ?? '').toString().toLowerCase();
      final caseId = (c['case_id'] ?? '').toString().toLowerCase();
      final patientName = (c['patient_name'] ?? '').toString().toLowerCase();
      final matchesSearch = searchQuery.isEmpty || patientName.contains(searchQuery) || caseId.contains(searchQuery);
      final matchesTreatment = treatmentFilter == 'all' || status == treatmentFilter;

      if (!matchesSearch || !matchesTreatment) return false;

      if (taskStatusFilter == 'all') return true;
      final tasks = c['tasks'] as List<Map<String, dynamic>>;
      return tasks.any((t) => (t['status'] ?? '').toString().toLowerCase() == taskStatusFilter);
    }).toList();

    List<Map<String, dynamic>> allTasks = [];
    for (final c in filteredPlanCases) {
      final tasks = c['tasks'] as List<Map<String, dynamic>>;
      for (final t in tasks) {
        allTasks.add({
          ...t,
          'patient_name': c['patient_name'],
          'case_id': c['case_id'],
        });
      }
    }
    if (taskStatusFilter != 'all') {
      allTasks = allTasks
          .where((t) => (t['status'] ?? '').toString().toLowerCase() == taskStatusFilter)
          .toList();
    }
    allTasks.sort((a, b) {
      final ad = a['task_due']?.toString();
      final bd = b['task_due']?.toString();
      if (ad == null || ad.isEmpty) return 1;
      if (bd == null || bd.isEmpty) return -1;
      return DateTime.parse(ad).compareTo(DateTime.parse(bd));
    });

    return Column(
      children: [
        if (_tasksLoading)
          const LinearProgressIndicator(color: Color(0xFF0D9488), minHeight: 2),
        if (_tasksError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(_tasksError!, style: const TextStyle(color: Colors.redAccent)),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _tasksViewMode == 'plan' ? "Case Load" : "All Action Items",
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                Text(
                  _tasksViewMode == 'plan' ? "Managing patient treatment cycles" : "Drill-down: Sorted by urgency",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text("Today's Date", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
                Text(fmtDateLong(today), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _tasksViewMode = 'plan'),
                  style: TextButton.styleFrom(
                    backgroundColor: _tasksViewMode == 'plan' ? const Color(0xFF0D9488) : Colors.transparent,
                    foregroundColor: _tasksViewMode == 'plan' ? Colors.white : Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Treatment Plans", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _tasksViewMode = 'task'),
                  style: TextButton.styleFrom(
                    backgroundColor: _tasksViewMode == 'task' ? const Color(0xFF0D9488) : Colors.transparent,
                    foregroundColor: _tasksViewMode == 'task' ? Colors.white : Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Individual Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                onChanged: (value) => setState(() => _tasksSearchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search patient or case ID",
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.blueGrey),
                  suffixIcon: _tasksSearchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: Colors.blueGrey),
                          onPressed: () => setState(() => _tasksSearchQuery = ''),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      label: "Treatment Status",
                      value: _tasksTreatmentStatus,
                      items: const ["ALL", "DRAFT", "ACTIVE", "COMPLETED"],
                      onChanged: (value) => setState(() => _tasksTreatmentStatus = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFilterDropdown(
                      label: "Task Status",
                      value: _tasksTaskStatus,
                      items: const ["ALL", "DRAFT", "PENDING", "COMPLETED"],
                      onChanged: (value) => setState(() => _tasksTaskStatus = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0D9488),
            onRefresh: () async {
              await _fetchTasksList();
            },
            child: _tasksViewMode == 'plan'
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredPlanCases.length,
                    itemBuilder: (context, i) {
                    final c = filteredPlanCases[i];
                    final plan = c['plan'] as Map<String, dynamic>;
                    final tasks = c['tasks'] as List<Map<String, dynamic>>;
                    final status = (plan['status'] ?? 'DRAFT').toString();
                    final caseId = c['case_id'].toString();
                    final selectedTask = tasks.isNotEmpty ? tasks.first : null;
                    final isExpanded = _tasksExpandedByCase[caseId] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      if (tasks.isEmpty || selectedTask == null) return;
                                      final taskIndex = tasks.indexOf(selectedTask);
                                      _taskDetailReturnStep = _currentStep;
                                      _taskDetailReturnTab = _activeTab;
                                      final ok = await _fetchTaskDetail(caseId: caseId, taskIndex: taskIndex);
                                      if (!ok) return;
                                      if (!mounted) return;
                                      setState(() {
                                        _currentStep = 'task_detail';
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                                            alignment: Alignment.center,
                                            child: Text(
                                              (c['patient_name'] as String).isNotEmpty ? (c['patient_name'] as String)[0] : "?",
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(c['patient_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                              Text("ID: ${c['case_id']} • ${tasks.length} Tasks", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ]),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusBgColor(status),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusFgColor(status)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: Colors.blueGrey),
                                  onPressed: () {
                                    setState(() => _tasksExpandedByCase[caseId] = !isExpanded);
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: tasks.map((t) {
                                  final text = t['task_text']?.toString() ?? "-";
                                  final due = fmtTime(t['task_due']?.toString());
                                  return Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                                        Text(due, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: allTasks.length,
                    itemBuilder: (context, i) {
                    final t = allTasks[i];
                    final dueRaw = t['task_due']?.toString();
                    final due = fmtTime(dueRaw);
                    final isOverdue = dueRaw != null && dueRaw.isNotEmpty && DateTime.parse(dueRaw).isBefore(DateTime.now());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(left: BorderSide(color: isOverdue ? Colors.red : const Color(0xFF3B82F6), width: 4)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t['task_text']?.toString() ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 4),
                              Text("${t['patient_name']} • ${t['case_id']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ]),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(due, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOverdue ? Colors.red : const Color(0xFF2563EB))),
                              Text(dueRaw == null ? "DRAFT MODE" : "TODAY", style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.blueGrey),
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      "$label: $e",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }
}
