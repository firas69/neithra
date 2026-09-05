import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/imported_test_model.dart';
import '../models/session_snapshot_model.dart';
import '../providers/history_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/session_provider.dart';
import '../providers/test_library_provider.dart';
import '../services/json_parser_service.dart';
import 'exam_screen.dart';
import 'exam_detail_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neithra')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<SessionProvider>().loadSavedSessions(),
              context.read<TestLibraryProvider>().loadTests(),
              context.read<HistoryProvider>().loadHistory(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child:
                      Consumer4<
                        ProfileProvider,
                        SessionProvider,
                        TestLibraryProvider,
                        HistoryProvider
                      >(
                        builder:
                            (
                              context,
                              profileProvider,
                              sessionProvider,
                              libraryProvider,
                              historyProvider,
                              child,
                            ) {
                              final latestSession =
                                  sessionProvider.savedSessions.isEmpty
                                  ? null
                                  : sessionProvider.savedSessions.first;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _HeroPanel(
                                    username:
                                        profileProvider.profile?.username ??
                                        'there',
                                    examsCount: libraryProvider.tests.length,
                                    attemptsCount:
                                        historyProvider.attempts.length,
                                  ),
                                  if (latestSession != null) ...[
                                    const SizedBox(height: 16),
                                    _ResumeCard(session: latestSession),
                                  ],
                                  const SizedBox(height: 16),
                                  _QuickActions(),
                                  const SizedBox(height: 16),
                                  _RecentExams(exams: libraryProvider.tests),
                                ],
                              );
                            },
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String username;
  final int examsCount;
  final int attemptsCount;

  const _HeroPanel({
    required this.username,
    required this.examsCount,
    required this.attemptsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $username',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick up a saved session or import your next JSON exam.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(icon: Icons.quiz, label: '$examsCount exams'),
                _StatChip(
                  icon: Icons.fact_check_outlined,
                  label: '$attemptsCount attempts',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final SessionSummary session;

  const _ResumeCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final progress = session.totalQuestions == 0
        ? 0.0
        : session.answeredQuestions / session.totalQuestions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_outline, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Resume ${session.testTitle}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.clamp(0, 1)),
            const SizedBox(height: 8),
            Text(
              '${session.answeredQuestions}/${session.totalQuestions} answered - '
              '${_formatDuration(session.elapsedTime)} saved',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continue'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamScreen(resumeSessionId: session.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Exam'),
              onPressed: () => _importFromFile(context),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('Use Sample Exam'),
              onPressed: () async {
                final imported = await context
                    .read<TestLibraryProvider>()
                    .importJson(JsonParserService.getSampleJson());
                if (!context.mounted) return;
                final libraryProvider = context.read<TestLibraryProvider>();
                final duplicate = libraryProvider.duplicateExam;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      imported == null
                          ? libraryProvider.error ?? 'Import failed'
                          : '${imported.displayName} imported',
                    ),
                    action: duplicate == null
                        ? null
                        : SnackBarAction(
                            label: 'Open',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExamDetailScreen(testId: duplicate.id),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final libraryProvider = context.read<TestLibraryProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final content = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();
      final imported = await libraryProvider.importJson(content);
      if (!context.mounted) return;
      if (imported == null) {
        final duplicate = libraryProvider.duplicateExam;
        messenger.showSnackBar(
          SnackBar(
            content: Text(libraryProvider.error ?? 'Import failed'),
            action: duplicate == null
                ? null
                : SnackBarAction(
                    label: 'Open',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ExamDetailScreen(testId: duplicate.id),
                      ),
                    ),
                  ),
          ),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('${imported.displayName} imported')),
      );
    } catch (e) {
      debugPrint('File import failed: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('The selected file could not be imported.'),
        ),
      );
    }
  }
}

class _RecentExams extends StatelessWidget {
  final List<ImportedTest> exams;

  const _RecentExams({required this.exams});

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.lightNavy),
              SizedBox(height: 10),
              Text(
                'No exams yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              SizedBox(height: 4),
              Text('Import a JSON exam to start studying.'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent exams',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ...exams
                .take(3)
                .map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.quiz_outlined),
                    title: Text(item.displayName),
                    subtitle: Text('${item.test.questionCount} questions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamDetailScreen(testId: item.id),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: AppColors.lightGray,
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m ${duration.inSeconds.remainder(60)}s';
}
