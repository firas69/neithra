import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/imported_test_model.dart';
import '../providers/test_library_provider.dart';
import 'test_detail_screen.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests'),
        actions: [
          IconButton(
            tooltip: 'Import',
            icon: const Icon(Icons.upload_file),
            onPressed: () => _importFromFile(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<TestLibraryProvider>(
          builder: (context, libraryProvider, child) {
            final tests = libraryProvider.filteredTests;
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
                              hintText: 'Search imported tests',
                            ),
                            onChanged: libraryProvider.updateSearchQuery,
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import JSON Test'),
                            onPressed: libraryProvider.isLoading
                                ? null
                                : () => _importFromFile(context),
                          ),
                          if (libraryProvider.error != null) ...[
                            const SizedBox(height: 12),
                            _ErrorPanel(message: libraryProvider.error!),
                          ],
                          const SizedBox(height: 16),
                          if (libraryProvider.tests.isEmpty)
                            const _EmptyTests()
                          else if (tests.isEmpty)
                            const _EmptySearch()
                          else
                            ...tests.map((test) => _TestCard(test: test)),
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            imported == null
                ? libraryProvider.error ?? 'Import failed'
                : '${imported.displayName} imported',
          ),
        ),
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

class _TestCard extends StatelessWidget {
  final ImportedTest test;

  const _TestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestDetailScreen(testId: test.id),
          ),
        ),
        onLongPress: () => _showRenameDialog(context),
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
                      test.displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Test actions',
                    onSelected: (value) {
                      if (value == 'rename') _showRenameDialog(context);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                    ],
                  ),
                ],
              ),
              if (test.test.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  test.test.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: '${test.test.questionCount} questions'),
                  _InfoChip(label: test.test.difficulty.name),
                  _InfoChip(label: '${test.attemptsCount} attempts'),
                  if (test.bestScore != null)
                    _InfoChip(
                      label: 'Best ${test.bestScore!.toStringAsFixed(0)}%',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final controller = TextEditingController(text: test.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename test'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Display name'),
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
    final renamed = await context.read<TestLibraryProvider>().renameTest(
      test.id,
      result,
    );
    if (!context.mounted) return;
    if (!renamed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<TestLibraryProvider>().error ??
                'The test name could not be saved.',
          ),
        ),
      );
    }
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

class _EmptyTests extends StatelessWidget {
  const _EmptyTests();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.lightNavy),
            SizedBox(height: 12),
            Text(
              'No tests yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text('Import a JSON test to start studying.'),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No tests match your search.'),
      ),
    );
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
