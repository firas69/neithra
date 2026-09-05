import 'dart:convert';

import '../models/test_model.dart';

class JsonParserService {
  static TestModel? parseJsonString(String jsonString) {
    try {
      final jsonData = json.decode(jsonString);
      if (jsonData is! Map<String, dynamic>) {
        throw Exception('Top-level JSON must be an object');
      }
      return _validateAndParseTest(jsonData);
    } catch (e) {
      throw Exception('Invalid JSON format: $e');
    }
  }

  static TestModel _validateAndParseTest(Map<String, dynamic> jsonData) {
    if (!jsonData.containsKey('title') || !jsonData.containsKey('questions')) {
      throw Exception('Missing required fields: title or questions');
    }

    final questionsData = jsonData['questions'];
    if (questionsData is! List || questionsData.isEmpty) {
      throw Exception('Questions array cannot be empty');
    }

    for (final questionData in questionsData) {
      if (questionData is! Map<String, dynamic>) {
        throw Exception('Each question must be an object');
      }
      _validateQuestion(questionData);
    }

    return TestModel.fromJson(jsonData);
  }

  static void _validateQuestion(Map<String, dynamic> questionData) {
    final id = questionData['id']?.toString();
    final type = questionData['type']?.toString();
    if (id == null || id.isEmpty || type == null || type.isEmpty) {
      throw Exception('Each question must have id and type fields');
    }

    final prompt = questionData['prompt'] ?? questionData['question'];
    if (prompt == null || prompt.toString().trim().isEmpty) {
      throw Exception('Question $id must include prompt or question text');
    }

    switch (type.toLowerCase()) {
      case 'single_choice':
      case 'singlechoice':
      case 'mcq':
        if (!questionData.containsKey('options')) {
          throw Exception('Question $id must include options');
        }
        if (!questionData.containsKey('correct_answer') &&
            !questionData.containsKey('correctAnswer')) {
          throw Exception('Question $id must include correct_answer');
        }
        break;
      case 'multiple_choice':
      case 'multiple_answer':
      case 'multiplechoice':
      case 'multi_select':
        if (!questionData.containsKey('options')) {
          throw Exception('Question $id must include options');
        }
        if (!questionData.containsKey('correct_answers') &&
            !questionData.containsKey('correctAnswer') &&
            !questionData.containsKey('correct_answer')) {
          throw Exception('Question $id must include correct answers');
        }
        break;
      case 'true_false':
      case 'truefalse':
      case 'boolean':
      case 'numerical':
      case 'number':
        if (!questionData.containsKey('correct_answer') &&
            !questionData.containsKey('correctAnswer')) {
          throw Exception('Question $id must include correct_answer');
        }
        break;
      case 'matching':
        if (!questionData.containsKey('matching_pairs') &&
            !questionData.containsKey('matchingPairs')) {
          throw Exception('Question $id must include matching_pairs');
        }
        break;
      case 'ordering':
      case 'sequencing':
        if (!questionData.containsKey('correct_order') &&
            !questionData.containsKey('correctOrder')) {
          throw Exception('Question $id must include correct_order');
        }
        break;
    }
  }

  static String getSampleJson() {
    return '''
{
  "title": "Symfony Learning Sprint",
  "topic": "Symfony fundamentals",
  "description": "Focused practice across Composer, HttpFoundation, DI, routing, Twig, and controller design.",
  "version": "2.0",
  "test_mode": "practice",
  "difficulty": "intermediate",
  "estimated_duration": 18,
  "categories": ["Composer", "Architecture", "Routing", "Dependency Injection"],
  "shuffle_questions": false,
  "shuffle_answers": false,
  "passing_score": 70,
  "questions": [
    {
      "id": "S001",
      "type": "single_choice",
      "question": "Which file defines autoloading rules in a Composer project?",
      "options": ["autoload.php", "composer.json", "composer.lock", "index.php"],
      "correct_answer": 1,
      "explanation": "Composer reads autoload rules from composer.json, then generates vendor/autoload.php.",
      "difficulty": "foundation",
      "category": "Composer",
      "skills": ["autoloading"],
      "estimated_time": 45,
      "points": 1
    },
    {
      "id": "S002",
      "type": "multiple_choice",
      "question": "Which statements are true about Symfony controllers?",
      "options": [
        "They can return Response objects",
        "They should contain all database schema definitions",
        "They coordinate request handling",
        "They can receive services through dependency injection"
      ],
      "correct_answers": [0, 2, 3],
      "explanation": "Controllers coordinate request handling and return responses; dependencies can be injected.",
      "category": "Architecture",
      "points": 2
    },
    {
      "id": "S003",
      "type": "true_false",
      "question": "Symfony routes can be defined with PHP attributes.",
      "correct_answer": true,
      "explanation": "Modern Symfony applications commonly use PHP attributes for route declarations.",
      "category": "Routing"
    },
    {
      "id": "S004",
      "type": "short_answer",
      "question": "What is the main benefit of using namespaces in PHP projects?",
      "accepted_answers": ["prevent name collisions"],
      "model_answer": "Namespaces organize code and prevent class name collisions in larger projects.",
      "keywords": [
        {"text": "collision", "weight": 1},
        {"text": "organize", "weight": 1},
        {"text": "maintain", "weight": 0.5}
      ],
      "category": "Architecture",
      "hint": "Think about what happens when two libraries define the same class name."
    },
    {
      "id": "S005",
      "type": "fill_blank",
      "question": "The Symfony object that represents an HTTP response is named ____.",
      "accepted_answers": ["Response", "Symfony\\\\Component\\\\HttpFoundation\\\\Response"],
      "explanation": "HttpFoundation provides the Response class.",
      "category": "HttpFoundation"
    },
    {
      "id": "S006",
      "type": "matching",
      "question": "Match each Symfony concept to its role.",
      "matching_pairs": {
        "Route": "Maps URL to controller",
        "Service": "Reusable application object",
        "Twig": "Template rendering"
      },
      "category": "Architecture",
      "points": 2
    },
    {
      "id": "S007",
      "type": "ordering",
      "question": "Order this simplified request lifecycle.",
      "correct_order": [
        "Request enters front controller",
        "Router matches a route",
        "Controller builds a response",
        "Response is sent"
      ],
      "category": "Routing",
      "points": 2
    },
    {
      "id": "S008",
      "type": "numerical",
      "question": "If a quiz has 20 questions worth 2 points each, how many total points are available?",
      "correct_answer": 40,
      "tolerance": 0,
      "category": "Assessment"
    },
    {
      "id": "S009",
      "type": "scenario",
      "scenario_context": "A controller directly creates three concrete service classes and is now hard to test.",
      "question": "What refactor would improve testability and maintainability?",
      "model_answer": "Inject dependencies through the constructor or method and depend on abstractions where useful.",
      "keywords": [
        {"text": "inject", "weight": 1},
        {"text": "dependency", "weight": 1},
        {"text": "test", "weight": 0.5}
      ],
      "category": "Dependency Injection",
      "points": 2
    },
    {
      "id": "S010",
      "type": "code",
      "question": "Write a minimal controller action that returns a JSON response.",
      "code_snippet": "use Symfony\\\\Component\\\\HttpFoundation\\\\JsonResponse;",
      "reference_solution": "public function status(): JsonResponse { return new JsonResponse(['ok' => true]); }",
      "rubric": {
        "checklist": [
          "Returns JsonResponse",
          "Defines an action method",
          "Provides serializable response data"
        ]
      },
      "category": "Controllers",
      "learning_objective": "Create framework-native responses",
      "points": 3
    }
  ]
}''';
  }
}
