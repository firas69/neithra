import 'dart:convert';

enum AnswerValueKind {
  empty,
  text,
  singleChoice,
  multipleChoice,
  boolean,
  matching,
  ordering,
  number,
}

class AnswerValue {
  final AnswerValueKind kind;
  final String? text;
  final int? selectedIndex;
  final List<int> selectedIndexes;
  final bool? booleanValue;
  final Map<String, String> pairs;
  final List<String> orderedItems;
  final double? numberValue;
  final bool? selfEvaluatedCorrect;

  const AnswerValue({
    required this.kind,
    this.text,
    this.selectedIndex,
    this.selectedIndexes = const [],
    this.booleanValue,
    this.pairs = const {},
    this.orderedItems = const [],
    this.numberValue,
    this.selfEvaluatedCorrect,
  });

  const AnswerValue.empty()
    : kind = AnswerValueKind.empty,
      text = null,
      selectedIndex = null,
      selectedIndexes = const [],
      booleanValue = null,
      pairs = const {},
      orderedItems = const [],
      numberValue = null,
      selfEvaluatedCorrect = null;

  factory AnswerValue.text(String value, {bool? selfEvaluatedCorrect}) {
    return AnswerValue(
      kind: AnswerValueKind.text,
      text: value,
      selfEvaluatedCorrect: selfEvaluatedCorrect,
    );
  }

  factory AnswerValue.singleChoice(int index) {
    return AnswerValue(
      kind: AnswerValueKind.singleChoice,
      selectedIndex: index,
    );
  }

  factory AnswerValue.multipleChoice(List<int> indexes) {
    final normalized = [...indexes]..sort();
    return AnswerValue(
      kind: AnswerValueKind.multipleChoice,
      selectedIndexes: normalized,
    );
  }

  factory AnswerValue.boolean(bool value) {
    return AnswerValue(kind: AnswerValueKind.boolean, booleanValue: value);
  }

  factory AnswerValue.matching(Map<String, String> pairs) {
    return AnswerValue(kind: AnswerValueKind.matching, pairs: pairs);
  }

  factory AnswerValue.ordering(List<String> items) {
    return AnswerValue(kind: AnswerValueKind.ordering, orderedItems: items);
  }

  factory AnswerValue.number(double value) {
    return AnswerValue(kind: AnswerValueKind.number, numberValue: value);
  }

  factory AnswerValue.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const AnswerValue.empty();

    final kind = AnswerValueKind.values.firstWhere(
      (value) => value.name == json['kind'],
      orElse: () => AnswerValueKind.text,
    );

    return AnswerValue(
      kind: kind,
      text: json['text']?.toString(),
      selectedIndex: json['selectedIndex'] as int?,
      selectedIndexes: List<int>.from(json['selectedIndexes'] ?? const []),
      booleanValue: json['booleanValue'] as bool?,
      pairs: Map<String, String>.from(json['pairs'] ?? const {}),
      orderedItems: List<String>.from(json['orderedItems'] ?? const []),
      numberValue: (json['numberValue'] as num?)?.toDouble(),
      selfEvaluatedCorrect: json['selfEvaluatedCorrect'] as bool?,
    );
  }

  factory AnswerValue.fromStorage(String? value) {
    if (value == null || value.trim().isEmpty) return const AnswerValue.empty();

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return AnswerValue.fromJson(decoded);
      }
    } catch (_) {
      return AnswerValue.text(value);
    }

    return AnswerValue.text(value);
  }

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      if (text != null) 'text': text,
      if (selectedIndex != null) 'selectedIndex': selectedIndex,
      if (selectedIndexes.isNotEmpty) 'selectedIndexes': selectedIndexes,
      if (booleanValue != null) 'booleanValue': booleanValue,
      if (pairs.isNotEmpty) 'pairs': pairs,
      if (orderedItems.isNotEmpty) 'orderedItems': orderedItems,
      if (numberValue != null) 'numberValue': numberValue,
      if (selfEvaluatedCorrect != null)
        'selfEvaluatedCorrect': selfEvaluatedCorrect,
    };
  }

  String toStorage() => jsonEncode(toJson());

  bool get isAnswered {
    switch (kind) {
      case AnswerValueKind.empty:
        return false;
      case AnswerValueKind.text:
        return text?.trim().isNotEmpty ?? false;
      case AnswerValueKind.singleChoice:
        return selectedIndex != null;
      case AnswerValueKind.multipleChoice:
        return selectedIndexes.isNotEmpty;
      case AnswerValueKind.boolean:
        return booleanValue != null;
      case AnswerValueKind.matching:
        return pairs.isNotEmpty &&
            pairs.values.every((value) => value.isNotEmpty);
      case AnswerValueKind.ordering:
        return orderedItems.isNotEmpty;
      case AnswerValueKind.number:
        return numberValue != null;
    }
  }

  String asDisplayText({List<String>? options}) {
    switch (kind) {
      case AnswerValueKind.empty:
        return 'No answer provided';
      case AnswerValueKind.text:
        return text?.trim().isEmpty ?? true ? 'No answer provided' : text!;
      case AnswerValueKind.singleChoice:
        if (selectedIndex == null) return 'No answer provided';
        if (options != null &&
            selectedIndex! >= 0 &&
            selectedIndex! < options.length) {
          return options[selectedIndex!];
        }
        return selectedIndex.toString();
      case AnswerValueKind.multipleChoice:
        if (selectedIndexes.isEmpty) return 'No answer provided';
        if (options != null) {
          return selectedIndexes
              .where((index) => index >= 0 && index < options.length)
              .map((index) => options[index])
              .join(', ');
        }
        return selectedIndexes.join(', ');
      case AnswerValueKind.boolean:
        return booleanValue == null
            ? 'No answer provided'
            : booleanValue!
            ? 'True'
            : 'False';
      case AnswerValueKind.matching:
        if (pairs.isEmpty) return 'No answer provided';
        return pairs.entries
            .map((entry) => '${entry.key} -> ${entry.value}')
            .join('\n');
      case AnswerValueKind.ordering:
        if (orderedItems.isEmpty) return 'No answer provided';
        return orderedItems
            .asMap()
            .entries
            .map((entry) => '${entry.key + 1}. ${entry.value}')
            .join('\n');
      case AnswerValueKind.number:
        return numberValue?.toString() ?? 'No answer provided';
    }
  }
}
