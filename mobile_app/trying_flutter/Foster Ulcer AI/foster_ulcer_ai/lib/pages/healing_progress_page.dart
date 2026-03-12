part of '../widgets/main_navigation_screen.dart';

extension _HealingProgressPage on _MainNavigationScreenState {
  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5EEAD4)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
    );
  }

  Widget _buildHealingProgressPage() {
    final text = _healingResponseText ?? "No healing analysis available.";

    List<Map<String, dynamic>> records = [];
    if (_healingRawResponse != null) {
      try {
        final decoded = jsonDecode(_healingRawResponse!);
        if (decoded is Map && decoded['records'] is List) {
          records = List<Map<String, dynamic>>.from(decoded['records']);
        }
      } catch (_) {}
    }
    String formatShortDate(String? raw) {
      if (raw == null || raw.isEmpty) return "-";
      try {
        final dt = DateTime.parse(raw).toLocal();
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        return "$m/$d";
      } catch (_) {
        return raw;
      }
    }

    String formatLongDate(String? raw) {
      if (raw == null || raw.isEmpty) return "-";
      try {
        final dt = DateTime.parse(raw).toLocal();
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return "$y-$m-$d $hh:$mm";
      } catch (_) {
        return raw;
      }
    }

    String recordTime(Map<String, dynamic> r) {
      return r['record_created_at']?.toString() ??
          r['record_created_at_utc']?.toString() ??
          r['timestamps']?['created_at']?.toString() ??
          "-";
    }
    final currentIndex = records.isEmpty ? 0 : _healingIndex.clamp(0, records.length - 1);
    return Column(
      children: [
        _buildHeader("Healing Progress", onBack: () => _navigateTo('assessment')),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (records.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final raw = recordTime(records[i]);
                        final isActive = currentIndex == i;
                        return InkWell(
                          onTap: () {
                            _healingPageCtrl.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                            setState(() => _healingIndex = i);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 64,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF0D9488).withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isActive ? const Color(0xFF0D9488) : Colors.transparent),
                            ),
                            child: Center(
                              child: Text(
                                formatShortDate(raw),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isActive ? const Color(0xFF0D9488) : Colors.blueGrey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (records.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Selected Assessment", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        Text(formatLongDate(recordTime(records[currentIndex])),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.gitCompareArrows),
                      label: const Text("Compare", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              _buildSectionTitle(LucideIcons.timerReset, "Wound Timeline"),
              const SizedBox(height: 10),
              if (records.isEmpty)
                const Center(child: Text("No record timeline available."))
              else
                SizedBox(
                  height: 360,
                  child: PageView.builder(
                    controller: _healingPageCtrl,
                    onPageChanged: (i) => setState(() => _healingIndex = i),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      final recordId = r['record_id']?.toString() ?? "-";
                      String formatDateTime(String? raw) {
                        if (raw == null || raw.isEmpty) return "-";
                        try {
                          final dt = DateTime.parse(raw).toLocal();
                          final y = dt.year.toString().padLeft(4, '0');
                          final m = dt.month.toString().padLeft(2, '0');
                          final d = dt.day.toString().padLeft(2, '0');
                          final hh = dt.hour.toString().padLeft(2, '0');
                          final mm = dt.minute.toString().padLeft(2, '0');
                          return "$y-$m-$d $hh:$mm";
                        } catch (_) {
                          return raw;
                        }
                      }
                      final createdAt = formatLongDate(recordTime(r));
                      final vitals = (r['vital_signs'] is Map) ? Map<String, dynamic>.from(r['vital_signs']) : <String, dynamic>{};
                      final wound = (r['wound_detail'] is Map) ? Map<String, dynamic>.from(r['wound_detail']) : <String, dynamic>{};
                      final size = (wound['size'] is Map) ? Map<String, dynamic>.from(wound['size']) : <String, dynamic>{};
                      final width = size['width_cm']?.toString() ?? "-";
                      final length = size['length_cm']?.toString() ?? "-";
                      final depth = wound['depth_category']?.toString() ?? "-";
                      final pain = wound['pain_score']?.toString() ?? "-";
                      final discharge = (wound['discharge'] is Map) ? Map<String, dynamic>.from(wound['discharge']) : <String, dynamic>{};
                      final exudate = discharge['type']?.toString() ?? "-";
                      final hasInfection = wound['has_infection'];
                      final infection = (hasInfection == null) ? "-" : (hasInfection == true || hasInfection.toString().toLowerCase() == 'true' ? "Yes" : "No");
                      final bed = (wound['bed'] is Map) ? Map<String, dynamic>.from(wound['bed']) : <String, dynamic>{};
                      int? toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
                      final slough = toInt(bed['slough_pct']);
                      final necrotic = toInt(bed['necrotic_pct']);
                      final granulation = (slough != null && necrotic != null) ? (100 - slough - necrotic).clamp(0, 100) : null;
                      final g = granulation ?? 0;
                      final s = slough ?? 0;
                      final n = necrotic ?? 0;
                      final gFlex = g <= 0 ? 1 : g;
                      final sFlex = s <= 0 ? 1 : s;
                      final nFlex = n <= 0 ? 1 : n;
                      final img = r['image'];
                      final rawUrl = (img is Map) ? img['image_folder_url']?.toString() : null;
                      final imgUrl = (rawUrl == null) ? null : rawUrl.trim();
                      final status = r['status']?.toString() ?? "-";
                      final healingProgress = r['healing_progress']?.toString();
                      final analysis = (r['analysis'] is Map) ? Map<String, dynamic>.from(r['analysis']) : <String, dynamic>{};
                      final classifications = (analysis['classifications'] is Map) ? Map<String, dynamic>.from(analysis['classifications']) : <String, dynamic>{};
                      final idsa = classifications['IDSA_infection_stage'];
                      final wIfi = (classifications['WIfI'] is Map) ? Map<String, dynamic>.from(classifications['WIfI']) : <String, dynamic>{};
                      final wW = wIfi['wound_grade'];
                      final wI = wIfi['ischemia_grade'];
                      final wFI = wIfi['foot_infection_grade'];
                      final sinbad = (classifications['SINBAD'] is Map) ? Map<String, dynamic>.from(classifications['SINBAD']) : <String, dynamic>{};
                      final sinbadTotal = sinbad['total'];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imgUrl != null && imgUrl.isNotEmpty && imgUrl.toLowerCase() != 'null') ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imgUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    height: 120,
                                    color: const Color(0xFFF1F5F9),
                                    child: const Center(child: Icon(LucideIcons.image, color: Colors.grey)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clipboardList, size: 16, color: Color(0xFF0D9488)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Record $recordId",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            status,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(createdAt, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _pill("SINBAD ${sinbadTotal ?? '-'}"),
                                        _pill("W:${wW ?? '-'} I:${wI ?? '-'} FI:${wFI ?? '-'}"),
                                        _pill("IDSA ${idsa ?? '-'}"),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text("Size: $width × $length cm", style: const TextStyle(fontSize: 12)),
                                    Text("Depth: $depth", style: const TextStyle(fontSize: 12)),
                                    Text("Pain: $pain/10", style: const TextStyle(fontSize: 12)),
                                    Text("Exudate: $exudate", style: const TextStyle(fontSize: 12)),
                                    Text("Infection: $infection", style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Tissue Composition", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: gFlex,
                                              child: Container(height: 10, color: const Color(0xFF22C55E)),
                                            ),
                                            Expanded(
                                              flex: sFlex,
                                              child: Container(height: 10, color: const Color(0xFFF59E0B)),
                                            ),
                                            Expanded(
                                              flex: nFlex,
                                              child: Container(height: 10, color: const Color(0xFF334155)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "G/S/N: ${granulation?.toString() ?? '-'} / ${slough?.toString() ?? '-'} / ${necrotic?.toString() ?? '-'} %",
                                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        title: const Text("Vital Signs", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                        children: [
                                          _kv("Temperature", (vitals['temperature'] ?? '-').toString()),
                                          _kv("Blood Pressure", (vitals['blood_pressure'] ?? '-').toString()),
                                          _kv("Heart Rate", (vitals['heart_rate'] ?? '-').toString()),
                                          _kv("Respiratory Rate", (vitals['respiratory_rate'] ?? vitals['repiratory_rate'] ?? '-').toString()),
                                          _kv("Blood Glucose", (vitals['blood_glucose'] ?? vitals['blood_sugar'] ?? '-').toString()),
                                        ],
                                      ),
                                    ),
                                    if (healingProgress != null && healingProgress.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        "Healing: $healingProgress",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              _buildSectionTitle(LucideIcons.activity, "Healing Summary"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        _buildFixedBottomButton("Back to Dashboard", LucideIcons.house, () => _navigateTo('dashboard')),
      ],
    );
  }
}
