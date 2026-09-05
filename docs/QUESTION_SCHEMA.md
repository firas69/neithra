# Exam Definition Schema

Neithra loads assessments from JSON. The schema is intentionally permissive enough for
generated exams while still validating the fields needed for rendering and scoring.

## Exam-Level Fields

Required:

- `title`
- `questions`

Recommended:

- `topic`
- `description`
- `version`
- `test_mode`: legacy-compatible field; current app sessions start as exams
- `difficulty`: `foundation`, `intermediate`, `advanced`, or `mixed`
- `estimated_duration`: minutes
- `categories`
- `shuffle_questions`
- `shuffle_answers`
- `passing_score`

## Question-Level Fields

Required:

- `id`
- `type`
- `question` or `prompt`

Common optional metadata:

- `options`
- `correct_answer`
- `correct_answers`
- `accepted_answers`
- `explanation`
- `difficulty`
- `category`
- `subcategory`
- `topic`
- `tags`
- `skills`
- `estimated_time`
- `points`
- `negative_marking`
- `hint`
- `source`
- `question_group`
- `scenario_context`
- `code_snippet`
- `media`
- `shuffle_options`
- `learning_objective`
- `model_answer`
- `reference_solution`
- `rubric`
- `keywords`
- `matching_pairs`
- `correct_order`
- `tolerance`

## Supported Question Types

| Type | Required scoring fields |
| --- | --- |
| `single_choice` | `options`, `correct_answer` as option index |
| `multiple_choice` | `options`, `correct_answers` as option indexes |
| `true_false` | `correct_answer` as boolean |
| `short_answer` | `accepted_answers` or `keywords` |
| `fill_blank` | `accepted_answers` |
| `matching` | `matching_pairs` |
| `ordering` | `correct_order` |
| `numerical` | `correct_answer`, optional `tolerance` |
| `scenario` | `accepted_answers`, `keywords`, or `model_answer` |
| `code` | `rubric`, `reference_solution`, or text matching fields |
| `open_ended` | Learner self-evaluation |

## Example

See `samples/symfony_learning_sprint.json` for a complete assessment that exercises most
supported question types.

Small example:

```json
{
  "title": "Composer Basics",
  "topic": "PHP tooling",
  "test_mode": "exam",
  "questions": [
    {
      "id": "C001",
      "type": "single_choice",
      "question": "Which file defines Composer autoload rules?",
      "options": ["index.php", "composer.json", "composer.lock"],
      "correct_answer": 1,
      "explanation": "Composer reads autoload configuration from composer.json."
    }
  ]
}
```
