import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/question_model.dart';

class QuestionWidget extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightSilver),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(label: 'Question $questionNumber / $totalQuestions'),
                _Pill(label: question.typeLabel, quiet: true),
                if (question.difficulty != QuestionDifficulty.mixed)
                  _Pill(label: question.difficulty.name, quiet: true),
                if (question.points != 1)
                  _Pill(
                    label: '${question.points.toStringAsFixed(1)} pts',
                    quiet: true,
                  ),
              ],
            ),
            if (question.scenarioContext != null) ...[
              const SizedBox(height: 18),
              _ContextBlock(
                icon: Icons.article_outlined,
                child: Text(question.scenarioContext!),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              question.displayText,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 22, height: 1.35),
            ),
            if (question.codeSnippet != null) ...[
              const SizedBox(height: 18),
              _ContextBlock(
                icon: Icons.code,
                monospace: true,
                child: Text(question.codeSnippet!),
              ),
            ],
            if (question.hint != null) ...[
              const SizedBox(height: 14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Hint'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(question.hint!),
                  ),
                ],
              ),
            ],
            if (question.learningObjective != null ||
                question.category != null ||
                question.skills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (question.category != null)
                    _Pill(label: question.category!, quiet: true),
                  if (question.learningObjective != null)
                    _Pill(label: question.learningObjective!, quiet: true),
                  ...question.skills
                      .take(3)
                      .map((skill) => _Pill(label: skill, quiet: true)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool quiet;

  const _Pill({required this.label, this.quiet = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: quiet ? AppColors.lightGray : AppColors.navyBlue,
        borderRadius: BorderRadius.circular(16),
        border: quiet ? Border.all(color: AppColors.lightSilver) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: quiet ? AppColors.darkGray : AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ContextBlock extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final bool monospace;

  const _ContextBlock({
    required this.icon,
    required this.child,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightSilver),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.lightNavy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                height: 1.4,
                fontFamily: monospace ? 'monospace' : null,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
