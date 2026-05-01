part of '../widgets/main_navigation_screen.dart';

extension _TasksPage on _MainNavigationScreenState {
  static const List<String> _treatmentStatusOptions = [
    'DRAFT',
    'SENT',
    'APPOINTMENT',
    'COMPLETED',
  ];

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
        final yy = (dt.year).toString().padLeft(2, '0');
        final mo = dt.month.toString().padLeft(2, '0');
        final dd = dt.day.toString().padLeft(2, '0');
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return "$yy/$mo/$dd $hh:$mm";
      } catch (_) {
        return "No Time";
      }
    }

    String fmtDueDayLabel(String? iso) {
      if (iso == null || iso.isEmpty) return "No Due Date";
      try {
        final dt = DateTime.parse(iso).toLocal();
        final now = DateTime.now();
        final dueDate = DateTime(dt.year, dt.month, dt.day);
        final todayDate = DateTime(now.year, now.month, now.day);
        final diffDays = dueDate.difference(todayDate).inDays;
        if (diffDays <= 0) return "Today";
        return "Due in ${diffDays}d";
      } catch (_) {
        return "No Due Date";
      }
    }

    DateTime? parseIso(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {
        return null;
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
          'case_updated_at': (t['case_updated_at'] ?? '').toString(),
          'photo_url': (t['photo_url'] ?? t['patient_photo_url'] ?? '').toString(),
          'plan': plan,
          'tasks': tasks,
        };
      }).toList();
    }

    final today = DateTime.now();
    final searchQuery = _tasksSearchQuery.trim().toLowerCase();
    final treatmentFilters = _tasksTreatmentStatuses.map((status) => status.toLowerCase()).toSet();
    final taskStatusFilter = _tasksTaskStatus.toLowerCase();
    final filteredPlanCases = planCases.where((c) {
      final plan = c['plan'] as Map<String, dynamic>;
      final status = (plan['status'] ?? '').toString().toLowerCase();
      final caseId = (c['case_id'] ?? '').toString().toLowerCase();
      final patientName = (c['patient_name'] ?? '').toString().toLowerCase();
      final matchesSearch = searchQuery.isEmpty || patientName.contains(searchQuery) || caseId.contains(searchQuery);
      final matchesTreatment = treatmentFilters.contains(status);

      if (!matchesSearch || !matchesTreatment) return false;

      if (taskStatusFilter == 'all') return true;
      final tasks = c['tasks'] as List<Map<String, dynamic>>;
      return tasks.any((t) => (t['status'] ?? '').toString().toLowerCase() == taskStatusFilter);
    }).toList();
    filteredPlanCases.sort((a, b) {
      final aName = (a['patient_name'] ?? '').toString().toLowerCase();
      final bName = (b['patient_name'] ?? '').toString().toLowerCase();
      final aTasks = a['tasks'] as List<Map<String, dynamic>>;
      final bTasks = b['tasks'] as List<Map<String, dynamic>>;
      final aUpdated = parseIso(a['case_updated_at']?.toString());
      final bUpdated = parseIso(b['case_updated_at']?.toString());
      final aEarliestDue = aTasks
          .map((t) => parseIso(t['task_due']?.toString()))
          .whereType<DateTime>()
          .fold<DateTime?>(null, (prev, dt) => prev == null || dt.isBefore(prev) ? dt : prev);
      final bEarliestDue = bTasks
          .map((t) => parseIso(t['task_due']?.toString()))
          .whereType<DateTime>()
          .fold<DateTime?>(null, (prev, dt) => prev == null || dt.isBefore(prev) ? dt : prev);
      final aLatestDue = aTasks
          .map((t) => parseIso(t['task_due']?.toString()))
          .whereType<DateTime>()
          .fold<DateTime?>(null, (prev, dt) => prev == null || dt.isAfter(prev) ? dt : prev);
      final bLatestDue = bTasks
          .map((t) => parseIso(t['task_due']?.toString()))
          .whereType<DateTime>()
          .fold<DateTime?>(null, (prev, dt) => prev == null || dt.isAfter(prev) ? dt : prev);

      switch (_tasksSortBy) {
        case 'DUE_DESC':
          if (aLatestDue == null && bLatestDue == null) return aName.compareTo(bName);
          if (aLatestDue == null) return 1;
          if (bLatestDue == null) return -1;
          return bLatestDue.compareTo(aLatestDue);
        case 'UPDATE_ASC':
          if (aUpdated == null && bUpdated == null) return aName.compareTo(bName);
          if (aUpdated == null) return 1;
          if (bUpdated == null) return -1;
          return aUpdated.compareTo(bUpdated);
        case 'UPDATE_DESC':
          if (aUpdated == null && bUpdated == null) return aName.compareTo(bName);
          if (aUpdated == null) return 1;
          if (bUpdated == null) return -1;
          return bUpdated.compareTo(aUpdated);
        case 'DUE_ASC':
        default:
          if (aEarliestDue == null && bEarliestDue == null) return aName.compareTo(bName);
          if (aEarliestDue == null) return 1;
          if (bEarliestDue == null) return -1;
          return aEarliestDue.compareTo(bEarliestDue);
      }
    });

    List<Map<String, dynamic>> allTasks = [];
    for (final c in filteredPlanCases) {
      final tasks = c['tasks'] as List<Map<String, dynamic>>;
      for (final t in tasks) {
        allTasks.add({
          ...t,
          'patient_name': c['patient_name'],
          'case_id': c['case_id'],
          'case_updated_at': c['case_updated_at'],
        });
      }
    }
    if (taskStatusFilter != 'all') {
      allTasks = allTasks
          .where((t) => (t['status'] ?? '').toString().toLowerCase() == taskStatusFilter)
          .toList();
    }
    allTasks.sort((a, b) {
      final aName = (a['patient_name'] ?? '').toString().toLowerCase();
      final bName = (b['patient_name'] ?? '').toString().toLowerCase();
      final aUpdated = parseIso(a['case_updated_at']?.toString());
      final bUpdated = parseIso(b['case_updated_at']?.toString());
      final ad = parseIso(a['task_due']?.toString());
      final bd = parseIso(b['task_due']?.toString());
      switch (_tasksSortBy) {
        case 'DUE_DESC':
          if (ad == null && bd == null) return aName.compareTo(bName);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        case 'UPDATE_ASC':
          if (aUpdated == null && bUpdated == null) return aName.compareTo(bName);
          if (aUpdated == null) return 1;
          if (bUpdated == null) return -1;
          return aUpdated.compareTo(bUpdated);
        case 'UPDATE_DESC':
          if (aUpdated == null && bUpdated == null) return aName.compareTo(bName);
          if (aUpdated == null) return 1;
          if (bUpdated == null) return -1;
          return bUpdated.compareTo(aUpdated);
        case 'DUE_ASC':
        default:
          if (ad == null && bd == null) return aName.compareTo(bName);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
      }
    });

    return Column(
      children: [
        if (_tasksLoading)
          const LinearProgressIndicator(color: Color(0xFF0D9488), minHeight: 2),
        if (_tasksError != null)
          GestureDetector(
            onTap: _fetchTasksList,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.circleAlert, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tasksError!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _tasksViewMode == 'plan' ? "Treatment Plan" : "All Action Items",
                  style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                Text(
                  _tasksViewMode == 'plan' ? "Managing patient treatment cycles" : "Drill-down: Sorted by urgency",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ]),
              _buildNotificationButton(),
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
                    child: _buildTreatmentStatusMultiSelect(
                      label: "Treatment Status",
                      selectedItems: _tasksTreatmentStatuses,
                      items: _treatmentStatusOptions,
                      onChanged: (values) => setState(() {
                        _tasksTreatmentStatuses
                          ..clear()
                          ..addAll(values);
                      }),
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
              const SizedBox(height: 10),
              _buildFilterDropdown(
                label: "Sort By",
                value: _tasksSortBy,
                items: const ["DUE_ASC", "DUE_DESC", "UPDATE_ASC", "UPDATE_DESC"],
                onChanged: (value) => setState(() => _tasksSortBy = value),
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
                ? filteredPlanCases.isEmpty
                    ? _buildEmptyState(
                        LucideIcons.clipboardList,
                        _tasksItems.isEmpty ? 'No treatment plans yet' : 'No matching plans',
                        subtitle: _tasksItems.isEmpty
                            ? 'Treatment plans will appear here once a doctor issues one.'
                            : 'Try adjusting your filters or search query.',
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 8, 24, 8),
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
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: (c['photo_url']?.toString().isNotEmpty == true)
                                                ? Image.network(
                                                    c['photo_url'].toString(),
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: const Color(0xFFE2E8F0),
                                                      child: const Icon(Icons.broken_image, size: 18),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: const Color(0xFFE2E8F0),
                                                    child: const Icon(Icons.person, size: 18),
                                                  ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(c['patient_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                              Text("ID: ${c['case_id']} \n ${tasks.length} Tasks", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ]),
                                          ),
                                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusBgColor(status),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _statusLabel(status),
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _statusFgColor(status)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
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
                                  final taskStatus = (t['status'] ?? 'PENDING').toString();
                                  final due = fmtDueDayLabel(t['task_due']?.toString());
                                  return Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: _statusFgColor(taskStatus),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  text,
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                : allTasks.isEmpty
                    ? _buildEmptyState(
                        LucideIcons.checkSquare,
                        _tasksItems.isEmpty ? 'No tasks yet' : 'No matching tasks',
                        subtitle: _tasksItems.isEmpty
                            ? 'Tasks assigned to you will appear here.'
                            : 'Try adjusting your filters or search query.',
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 8, 24, 8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: allTasks.length,
                    itemBuilder: (context, i) {
                    final t = allTasks[i];
                    final dueRaw = t['task_due']?.toString();
                    final due = fmtDueDayLabel(dueRaw);
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
                              Text(dueRaw == null ? "DRAFT MODE" : fmtTime(dueRaw), style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
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
    String displayLabel(String raw) {
      switch (raw) {
        case 'DUE_ASC':
          return 'Schedule: Earliest';
        case 'DUE_DESC':
          return 'Schedule: Latest';
        case 'UPDATE_ASC':
          return 'Update: Oldest';
        case 'UPDATE_DESC':
          return 'Update: Newest';
        default:
          return raw.replaceAll('_', ' ');
      }
    }

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
                      "$label: ${displayLabel(e)}",
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

  Widget _buildTreatmentStatusMultiSelect({
    required String label,
    required Set<String> selectedItems,
    required List<String> items,
    required ValueChanged<Set<String>> onChanged,
  }) {
    String displayLabel(String raw) => _statusLabel(raw);

    final selectedCount = selectedItems.length;
    final summary = selectedCount == 0
        ? 'None selected'
        : selectedCount <= 2
        ? items.where(selectedItems.contains).map(displayLabel).join(', ')
        : '$selectedCount selected';

    Future<void> openSelector() async {
      final workingSelection = Set<String>.from(selectedItems);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select $label',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => setModalState(() {
                              workingSelection
                                ..clear()
                                ..addAll(items);
                            }),
                            child: const Text('Select all'),
                          ),
                          TextButton(
                            onPressed: () => setModalState(workingSelection.clear),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: items
                                .map(
                                  (item) => CheckboxListTile(
                                    value: workingSelection.contains(item),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color(0xFF0D9488),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: Text(
                                      displayLabel(item),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    onChanged: (checked) {
                                      setModalState(() {
                                        if (checked ?? false) {
                                          workingSelection.add(item);
                                        } else {
                                          workingSelection.remove(item);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            onChanged(workingSelection);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return InkWell(
      onTap: openSelector,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label: $summary',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronDown, size: 16, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }
}
