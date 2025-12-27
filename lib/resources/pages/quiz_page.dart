import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lesson.dart';
import '/app/models/quiz.dart';
import '/app/models/course.dart';
import '/app/controllers/lesson_controller.dart';
import '/resources/widgets/safearea_widget.dart';
import '/bootstrap/extensions.dart';

class QuizPage extends NyStatefulWidget<LessonController> {
  static RouteView path = ("/quiz", (_) => QuizPage());

  QuizPage({super.key}) : super(child: () => _QuizPageState());
}

class _QuizPageState extends NyPage<QuizPage> {
  Lesson? lesson;
  Course? course;
  int _currentQuizIndex = 0;
  Map<int, String?> _selectedAnswers = {};
  Map<int, bool> _showResults = {};
  int _score = 0;
  bool _quizCompleted = false;

  @override
  get init => () {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          lesson = data['lesson'] as Lesson?;
          course = data['course'] as Course?;
        }
      };

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  Widget view(BuildContext context) {
    if (lesson == null || lesson!.quizzes == null || lesson!.quizzes!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "Quiz",
            style: TextStyle(color: Color(0xFF1A1A1A)),
          ),
        ),
        body: const Center(
          child: Text(
            "No quiz available",
            style: TextStyle(color: Color(0xFF666666)),
          ),
        ),
      );
    }

    final quizzes = lesson!.quizzes!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Quiz: ${lesson!.title ?? 'Lesson Quiz'}",
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeAreaWidget(
        child: _quizCompleted
            ? _buildResults(context, quizzes)
            : _buildQuizQuestion(context, quizzes),
      ),
    );
  }

  Widget _buildQuizQuestion(BuildContext context, List<Quiz> quizzes) {
    if (_currentQuizIndex >= quizzes.length) {
      _completeQuiz(quizzes);
      return _buildResults(context, quizzes);
    }

    final quiz = quizzes[_currentQuizIndex];
    final hasAnswered = _selectedAnswers[_currentQuizIndex] != null;
    final showResult = _showResults[_currentQuizIndex] ?? false;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Progress bar at top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${_currentQuizIndex + 1} of ${quizzes.length}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      "${((_currentQuizIndex + 1) / quizzes.length * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentQuizIndex + 1) / quizzes.length,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E5E5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D8659)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Question and Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    quiz.question ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Options
                  ...List.generate(quiz.options?.length ?? 0, (index) {
                    final option = quiz.options![index];
                    final isSelected = _selectedAnswers[_currentQuizIndex] == option.id;
                    final isCorrect = option.isCorrect == true;
                    
                    Color borderColor = const Color(0xFFE5E5E5);
                    Color backgroundColor = Colors.white;
                    Color textColor = const Color(0xFF1A1A1A);
                    
                    if (showResult) {
                      if (isCorrect) {
                        borderColor = Colors.green;
                        backgroundColor = Colors.green.withOpacity(0.1);
                        textColor = Colors.green[700]!;
                      } else if (isSelected && !isCorrect) {
                        borderColor = Colors.red;
                        backgroundColor = Colors.red.withOpacity(0.1);
                        textColor = Colors.red[700]!;
                      }
                    } else if (isSelected) {
                      borderColor = const Color(0xFF2D8659);
                      backgroundColor = const Color(0xFF2D8659).withOpacity(0.1);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: showResult
                              ? null
                              : () {
                                  setState(() {
                                    _selectedAnswers[_currentQuizIndex] = option.id;
                                  });
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                    color: isSelected ? borderColor : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.text ?? "",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (showResult && isCorrect)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                else if (showResult && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Explanation (if shown)
                  if (showResult && quiz.explanation != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2D8659).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Color(0xFF2D8659), size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Explanation",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D8659),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            quiz.explanation!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                if (_currentQuizIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuizIndex--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2D8659)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Previous",
                        style: TextStyle(
                          color: Color(0xFF2D8659),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentQuizIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: hasAnswered
                        ? () {
                            if (!showResult) {
                              setState(() {
                                _showResults[_currentQuizIndex] = true;
                              });
                            } else {
                              setState(() {
                                _currentQuizIndex++;
                              });
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAnswered ? const Color(0xFF2D8659) : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      showResult ? "Next Question" : "Submit Answer",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<Quiz> quizzes) {
    final percentage = (_score / quizzes.length * 100).toInt();
    final isPassed = percentage >= 70;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: isPassed ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            isPassed ? "Congratulations!" : "Try Again",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ).displayLarge(color: context.color.primaryAccent),
          const SizedBox(height: 16),
          Text(
            "You scored $_score out of ${quizzes.length}",
            style: const TextStyle(fontSize: 18),
          ).titleLarge(color: context.color.content),
          const SizedBox(height: 8),
          Text(
            "$percentage%",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ).displayLarge(color: isPassed ? Colors.green : Colors.red),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              if (isPassed && lesson != null) {
                await widget.controller.markLessonCompleted(lesson!.id!);
                showToastSuccess(
                  title: "Quiz Passed",
                  description: "Lesson marked as completed",
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _completeQuiz(List<Quiz> quizzes) {
    if (_quizCompleted) return;

    _quizCompleted = true;
    _score = 0;

    for (int i = 0; i < quizzes.length; i++) {
      final selectedAnswerId = _selectedAnswers[i];
      if (selectedAnswerId != null) {
        final selectedOption = quizzes[i].options?.firstWhere(
          (opt) => opt.id == selectedAnswerId,
          orElse: () => QuizOption(),
        );
        if (selectedOption?.isCorrect == true) {
          _score++;
        }
      }
    }
  }
}

