import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/test_attempt_model.dart';
import '../providers/history_provider.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String attemptId;

  const HistoryDetailScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context) {
    final attempt = context.watch<HistoryProvider>().findById(attemptId);
    if (attempt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attempt')),
        body: const Center(child: Text('This attempt could not be found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Attempt detail')),
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
                    _Summary(attempt: attempt),
                    const SizedBox(height: 16),
                    ...attempt.questionResults.asMap().entries.map(
                      (entry) => _QuestionResultCard(
                        number: entry.key + 1,
                        result: entry.value,
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
  }
}

class _Summary extends StatelessWidget {
  final TestAttempt attempt;

  const _Summary({required this.attempt});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attempt.testName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.folder_outlined,
                  label: attempt.familyName,
                ),
                _InfoChip(
                  icon: Icons.percent,
                  label: '${attempt.scorePercentage.toStringAsFixed(1)}%',
                ),
                _InfoChip(
                  icon: Icons.check_circle_outline,
                  label:
                      '${attempt.correctAnswers}/${attempt.totalQuestions} correct',
                ),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: _formatDuration(attempt.elapsedTime),
                ),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDateTime(attempt.completedAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionResultCard extends StatelessWidget {
  final int number;
  final QuestionAttemptResult result;

  const _QuestionResultCard({required this.number, required this.result});

  @override
  Widget build(BuildContext context) {
    final icon = result.needsManualReview
        ? Icons.rate_review_outlined
        : result.isCorrect
        ? Icons.check_circle
        : Icons.cancel;
    final color = result.needsManualReview
        ? AppColors.darkGold
        : result.isCorrect
        ? AppColors.green
        : AppColors.red;
    final status = result.needsManualReview
        ? 'Needs review'
        : result.isCorrect
        ? 'Correct'
        : 'Incorrect';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text('Question $number'),
        subtitle: Text('$status - ${result.questionType}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _ReviewBlock(title: 'Question', body: result.questionText),
          const SizedBox(height: 10),
          _ReviewBlock(title: 'Your answer', body: result.userAnswerText),
          const SizedBox(height: 10),
          _ReviewBlock(title: 'Correct answer', body: result.correctAnswerText),
          if (result.explanation != null &&
              result.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _ReviewBlock(title: 'Explanation', body: result.explanation!),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: AppColors.lightGray,
    );
  }
}

class _ReviewBlock extends StatelessWidget {
  final String title;
  final String body;

  const _ReviewBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightSilver),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m ${duration.inSeconds.remainder(60)}s';
}

String _two(int value) => value.toString().padLeft(2, '0');
