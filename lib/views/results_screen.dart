import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/answer_value_model.dart';
import '../models/question_model.dart';
import '../models/result_model.dart';
import '../models/test_attempt_model.dart';
import '../models/test_model.dart';
import '../providers/history_provider.dart';
import '../providers/result_provider.dart';
import '../providers/session_provider.dart';
import '../providers/test_library_provider.dart';
import '../providers/test_provider.dart';
import 'app_shell.dart';
import 'practice_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Duration? timeTaken;

  const ResultsScreen({super.key, this.timeTaken});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _attemptSaved = false;

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  Future<void> _calculateResults() async {
    final sessionProvider = context.read<SessionProvider>();
    final resultProvider = context.read<ResultProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final libraryProvider = context.read<TestLibraryProvider>();

    if (sessionProvider.sessionId != null && sessionProvider.test != null) {
      await resultProvider.calculateResult(
        sessionId: sessionProvider.sessionId!,
        testTitle: sessionProvider.test!.title,
        questions: sessionProvider.questions,
        responses: sessionProvider.answers,
        timeTaken: widget.timeTaken ?? sessionProvider.elapsedTime,
      );
      final result = resultProvider.currentResult;
      final startedAt = sessionProvider.startTime;
      if (!_attemptSaved && result != null && startedAt != null) {
        _attemptSaved = true;
        final attempt = TestAttempt.fromResult(
          testId: sessionProvider.test!.id,
          result: result,
          questions: sessionProvider.questions,
          startedAt: startedAt,
        );
        await historyProvider.saveAttempt(attempt);
        await libraryProvider.loadTests();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home),
            onPressed: _navigateToHome,
          ),
        ],
      ),
      body: Consumer<ResultProvider>(
        builder: (context, resultProvider, child) {
          if (resultProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = resultProvider.currentResult;
          if (result == null) {
            return const Center(child: Text('No results available'));
          }

          final sessionProvider = context.read<SessionProvider>();
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 320,
                                child: _buildSummary(result),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildReviewList(
                                  result,
                                  sessionProvider.questions,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildSummary(result),
                              const SizedBox(height: 16),
                              _buildReviewList(
                                result,
                                sessionProvider.questions,
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummary(ResultModel result) {
    final scoreColor = result.scorePercentage >= 80
        ? AppColors.green
        : result.scorePercentage >= 60
        ? AppColors.darkGold
        : AppColors.red;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightSilver),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${result.scorePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: scoreColor,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.correctAnswers}/${result.totalQuestions} correct',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            Text(
              '${result.earnedPoints.toStringAsFixed(1)} / '
              '${result.maxPoints.toStringAsFixed(1)} points',
            ),
            const SizedBox(height: 18),
            _SummaryRow(
              icon: Icons.timer,
              label: 'Time',
              value: _formatDuration(result.timeTaken),
            ),
            _SummaryRow(
              icon: Icons.rate_review_outlined,
              label: 'Manual review',
              value: '${result.manualReviewQuestions}',
            ),
            const Divider(height: 28),
            Text(
              'Weakest areas',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (result.weakestCategories.isEmpty)
              const Text('No category data yet.')
            else
              ...result.weakestCategories.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(
                    value: entry.value,
                    minHeight: 8,
                    backgroundColor: AppColors.lightSilver,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      entry.value >= 0.7 ? AppColors.green : AppColors.red,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.fitness_center),
              label: const Text('Practice Weaknesses'),
              onPressed: () => _startWeaknessPractice(result),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList(ResultModel result, List<Question> questions) {
    return Column(
      children: questions.map((question) {
        final answer =
            result.responses[question.id] ?? const AnswerValue.empty();
        final score = question.scoreAnswer(answer);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightSilver),
            ),
            child: ExpansionTile(
              initiallyExpanded: !score.isCorrect,
              leading: Icon(
                score.needsManualReview
                    ? Icons.rate_review_outlined
                    : score.isCorrect
                    ? Icons.check_circle
                    : Icons.cancel,
                color: score.needsManualReview
                    ? AppColors.darkGold
                    : score.isCorrect
                    ? AppColors.green
                    : AppColors.red,
              ),
              title: Text(question.displayText),
              subtitle: Text(
                '${question.typeLabel} - '
                '${score.earnedPoints.toStringAsFixed(1)} / '
                '${score.maxPoints.toStringAsFixed(1)} pts',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _ReviewBlock(
                  title: 'Your answer',
                  body: answer.asDisplayText(options: question.options),
                ),
                const SizedBox(height: 10),
                _ReviewBlock(
                  title: 'Expected answer',
                  body: question.correctAnswerDisplay(),
                ),
                if (question.explanation != null) ...[
                  const SizedBox(height: 10),
                  _ReviewBlock(
                    title: 'Explanation',
                    body: question.explanation!,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _startWeaknessPractice(ResultModel result) {
    final categories = result.weakestCategories
        .map((entry) => entry.key)
        .toList();
    final testProvider = context.read<TestProvider>();
    final weaknessTest = testProvider.createWeaknessPractice(categories);
    if (weaknessTest == null) return;

    testProvider.setCurrentTest(weaknessTest);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const PracticeScreen(mode: TestMode.weaknessPractice),
      ),
    );
  }

  void _navigateToHome() {
    context.read<SessionProvider>().resetSession();
    context.read<ResultProvider>().clearResult();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AppShell()),
      (route) => false,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lightNavy, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
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
