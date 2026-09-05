import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/test_attempt_model.dart';
import '../providers/history_provider.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam History')),
      body: SafeArea(
        child: Consumer<HistoryProvider>(
          builder: (context, historyProvider, child) {
            return RefreshIndicator(
              onRefresh: historyProvider.loadHistory,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (historyProvider.isLoading)
                            const LinearProgressIndicator(),
                          if (historyProvider.error != null) ...[
                            _ErrorPanel(message: historyProvider.error!),
                            const SizedBox(height: 12),
                          ],
                          if (historyProvider.attempts.isEmpty)
                            const _EmptyHistory()
                          else
                            ...historyProvider.attempts.map(
                              (attempt) => _AttemptCard(attempt: attempt),
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

class _AttemptCard extends StatelessWidget {
  final TestAttempt attempt;

  const _AttemptCard({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final color = attempt.scorePercentage >= 80
        ? AppColors.green
        : attempt.scorePercentage >= 60
        ? AppColors.darkGold
        : AppColors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            attempt.scorePercentage.toStringAsFixed(0),
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          attempt.testName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${_formatDateTime(attempt.completedAt)} - '
          '${attempt.correctAnswers}/${attempt.totalQuestions} correct - '
          '${_formatDuration(attempt.elapsedTime)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryDetailScreen(attemptId: attempt.id),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.history_outlined, color: AppColors.lightNavy),
            SizedBox(height: 12),
            Text(
              'No exam history yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text('Completed exams will appear here.'),
          ],
        ),
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

String _two(int value) => value.toString().padLeft(2, '0');
