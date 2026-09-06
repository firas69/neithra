import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/exam_family_model.dart';
import '../providers/history_provider.dart';
import '../providers/test_library_provider.dart';
import '../services/exam_statistics_service.dart';
import 'exams_screen.dart';

class FamilyDetailScreen extends StatefulWidget {
  final String familyId;

  const FamilyDetailScreen({super.key, required this.familyId});

  @override
  State<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends State<FamilyDetailScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer2<TestLibraryProvider, HistoryProvider>(
      builder: (context, libraryProvider, historyProvider, child) {
        final family = libraryProvider.familyForId(widget.familyId);
        final exams = libraryProvider.testsForFamily(family.id, query: _query);
        final stats = libraryProvider.familyStats(
          family.id,
          historyProvider.attempts,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(family.name),
            actions: [
              IconButton(
                tooltip: 'Import exam',
                icon: const Icon(Icons.upload_file),
                onPressed: () =>
                    importExamFromFile(context, initialFamilyId: family.id),
              ),
              if (family.id != ExamFamily.uncategorizedId)
                PopupMenuButton<String>(
                  tooltip: 'Family actions',
                  onSelected: (value) {
                    if (value == 'rename') {
                      showFamilyDialog(context, family: family);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                  ],
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FamilyStatsPanel(family: family, stats: stats),
                        const SizedBox(height: 14),
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search exams in this family',
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Import Exam'),
                          onPressed: () => importExamFromFile(
                            context,
                            initialFamilyId: family.id,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (exams.isEmpty)
                          _EmptyFamily(query: _query)
                        else
                          ...exams.map(
                            (exam) => ExamCard(
                              exam: exam,
                              stats: libraryProvider.examStats(
                                exam.id,
                                historyProvider.attempts,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FamilyStatsPanel extends StatelessWidget {
  final ExamFamily family;
  final ExamStats stats;

  const _FamilyStatsPanel({required this.family, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              family.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: '${stats.examCount} exams'),
                _StatChip(label: '${stats.attemptCount} attempts'),
                _StatChip(
                  label: stats.hasAttempts
                      ? 'Avg ${stats.averageScore.toStringAsFixed(0)}%'
                      : 'No attempts yet',
                ),
                if (stats.bestScore != null)
                  _StatChip(
                    label: 'Best ${stats.bestScore!.toStringAsFixed(0)}%',
                  ),
                _StatChip(label: _formatDuration(stats.totalTime)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFamily extends StatelessWidget {
  final String query;

  const _EmptyFamily({required this.query});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.quiz_outlined, color: AppColors.lightNavy),
            const SizedBox(height: 12),
            Text(
              query.trim().isEmpty
                  ? 'No exams in this family'
                  : 'No exams match your search',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('Import an exam or move an existing exam here.'),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;

  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), backgroundColor: AppColors.lightGray);
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
