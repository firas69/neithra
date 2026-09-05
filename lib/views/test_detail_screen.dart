import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/test_model.dart';
import '../providers/test_library_provider.dart';
import '../providers/test_provider.dart';
import 'practice_screen.dart';

class TestDetailScreen extends StatelessWidget {
  final String testId;

  const TestDetailScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    final importedTest = context.watch<TestLibraryProvider>().findById(testId);
    if (importedTest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('This test could not be found.')),
      );
    }

    final test = importedTest.test;
    return Scaffold(
      appBar: AppBar(title: Text(importedTest.displayName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          importedTest.displayName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (test.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(test.description),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(label: '${test.questionCount} questions'),
                            _InfoChip(
                              label:
                                  '${test.effectiveEstimatedDuration.inMinutes} min',
                            ),
                            _InfoChip(label: test.difficulty.name),
                            if (test.topic.isNotEmpty)
                              _InfoChip(label: test.topic),
                            if (importedTest.bestScore != null)
                              _InfoChip(
                                label:
                                    'Best ${importedTest.bestScore!.toStringAsFixed(0)}%',
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Practice'),
                          onPressed: () =>
                              _start(context, test, TestMode.practice),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.assignment_outlined),
                          label: const Text('Start Exam'),
                          onPressed: () => _start(context, test, TestMode.exam),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _start(BuildContext context, TestModel test, TestMode mode) {
    context.read<TestProvider>().setCurrentTest(test);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PracticeScreen(mode: mode)),
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
