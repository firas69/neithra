import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/answer_value_model.dart';
import '../models/question_model.dart';

class AnswerInputWidget extends StatefulWidget {
  final Question question;
  final AnswerValue initialValue;
  final ValueChanged<AnswerValue> onAnswerChanged;
  final bool revealPracticeFeedback;

  const AnswerInputWidget({
    super.key,
    required this.question,
    required this.initialValue,
    required this.onAnswerChanged,
    this.revealPracticeFeedback = false,
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
    if (widget.question.type == QuestionType.ordering &&
        !_answer.isAnswered &&
        _orderedItems.isNotEmpty) {
      _answer = AnswerValue.ordering(_orderedItems);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAnswerChanged(_answer);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(widget.question.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputWidget(),
        if (widget.revealPracticeFeedback && _answer.isAnswered) ...[
          const SizedBox(height: 12),
          _buildPracticeFeedback(),
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
    return RadioGroup<int>(
      groupValue: _answer.selectedIndex,
      onChanged: (value) {
        if (value == null) return;
        _emit(AnswerValue.singleChoice(value));
      },
      child: Column(
        children: widget.question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          return RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            title: Text(option),
            value: index,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultipleChoiceWidget() {
    final selected = _answer.selectedIndexes.toSet();
    return Column(
      children: widget.question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(option),
          value: selected.contains(index),
          onChanged: (checked) {
            final next = {...selected};
            if (checked == true) {
              next.add(index);
            } else {
              next.remove(index);
            }
            _emit(AnswerValue.multipleChoice(next.toList()));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseWidget() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('True')),
        ButtonSegment(value: false, label: Text('False')),
      ],
      selected: _answer.booleanValue == null
          ? <bool>{}
          : {_answer.booleanValue!},
      emptySelectionAllowed: true,
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          _emit(AnswerValue.boolean(selection.first));
        }
      },
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

  Widget _buildPracticeFeedback() {
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
