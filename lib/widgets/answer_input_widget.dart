import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/answer_value_model.dart';
import '../models/question_model.dart';

class AnswerInputWidget extends StatefulWidget {
  final Question question;
  final AnswerValue initialValue;
  final ValueChanged<AnswerValue> onAnswerChanged;
  final bool revealAnswerFeedback;

  const AnswerInputWidget({
    super.key,
    required this.question,
    required this.initialValue,
    required this.onAnswerChanged,
    this.revealAnswerFeedback = false,
  });

  @override
  State<AnswerInputWidget> createState() => _AnswerInputWidgetState();
}

class _AnswerInputWidgetState extends State<AnswerInputWidget> {
  late TextEditingController _controller;
  late AnswerValue _answer;
  List<String> _orderedItems = [];

  @override
  void initState() {
    super.initState();
    _resetForQuestion();
  }

  @override
  void didUpdateWidget(AnswerInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id ||
        oldWidget.initialValue != widget.initialValue) {
      _controller.dispose();
      _resetForQuestion();
    }
  }

  void _resetForQuestion() {
    _answer = widget.initialValue;
    _controller = TextEditingController(text: _initialTextValue());
    _orderedItems = widget.initialValue.orderedItems.isNotEmpty
        ? [...widget.initialValue.orderedItems]
        : _defaultOrderItems();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(widget.question.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputWidget(),
        if (widget.revealAnswerFeedback && _answer.isAnswered) ...[
          const SizedBox(height: 12),
          _buildAnswerFeedback(),
        ],
      ],
    );
  }

  Widget _buildInputWidget() {
    switch (widget.question.type) {
      case QuestionType.singleChoice:
        return _buildSingleChoiceWidget();
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceWidget();
      case QuestionType.trueFalse:
        return _buildTrueFalseWidget();
      case QuestionType.matching:
        return _buildMatchingWidget();
      case QuestionType.ordering:
        return _buildOrderingWidget();
      case QuestionType.numerical:
        return _buildNumberInputWidget();
      case QuestionType.code:
        return _buildTextInputWidget(
          maxLines: 10,
          hintText: 'Write your solution...',
        );
      case QuestionType.shortAnswer:
      case QuestionType.fillBlank:
      case QuestionType.scenario:
        return _buildTextInputWidget(
          maxLines: 4,
          hintText: 'Type your answer...',
        );
      case QuestionType.openEnded:
        return _buildOpenEndedWidget();
    }
  }

  Widget _buildSingleChoiceWidget() {
    return Column(
      children: widget.question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final selected = _answer.selectedIndex == index;
        final correct = _isSingleCorrectIndex(index);
        final incorrect = widget.revealAnswerFeedback && selected && !correct;

        return _OptionCard(
          label: entry.value,
          selected: selected,
          correct: widget.revealAnswerFeedback && correct,
          incorrect: incorrect,
          leading: selected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          onTap: () => _emit(AnswerValue.singleChoice(index)),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceWidget() {
    final selected = _answer.selectedIndexes.toSet();
    return Column(
      children: widget.question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selected.contains(index);
        final correct = _isMultipleCorrectIndex(index);
        final incorrect = widget.revealAnswerFeedback && isSelected && !correct;

        return _OptionCard(
          label: option,
          selected: isSelected,
          correct: widget.revealAnswerFeedback && correct,
          incorrect: incorrect,
          leading: isSelected ? Icons.check_box : Icons.check_box_outline_blank,
          onTap: () {
            final next = {...selected};
            if (isSelected) {
              next.remove(index);
            } else {
              next.add(index);
            }
            _emit(AnswerValue.multipleChoice(next.toList()));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseWidget() {
    return Column(
      children: [true, false].map((value) {
        final selected = _answer.booleanValue == value;
        final correct = _boolValue(widget.question.correctAnswer) == value;
        return _OptionCard(
          label: value ? 'True' : 'False',
          selected: selected,
          correct: widget.revealAnswerFeedback && correct,
          incorrect: widget.revealAnswerFeedback && selected && !correct,
          leading: selected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          onTap: () => _emit(AnswerValue.boolean(value)),
        );
      }).toList(),
    );
  }

  Widget _buildMatchingWidget() {
    final leftItems = widget.question.matchingPairs.keys.toList();
    final rightItems = widget.question.matchingPairs.values.toSet().toList();
    final pairs = {..._answer.pairs};

    return Column(
      children: leftItems.map((left) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  left,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: pairs[left]?.isEmpty ?? true
                      ? null
                      : pairs[left],
                  items: rightItems
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Match'),
                  onChanged: (value) {
                    pairs[left] = value ?? '';
                    _emit(AnswerValue.matching(pairs));
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderingWidget() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orderedItems.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _orderedItems.removeAt(oldIndex);
          _orderedItems.insert(newIndex, item);
        });
        _emit(AnswerValue.ordering(_orderedItems));
      },
      itemBuilder: (context, index) {
        return ListTile(
          key: ValueKey(_orderedItems[index]),
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.navyBlue,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: AppColors.white, fontSize: 12),
            ),
          ),
          title: Text(_orderedItems[index]),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }

  Widget _buildNumberInputWidget() {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        hintText: 'Enter a number',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final parsed = double.tryParse(value.trim());
        if (parsed == null) {
          _emit(const AnswerValue.empty());
        } else {
          _emit(AnswerValue.number(parsed));
        }
      },
    );
  }

  Widget _buildTextInputWidget({
    required int maxLines,
    required String hintText,
  }) {
    return TextField(
      controller: _controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => _emit(AnswerValue.text(value)),
    );
  }

  Widget _buildOpenEndedWidget() {
    return Column(
      children: [
        TextField(
          controller: _controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Write your response...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _emit(
            AnswerValue.text(
              value,
              selfEvaluatedCorrect: _answer.selfEvaluatedCorrect,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('My answer meets the expected answer'),
          value: _answer.selfEvaluatedCorrect ?? false,
          onChanged: (checked) {
            _emit(
              AnswerValue.text(
                _controller.text,
                selfEvaluatedCorrect: checked ?? false,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnswerFeedback() {
    final score = widget.question.scoreAnswer(_answer);
    final color = score.isCorrect ? AppColors.green : AppColors.red;
    final label = score.needsManualReview
        ? 'Review this against the explanation'
        : score.isCorrect
        ? 'Correct'
        : 'Try again';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  List<String> _defaultOrderItems() {
    if (widget.question.options.isNotEmpty) return [...widget.question.options];
    if (widget.question.correctOrder.isNotEmpty) {
      final items = [...widget.question.correctOrder];
      items.shuffle();
      return items;
    }
    return const [];
  }

  String _initialTextValue() {
    if (widget.initialValue.text != null) return widget.initialValue.text!;
    if (widget.initialValue.numberValue != null) {
      return widget.initialValue.numberValue!.toString();
    }
    return '';
  }

  bool _isSingleCorrectIndex(int index) {
    return _intValue(widget.question.correctAnswer) == index;
  }

  bool _isMultipleCorrectIndex(int index) {
    if (widget.question.correctAnswers.isNotEmpty) {
      return widget.question.correctAnswers.map(_intValue).contains(index);
    }
    final answer = widget.question.correctAnswer;
    if (answer is List) return answer.map(_intValue).contains(index);
    return _intValue(answer) == index;
  }

  void _emit(AnswerValue answer) {
    setState(() {
      _answer = answer;
    });
    widget.onAnswerChanged(answer);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool incorrect;
  final IconData leading;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.selected,
    required this.correct,
    required this.incorrect,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct
        ? AppColors.green
        : incorrect
        ? AppColors.red
        : selected
        ? AppColors.navyBlue
        : AppColors.lightSilver;
    final icon = correct
        ? Icons.check_circle
        : incorrect
        ? Icons.cancel
        : leading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: correct
            ? AppColors.green.withValues(alpha: 0.08)
            : incorrect
            ? AppColors.red.withValues(alpha: 0.08)
            : selected
            ? AppColors.navyBlue.withValues(alpha: 0.06)
            : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: selected ? 2 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: selected || correct
                          ? FontWeight.w700
                          : FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}
