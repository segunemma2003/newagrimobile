import 'package:nylo_framework/nylo_framework.dart';

class QuizOption extends Model {
  String? id;
  String? text;
  bool? isCorrect;

  QuizOption() : super();

  QuizOption.fromJson(dynamic data) {
    id = data['id']?.toString();
    text = data['text'];
    isCorrect = data['is_correct'] ?? data['isCorrect'] ?? false;
  }

  @override
  toJson() => {
        "id": id,
        "text": text,
        "is_correct": isCorrect,
      };
}

class Quiz extends Model {
  String? id;
  String? lessonId;
  String? question;
  List<QuizOption>? options;
  String? explanation;

  static StorageKey key = 'quizzes';

  Quiz() : super(key: key);

  Quiz.fromJson(dynamic data) {
    id = data['id']?.toString();
    lessonId = data['lesson_id']?.toString() ?? data['lessonId']?.toString();
    question = data['question'];
    explanation = data['explanation'];
    if (data['options'] != null) {
      options = (data['options'] as List)
          .map((option) => QuizOption.fromJson(option))
          .toList();
    }
  }

  @override
  toJson() => {
        "id": id,
        "lesson_id": lessonId,
        "question": question,
        "explanation": explanation,
        "options": options?.map((o) => o.toJson()).toList(),
      };
}




