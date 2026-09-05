import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/answer_value_model.dart';
import '../providers/session_provider.dart';
import '../providers/test_provider.dart';
import '../widgets/answer_input_widget.dart';
import '../widgets/question_widget.dart';
import '../widgets/timer_widget.dart';
import 'results_screen.dart';

class ExamScreen extends StatefulWidget {
  final String? resumeSessionId;

  const ExamScreen({super.key, this.resumeSessionId});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  AnswerValue _currentAnswer = const AnswerValue.empty();
  bool _isStarting = true;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _openSession();
  }

  Future<void> _openSession() async {
    final sessionProvider = context.read<SessionProvider>();
    final testProvider = context.read<TestProvider>();

    if (widget.resumeSessionId != null) {
      final resumed = await sessionProvider.resumeSession(
        widget.resumeSessionId!,
      );
      if (!resumed) {
        _startupError = 'Saved exam session could not be restored.';
      } else if (sessionProvider.test != null) {
        testProvider.setCurrentTest(sessionProvider.test!);
      }
    } else if (testProvider.currentTest != null) {
      await sessionProvider.startSession(testProvider.currentTest!);
    } else {
      _startupError = 'No exam is loaded.';
    }

    _loadCurrentAnswer();
    if (mounted) {
      setState(() => _isStarting = false);
    }
  }

  void _loadCurrentAnswer() {
    final sessionProvider = context.read<SessionProvider>();
    final question = sessionProvider.currentQuestion;
    if (question == null) return;

    _currentAnswer = sessionProvider.getAnswerForQuestion(question.id);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _pauseAndExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          title: const Text('Exam'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _pauseAndExit,
          ),
          actions: [
            Consumer<SessionProvider>(
              builder: (context, sessionProvider, child) {
                if (sessionProvider.startTime == null) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TimerWidget(
                    startTime: sessionProvider.startTime!,
                    elapsed: sessionProvider.elapsedTime,
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Pause',
              icon: const Icon(Icons.pause_circle_outline),
              onPressed: _pauseAndExit,
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _isStarting || _startupError != null
            ? null
            : Consumer<SessionProvider>(
                builder: (context, sessionProvider, child) {
                  if (sessionProvider.currentQuestion == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildBottomActions(sessionProvider);
                },
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isStarting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_startupError != null) {
      return Center(child: Text(_startupError!));
    }

    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, child) {
        final question = sessionProvider.currentQuestion;
        if (question == null) {
          return const Center(child: Text('No questions available'));
        }

        final progress = sessionProvider.questions.isEmpty
            ? 0.0
            : (sessionProvider.currentQuestionIndex + 1) /
                  sessionProvider.questions.length;

        return _QuestionSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressHeader(sessionProvider, progress),
              const SizedBox(height: 16),
              QuestionWidget(
                question: question,
                questionNumber: sessionProvider.currentQuestionIndex + 1,
                totalQuestions: sessionProvider.questions.length,
              ),
              const SizedBox(height: 16),
              _buildAnswerPanel(sessionProvider),
              const SizedBox(height: 12),
              _buildQuestionMap(sessionProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressHeader(
    SessionProvider sessionProvider,
    double progress,
  ) {
    final question = sessionProvider.currentQuestion!;
    final flagged = sessionProvider.isQuestionFlagged(question.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sessionProvider.test?.title ?? 'Exam Session',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGray.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: flagged ? 'Remove flag' : 'Flag question',
              icon: Icon(flagged ? Icons.flag : Icons.flag_outlined),
              color: flagged ? AppColors.darkGold : AppColors.darkGray,
              onPressed: sessionProvider.toggleFlagCurrentQuestion,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppColors.lightSilver,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lightNavy),
        ),
        const SizedBox(height: 8),
        Text(
          'Question ${sessionProvider.currentQuestionIndex + 1} of '
          '${sessionProvider.questions.length} - '
          '${sessionProvider.answeredCount} answered',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAnswerPanel(SessionProvider sessionProvider) {
    final question = sessionProvider.currentQuestion!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightSilver),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnswerInputWidget(
              question: question,
              initialValue: _currentAnswer,
              revealAnswerFeedback: false,
              onAnswerChanged: (answer) async {
                _currentAnswer = answer;
                await sessionProvider.saveAnswer(answer);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionMap(SessionProvider sessionProvider) {
    final items = sessionProvider.questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final selected = index == sessionProvider.currentQuestionIndex;
      final answered = sessionProvider.isQuestionAnswered(question.id);
      final flagged = sessionProvider.isQuestionFlagged(question.id);

      return Padding(
        padding: const EdgeInsets.all(4),
        child: Tooltip(
          message: answered ? 'Answered' : 'Unanswered',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _goToQuestion(sessionProvider, index),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.navyBlue
                    : answered
                    ? AppColors.green.withValues(alpha: 0.15)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: flagged
                      ? AppColors.darkGold
                      : selected
                      ? AppColors.navyBlue
                      : AppColors.lightSilver,
                  width: flagged ? 2 : 1,
                ),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.darkGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightSilver),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [...items, const SizedBox(width: 8), _Legend()]),
        ),
      ),
    );
  }

  Widget _buildBottomActions(SessionProvider sessionProvider) {
    final canGoBack = sessionProvider.currentQuestionIndex > 0;

    return Material(
      color: AppColors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  onPressed: canGoBack
                      ? () => _previousQuestion(sessionProvider)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Pause',
                icon: const Icon(Icons.pause_circle_outline),
                onPressed: _pauseAndExit,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: Icon(
                    sessionProvider.isLastQuestion
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    sessionProvider.isLastQuestion ? 'Submit Exam' : 'Next',
                  ),
                  onPressed: () => _proceed(sessionProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goToQuestion(SessionProvider sessionProvider, int index) async {
    await sessionProvider.goToQuestion(index);
    setState(_loadCurrentAnswer);
  }

  Future<void> _previousQuestion(SessionProvider sessionProvider) async {
    await sessionProvider.previousQuestion();
    setState(_loadCurrentAnswer);
  }

  Future<void> _proceed(SessionProvider sessionProvider) async {
    if (sessionProvider.isLastQuestion) {
      final shouldFinish = await _confirmFinish(sessionProvider);
      if (shouldFinish != true) return;
      final timeTaken = sessionProvider.elapsedTime;
      await sessionProvider.completeSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(timeTaken: timeTaken),
        ),
      );
      return;
    }

    await sessionProvider.nextQuestion();
    setState(_loadCurrentAnswer);
  }

  Future<bool?> _confirmFinish(SessionProvider sessionProvider) {
    final unanswered =
        sessionProvider.questions.length - sessionProvider.answeredCount;
    if (unanswered == 0) return Future.value(true);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit exam?'),
        content: Text(
          '${sessionProvider.answeredCount} answered. '
          '$unanswered question${unanswered == 1 ? '' : 's'} unanswered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep answering'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _pauseAndExit() async {
    await context.read<SessionProvider>().pauseSession();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progress saved.')));
    Navigator.of(context).pop();
  }
}

class _QuestionSurface extends StatelessWidget {
  final Widget child;

  const _QuestionSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: child,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendRow(color: AppColors.navyBlue, label: 'Current'),
        SizedBox(width: 10),
        _LegendRow(color: AppColors.green, label: 'Answered'),
        SizedBox(width: 10),
        _LegendRow(color: AppColors.darkGold, label: 'Flagged'),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
