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
    final planTasks = (p['plan_tasks'] is List)
        ? List<Map<String, dynamic>>.from(p['plan_tasks'])
        : <Map<String, dynamic>>[];
    final caseId = (p['case_id'] ?? '-').toString();
    final planId = (p['plan_id'] ?? p['current_treatment']?['plan_id'] ?? '').toString();
    final bool canComplete = evidencePath.isNotEmpty;
    final taskCount = planTasks.length;
    final completedCount = planTasks.where((task) {
      final s = (task['status'] ?? '').toString().toLowerCase();
      return s == 'completed';
    }).length;
    final totalCount = planTasks.length;
    final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);
    final nowIso = DateTime.now().toIso8601String();
    final selectedTasks = planTasks.where((task) {
      final taskId = (task['task_id'] ?? '').toString();
      final taskDue = fmtDueFull(task['task_due']?.toString());
      final text = (task['task_text'] ?? '-').toString();
      final key = taskId.isNotEmpty ? taskId : "${text}_$taskDue";
      return _taskDetailSelectedById[key] == true;
    }).toList();
    final selectedCount = selectedTasks.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentStep = _taskDetailReturnStep;
                              if (_taskDetailReturnStep == 'dashboard') {
                                _activeTab = _taskDetailReturnTab;
                              }
                            });
                          },
                          icon: const Icon(LucideIcons.chevronLeft, size: 18),
                          label: const Text("Back", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                        ),
                        const Text("Plan Execution", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("ID: $caseId", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: const Color(0xFF10B981),
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$completedCount of $totalCount Tasks Completed",
                      style: const TextStyle(fontSize: 10, color: Colors.blueGrey, letterSpacing: 1, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  children: planTasks.map((task) {
                    final text = (task['task_text'] ?? '-').toString();
                    final taskStatus = (task['status'] ?? 'DRAFT').toString();
                    final taskDue = fmtDueFull(task['task_due']?.toString());
                    final taskEvidencePath = (task['evidence_path'] ?? '').toString();
                    final taskPhotoUrl = (task['task_photo_url'] ?? '').toString();
                    final hasEvidence = taskEvidencePath.isNotEmpty || taskPhotoUrl.isNotEmpty;
                    final isCompleted = taskStatus.toLowerCase() == 'completed';
                    final isSelectedTask =
                        (task['task_text'] ?? '') == (t['task_text'] ?? '') &&
                        (task['task_due'] ?? '') == (t['task_due'] ?? '');
                    final taskId = (task['task_id'] ?? '').toString();
                    final expandedKey = taskId.isNotEmpty ? taskId : "${text}_$taskDue";
                    final isExpanded = _taskDetailExpandedById[expandedKey] ?? false;
                    final isSelected = _taskDetailSelectedById[expandedKey] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (v) {
                                  setState(() => _taskDetailSelectedById[expandedKey] = v ?? false);
                                },
                              ),
                              Expanded(
                                child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  taskStatus,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? const Color(0xFF64748B) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: Colors.blueGrey),
                                onPressed: () {
                                  setState(() => _taskDetailExpandedById[expandedKey] = !isExpanded);
                                },
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 8),
                            _kv("Due", taskDue),
                            if (isCompleted && (task['completed_at'] ?? '').toString().isNotEmpty)
                              _kv("Completed on", (task['completed_at']).toString()),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (taskEvidencePath.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.file(
                                            File(taskEvidencePath),
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(
                                              height: 200,
                                              color: const Color(0xFFE2E8F0),
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        )
                                      else if (taskPhotoUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            taskPhotoUrl,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(
                                              height: 200,
                                              color: const Color(0xFFE2E8F0),
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: const Icon(LucideIcons.image, color: Colors.grey, size: 28),
                                        ),
                                      const SizedBox(height: 10),
                                      Text(
                                        hasEvidence ? "Evidence captured" : "No evidence captured yet",
                                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() => _selectedTask = task);
                                          _pickTaskEvidencePhoto(ImageSource.camera, task, caseId);
                                        },
                                        icon: const Icon(LucideIcons.camera, size: 16),
                                        label: const Text("Take Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(double.infinity, 40),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() => _selectedTask = task);
                                          _pickTaskEvidencePhoto(ImageSource.gallery, task, caseId);
                                        },
                                        icon: const Icon(LucideIcons.folderOpen, size: 16),
                                        label: const Text("Browse", style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF2563EB),
                                          side: const BorderSide(color: Color(0xFF2563EB)),
                                          minimumSize: const Size(double.infinity, 40),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isCompleted
                                    ? null
                                    : () {
                                        setState(() => _selectedTask = task);
                                        _completeSelectedTask();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFF10B981),
                                  foregroundColor: isCompleted ? const Color(0xFF94A3B8) : Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(
                                  isCompleted ? "✓ Completed" : "Mark as Complete",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedCount == 0
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text("Confirm"),
                            content: Text("$selectedCount tasks will be marked as completed. Confirm?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text("No"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final updates = <Map<String, dynamic>>[];
                                  final imageFiles = <File>[];
                                  bool missingEvidence = false;
                                  for (final task in selectedTasks) {
                                    final taskId = (task['task_id'] ?? '').toString();
                                    if (taskId.isEmpty) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Missing task_id for one or more tasks."), backgroundColor: Colors.orange),
                                        );
                                      }
                                      Navigator.of(ctx).pop();
                                      return;
                                    }
                                    final evidencePath = (task['evidence_path'] ?? '').toString();
                                    if (evidencePath.isEmpty) {
                                      missingEvidence = true;
                                    } else {
                                      imageFiles.add(File(evidencePath));
                                    }
                                    updates.add({
                                      'task_id': taskId,
                                      'updates': {
                                        'status': 'COMPLETED',
                                        'completed_at': nowIso,
                                      }
                                    });
                                  }
                                  if (missingEvidence && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Some tasks have no evidence photo. Sending updates without photos."), backgroundColor: Colors.orange),
                                    );
                                  }
                                  final ok = await _taskUpdateApi(
                                    caseId: caseId,
                                    planId: planId.isNotEmpty ? planId : null,
                                    updates: updates,
                                    images: missingEvidence ? null : imageFiles,
                                  );
                                  if (ok && mounted) {
                                    setState(() {
                                      for (final task in selectedTasks) {
                                        task['status'] = 'COMPLETED';
                                        task['completed_at'] = task['completed_at'] ?? nowIso;
                                      }
                                      _selectedTask?['status'] = 'COMPLETED';
                                      _selectedTask?['completed_at'] = _selectedTask?['completed_at'] ?? nowIso;
                                    });
                                  }
                                  Navigator.of(ctx).pop();
                                },
                                child: const Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text("Mark $selectedCount Tasks as Complete", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
