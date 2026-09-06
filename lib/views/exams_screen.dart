import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/exam_family_model.dart';
import '../models/imported_test_model.dart';
import '../providers/history_provider.dart';
import '../providers/test_library_provider.dart';
import '../services/exam_statistics_service.dart';
import 'exam_detail_screen.dart';
import 'family_detail_screen.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        actions: [
          IconButton(
            tooltip: 'New family',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => showFamilyDialog(context),
          ),
          IconButton(
            tooltip: 'Import exam',
            icon: const Icon(Icons.upload_file),
            onPressed: () => importExamFromFile(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<TestLibraryProvider, HistoryProvider>(
          builder: (context, libraryProvider, historyProvider, child) {
            final families = libraryProvider.filteredFamilies;
            return RefreshIndicator(
              onRefresh: libraryProvider.loadTests,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search families and exams',
                            ),
                            onChanged: libraryProvider.updateSearchQuery,
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            icon: const Icon(Icons.create_new_folder_outlined),
                            label: const Text('New Family'),
                            onPressed: () => showFamilyDialog(context),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import Exam'),
                            onPressed: libraryProvider.isLoading
                                ? null
                                : () => importExamFromFile(context),
                          ),
                          if (libraryProvider.error != null) ...[
                            const SizedBox(height: 12),
                            _ErrorPanel(message: libraryProvider.error!),
                          ],
                          const SizedBox(height: 16),
                          if (families.isEmpty)
                            const _NoFamilies()
                          else
                            ...families.map(
                              (family) => _FamilyCard(
                                family: family,
                                examCount: libraryProvider
                                    .testsForFamily(family.id)
                                    .length,
                                stats: libraryProvider.familyStats(
                                  family.id,
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
            );
          },
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final ExamFamily family;
  final int examCount;
  final ExamStats stats;

  const _FamilyCard({
    required this.family,
    required this.examCount,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FamilyDetailScreen(familyId: family.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, color: AppColors.lightNavy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.name,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$examCount exam${examCount == 1 ? '' : 's'}'
                      '${stats.hasAttempts ? ' - Avg ${stats.averageScore.toStringAsFixed(0)}%' : ''}',
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Family actions',
                onSelected: (value) {
                  if (value == 'rename') {
                    showFamilyDialog(context, family: family);
                  }
                  if (value == 'delete') _confirmDeleteFamily(context, family);
                },
                itemBuilder: (context) => [
                  if (family.id != ExamFamily.uncategorizedId)
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  if (family.id != ExamFamily.uncategorizedId)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteFamily(
    BuildContext context,
    ExamFamily family,
  ) async {
    final examCount = context
        .read<TestLibraryProvider>()
        .testsForFamily(family.id)
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${family.name}?'),
        content: Text(
          examCount == 0
              ? 'The family will be removed.'
              : 'This family contains $examCount exam${examCount == 1 ? '' : 's'}. Exams will move to Uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move & Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context
        .read<TestLibraryProvider>()
        .deleteFamilyMoveExamsToUncategorized(family.id);
  }
}

class ExamCard extends StatelessWidget {
  final ImportedTest exam;
  final ExamStats stats;
  final bool showFamily;

  const ExamCard({
    super.key,
    required this.exam,
    required this.stats,
    this.showFamily = false,
  });

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.read<TestLibraryProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamDetailScreen(testId: exam.id),
          ),
        ),
        onLongPress: () => showExamRenameDialog(context, exam),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.quiz_outlined, color: AppColors.lightNavy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exam.displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Exam actions',
                    onSelected: (value) {
                      if (value == 'rename') {
                        showExamRenameDialog(context, exam);
                      }
                      if (value == 'move') _showMoveDialog(context);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(
                        value: 'move',
                        child: Text('Move to Family'),
                      ),
                    ],
                  ),
                ],
              ),
              if (exam.test.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  exam.test.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: '${exam.test.questionCount} questions'),
                  _InfoChip(label: exam.test.difficulty.name),
                  if (showFamily)
                    _InfoChip(
                      label: libraryProvider.familyNameFor(exam.familyId),
                    ),
                  if (stats.latestScore != null)
                    _InfoChip(
                      label: 'Last ${stats.latestScore!.toStringAsFixed(0)}%',
                    ),
                  if (stats.bestScore != null)
                    _InfoChip(
                      label: 'Best ${stats.bestScore!.toStringAsFixed(0)}%',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoveDialog(BuildContext context) async {
    final selected = await chooseFamily(
      context,
      initialFamilyId: exam.familyId,
    );
    if (selected == null || !context.mounted) return;
    await context.read<TestLibraryProvider>().moveExamToFamily(
      exam.id,
      selected.id,
    );
  }
}

class _NoFamilies extends StatelessWidget {
  const _NoFamilies();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_off_outlined, color: AppColors.lightNavy),
            SizedBox(height: 12),
            Text(
              'No exam families yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text('Create a family to organize your exams.'),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), backgroundColor: AppColors.lightGray);
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

Future<void> showFamilyDialog(
  BuildContext context, {
  ExamFamily? family,
}) async {
  final controller = TextEditingController(text: family?.name ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(family == null ? 'New family' : 'Rename family'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Family name'),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || !context.mounted) return;

  final provider = context.read<TestLibraryProvider>();
  final saved = family == null
      ? await provider.createFamily(result) != null
      : await provider.renameFamily(family.id, result);
  if (!context.mounted || saved) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.error ?? 'Family could not be saved.')),
  );
}

Future<void> showExamRenameDialog(
  BuildContext context,
  ImportedTest exam,
) async {
  final controller = TextEditingController(text: exam.displayName);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename exam'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Display name'),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();

  if (result == null || !context.mounted) return;
  final provider = context.read<TestLibraryProvider>();
  final renamed = await provider.renameTest(exam.id, result);
  if (!context.mounted || renamed) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(provider.error ?? 'The exam name could not be saved.'),
    ),
  );
}

Future<void> importExamFromFile(
  BuildContext context, {
  String initialFamilyId = ExamFamily.uncategorizedId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final libraryProvider = context.read<TestLibraryProvider>();
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final selectedFamily = await chooseFamily(
      context,
      initialFamilyId: initialFamilyId,
    );
    if (selectedFamily == null) return;

    final file = result.files.single;
    final content = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();
    final imported = await libraryProvider.importJson(
      content,
      familyId: selectedFamily.id,
    );
    if (!context.mounted) return;
    final duplicate = libraryProvider.duplicateExam;
    messenger.showSnackBar(
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
  } catch (e) {
    debugPrint('File import failed: $e');
    messenger.showSnackBar(
      const SnackBar(content: Text('The selected file could not be imported.')),
    );
  }
}

Future<ExamFamily?> chooseFamily(
  BuildContext context, {
  String initialFamilyId = ExamFamily.uncategorizedId,
}) {
  var selectedId = initialFamilyId;
  return showDialog<ExamFamily>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final provider = context.watch<TestLibraryProvider>();
        if (!provider.families.any((family) => family.id == selectedId)) {
          selectedId = ExamFamily.uncategorizedId;
        }
        return AlertDialog(
          title: const Text('Choose exam family'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroup<String>(
                  groupValue: selectedId,
                  onChanged: (value) {
                    if (value != null) setState(() => selectedId = value);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final family in provider.families)
                        RadioListTile<String>(
                          value: family.id,
                          title: Text(family.name),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, provider.familyForId(selectedId)),
              child: const Text('Choose'),
            ),
          ],
        );
      },
    ),
  );
}
