import 'package:flutter/material.dart';
import 'dart:async';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/lesson.dart';
import '/app/models/quiz.dart';
import '/app/models/course.dart';
import '/app/models/module.dart';
import '/app/controllers/lesson_controller.dart';
import '/app/networking/api_service.dart';
import '/app/helpers/image_helper.dart';
import '/resources/pages/course_detail_page.dart';

class QuizPage extends NyStatefulWidget<LessonController> {
  static RouteView path = ("/quiz", (_) => QuizPage());

  QuizPage({super.key}) : super(child: () => _QuizPageState());
}

class _QuizPageState extends NyPage<QuizPage> {
  Lesson? lesson;
  Course? course;
  Module? module;
  bool? isModuleQuiz;
  List<Quiz> _quizzes = [];
  int _currentQuizIndex = 0;
  Map<int, String?> _selectedAnswers = {};
  int _score = 0;
  bool _quizCompleted = false;
  bool _showSummary = false; // Show summary page before submission
  bool _showResults = false; // Show results after submission
  Map<int, bool> _correctAnswers =
      {}; // Store which questions were answered correctly
  Timer? _timer;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  // Color scheme
  static const Color primary = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  bool _isLoading = false;
  String? _errorMessage;

  @override
  get init => () {
        final data = widget.data<Map<String, dynamic>>();
        if (data != null) {
          lesson = data['lesson'] as Lesson?;
          course = data['course'] as Course?;
          module = data['module'] as Module?;
          isModuleQuiz = data['isModuleQuiz'] as bool? ?? false;
          _loadQuizzes();
        }
      };
  Future<void> _loadQuizzes() async {
    if (course == null || module == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();

      if (isModuleQuiz == true) {
        // Module-level test
        final response =
            await api.fetchModuleTest(course!.id!, module!.id!.toString());
        final data = response['data'] ?? response;
        final test = data['test'];
        final questions = test['questions'] as List<dynamic>? ?? [];

        _quizzes = questions.map((q) {
          final quiz = Quiz();
          quiz.id = q['id']?.toString();
          quiz.question = q['question']?.toString();
          quiz.image = q['image']?.toString();

          final options = <QuizOption>[];
          final optionsMap = q['options'] as Map<String, dynamic>? ?? {};

          optionsMap.forEach((key, value) {
            if (value != null && value.toString().isNotEmpty) {
              final option = QuizOption();
              option.id = key; // e.g. option_a
              option.text = value.toString();
              option.isCorrect = (q['correct_answer']?.toString() ?? '') ==
                  key; // e.g. option_a
              options.add(option);
            }
          });

          quiz.options = options;
          quiz.explanation = q['explanation']?.toString();
          return quiz;
        }).toList();
      } else if (lesson != null && lesson!.id != null) {
        // Topic/lesson-level quiz
        final response = await api.fetchLessonTest(
          course!.id!,
          module!.id!.toString(),
          lesson!.id!.toString(),
        );
        final data = response['data'] ?? response;
        final test = data['test'];
        final questions = test['questions'] as List<dynamic>? ?? [];

        _quizzes = questions.map((q) {
          final quiz = Quiz();
          quiz.id = q['id']?.toString();
          quiz.question = q['question']?.toString();
          quiz.image = q['image']?.toString();

          final options = <QuizOption>[];
          final optionsMap = q['options'] as Map<String, dynamic>? ?? {};

          optionsMap.forEach((key, value) {
            if (value != null && value.toString().isNotEmpty) {
              final option = QuizOption();
              option.id = key;
              option.text = value.toString();
              option.isCorrect = (q['correct_answer']?.toString() ?? '') == key;
              options.add(option);
            }
          });

          quiz.options = options;
          quiz.explanation = q['explanation']?.toString();
          return quiz;
        }).toList();
      }

      if (_quizzes.isNotEmpty) {
        _startTimer();
      } else {
        _errorMessage = "No questions available for this test.";
      }
    } catch (e) {
      print('Error loading quizzes: $e');
      _errorMessage = "Failed to load test questions. Please try again.";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_seconds >= 60) {
          _seconds = 0;
          _minutes++;
          if (_minutes >= 60) {
            _minutes = 0;
            _hours++;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF0f172a);
    final secondaryTextColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : (Colors.grey[600] ?? Colors.grey);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            color: textColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Quiz",
            style: TextStyle(color: textColor),
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? "No quiz available",
            style: TextStyle(color: secondaryTextColor),
          ),
        ),
      );
    }

    // Show summary page if all questions answered
    if (_showSummary && !_showResults) {
      return _buildSummaryPage(bgColor, textColor, secondaryTextColor, isDark);
    }

    // Show results page after submission
    if (_showResults) {
      return _buildResultsPage(bgColor, textColor, secondaryTextColor, isDark);
    }

    final progress = (_currentQuizIndex + 1) / _quizzes.length;
    final progressPercent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Top Bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  color: textColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        (isModuleQuiz == true)
                            ? "MODULE ${module?.order ?? ''}: ${module?.title ?? 'Test'}"
                            : "LESSON TEST",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Points Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text("🔥", style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        "300",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress Bar Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${_currentQuizIndex + 1} of ${_quizzes.length}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                    Text(
                      "$progressPercent%",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark ? surfaceDark : Colors.grey[200],
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Timer Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 20, color: secondaryTextColor),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Text(
                        _hours.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        " Hr ",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        _minutes.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        " Min ",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        _seconds.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      Text(
                        " Sec",
                        style: TextStyle(
                          fontSize: 12,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    _quizzes[_currentQuizIndex].question ?? "",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Show image only if quiz has an image from backend
                  if (_quizzes[_currentQuizIndex].image != null &&
                      _quizzes[_currentQuizIndex].image!.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(
                            getImageUrl(_quizzes[_currentQuizIndex].image!),
                          ),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Figure ${(_currentQuizIndex + 1).toStringAsFixed(1)}: Field Diagram",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Answer Options
                  Text(
                    "SELECT ONE ANSWER",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _quizzes[_currentQuizIndex].options?.length ?? 0,
                    (index) {
                      final option =
                          _quizzes[_currentQuizIndex].options![index];
                      final isSelected =
                          _selectedAnswers[_currentQuizIndex] == option.id;
                      final isCorrect = option.isCorrect == true;
                      // Only show feedback after quiz is completed
                      final showFeedback = _quizCompleted;

                      return _buildAnswerOption(
                        option,
                        index,
                        isSelected,
                        isCorrect,
                        showFeedback,
                        textColor,
                        secondaryTextColor,
                        isDark,
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
          // Bottom Action Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: _buildBottomActions(
                textColor,
                secondaryTextColor,
                isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(
    QuizOption option,
    int index,
    bool isSelected,
    bool isCorrect,
    bool showFeedback,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!;
    Color bgColor = isDark ? surfaceDark : Colors.white;
    Color optionTextColor = secondaryTextColor;

    if (showFeedback) {
      if (isCorrect) {
        borderColor = primary;
        bgColor = primary.withValues(alpha: 0.1);
        optionTextColor = textColor;
      } else if (isSelected && !isCorrect) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        optionTextColor = textColor;
      }
    } else if (isSelected) {
      borderColor = primary;
      bgColor = primary.withValues(alpha: 0.05);
      optionTextColor = textColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: showFeedback
            ? null
            : () {
                setState(() {
                  _selectedAnswers[_currentQuizIndex] = option.id;
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Radio Button
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primary : borderColor,
                    width: 2,
                  ),
                  color: isSelected ? primary : Colors.transparent,
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
              // Option Text
              Expanded(
                child: Text(
                  option.text ?? "",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: optionTextColor,
                  ),
                ),
              ),
              // Correct/Wrong Indicator (only after quiz completion)
              if (showFeedback)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCorrect
                        ? primary
                        : (isSelected ? Colors.red : Colors.transparent),
                  ),
                  child: isCorrect
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : (isSelected
                          ? const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            )
                          : null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final hasAnswered = _selectedAnswers[_currentQuizIndex] != null;

    // If quiz is completed, show review/results
    if (_quizCompleted) {
      return _buildReviewActions(textColor, secondaryTextColor, isDark);
    }

    // Show Previous and Submit buttons
    return Row(
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
                foregroundColor: textColor,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey[300]!,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Previous",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (_currentQuizIndex > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: hasAnswered && !_quizCompleted
                ? () {
                    if (_currentQuizIndex < _quizzes.length - 1) {
                      // Move to next question
                      setState(() {
                        _currentQuizIndex++;
                      });
                    } else {
                      // Last question - show summary
                      setState(() {
                        _showSummary = true;
                      });
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasAnswered ? primary : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: hasAnswered ? 4 : 0,
              shadowColor: primary.withValues(alpha: 0.25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentQuizIndex < _quizzes.length - 1
                      ? "Next Question"
                      : "Review Test",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _currentQuizIndex < _quizzes.length - 1
                      ? Icons.arrow_forward
                      : Icons.checklist,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _completeQuiz() {
    _score = 0;
    _correctAnswers.clear();

    // Calculate score and mark correct answers
    for (int i = 0; i < _quizzes.length; i++) {
      final selectedAnswerId = _selectedAnswers[i];
      if (selectedAnswerId != null) {
        final selectedOption = _quizzes[i].options?.firstWhere(
              (opt) => opt.id == selectedAnswerId,
              orElse: () => QuizOption(),
            );
        final isCorrect = selectedOption?.isCorrect == true;
        _correctAnswers[i] = isCorrect;
        if (isCorrect) {
          _score++;
        }
      } else {
        _correctAnswers[i] = false;
      }
    }

    final percentage = (_score / _quizzes.length * 100).toInt();
    final passed = percentage >= 80; // 80% threshold for module tests

    // If this is a module quiz, update module test score
    if (isModuleQuiz == true && module != null) {
      module!.testScore = percentage;
      module!.testPassed = passed;

      // If passed, mark module as completed and reset retries
      if (passed) {
        module!.isCompleted = true;
        module!.testRetries = 0; // Reset retries on pass
      } else {
        // Increment retry count if failed (but don't increment if already at max)
        final currentRetries = module!.testRetries ?? 0;
        if (currentRetries < 3) {
          module!.testRetries = currentRetries + 1;
        }
      }
    }
  }

  Widget _buildReviewActions(
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final percentage = (_score / _quizzes.length * 100).toInt();
    final passed = percentage >= 80;
    final isLastQuestion = _currentQuizIndex == _quizzes.length - 1;
    final isFirstQuestion = _currentQuizIndex == 0;

    return Column(
      children: [
        // Score Summary
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: passed
                ? primary.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: passed ? primary : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passed ? "Test Passed!" : "Test Failed",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: passed ? primary : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Score: $_score / ${_quizzes.length} ($percentage%)",
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              if (isModuleQuiz == true)
                Text(
                  passed ? "Next Module Unlocked" : "Need 80% to Pass",
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
            ],
          ),
        ),
        // Navigation buttons
        Row(
          children: [
            if (!isFirstQuestion)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentQuizIndex--;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text("Previous"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (!isFirstQuestion) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isLastQuestion
                    ? () {
                        // Close and navigate back
                        Navigator.of(context).pop();
                        if (isModuleQuiz == true && passed && course != null) {
                          routeTo(CourseDetailPage.path,
                              data: {"course": course});
                        }
                      }
                    : () {
                        setState(() {
                          _currentQuizIndex++;
                        });
                      },
                icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward,
                    size: 20),
                label: Text(isLastQuestion ? "Done" : "Next Question"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: primary.withValues(alpha: 0.25),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryPage(
    Color bgColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final surfaceColor = isDark ? surfaceDark : Colors.white;
    final answeredCount =
        _selectedAnswers.values.where((a) => a != null).length;
    final unansweredCount = _quizzes.length - answeredCount;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: textColor,
          onPressed: () {
            setState(() {
              _showSummary = false;
            });
          },
        ),
        title: Text(
          "Review Your Answers",
          style: TextStyle(color: textColor),
        ),
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Test Summary",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      "Total Questions",
                      _quizzes.length.toString(),
                      textColor,
                      secondaryTextColor,
                    ),
                    _buildSummaryStat(
                      "Answered",
                      answeredCount.toString(),
                      primary,
                      secondaryTextColor,
                    ),
                    _buildSummaryStat(
                      "Unanswered",
                      unansweredCount.toString(),
                      Colors.orange,
                      secondaryTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Questions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quizzes.length,
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                final selectedAnswerId = _selectedAnswers[index];
                final hasAnswer = selectedAnswerId != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasAnswer
                          ? primary.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasAnswer
                                  ? primary.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: hasAnswer ? primary : Colors.orange,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              quiz.question ?? "Question ${index + 1}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          Icon(
                            hasAnswer ? Icons.check_circle : Icons.help_outline,
                            color: hasAnswer ? primary : Colors.orange,
                            size: 20,
                          ),
                        ],
                      ),
                      if (hasAnswer) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Your Answer: ${quiz.options?.firstWhere((o) => o.id == selectedAnswerId, orElse: () => QuizOption()).text ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Text(
                          "Not answered",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showSummary = false;
                          _currentQuizIndex = _quizzes.length - 1;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Go Back"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _submitQuiz();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Submit Test",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
      String label, String value, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  void _submitQuiz() {
    _completeQuiz();
    setState(() {
      _showSummary = false;
      _showResults = true;
    });
  }

  Widget _buildResultsPage(
    Color bgColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final percentage = (_score / _quizzes.length * 100).toInt();
    final passed = percentage >= 80;
    final surfaceColor = isDark ? surfaceDark : Colors.white;

    // Get retry count
    final retryCount = module?.testRetries ?? 0;
    final canRetake = retryCount < 3;
    final maxRetriesReached = retryCount >= 3;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Test Results",
          style: TextStyle(color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: passed
                    ? primary.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: passed ? primary : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: passed ? primary : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    passed ? "Congratulations!" : "Test Failed",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your Score",
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$percentage%",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: passed ? primary : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_score out of ${_quizzes.length} questions correct",
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                  if (!passed) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Minimum score required: 80%",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Retry Info
            if (!passed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      maxRetriesReached ? Icons.warning : Icons.info_outline,
                      color: maxRetriesReached ? Colors.orange : primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        maxRetriesReached
                            ? "You have reached the maximum number of retries (3). Please retake the course to continue."
                            : "Attempts remaining: ${3 - retryCount}",
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Action Buttons
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Review answers
                    setState(() {
                      _showResults = false;
                      _quizCompleted = true;
                      _currentQuizIndex = 0;
                    });
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text("Review Answers"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (!passed && canRetake) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Retake test
                      _retakeTest();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retake Test"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (course != null) {
                      routeTo(CourseDetailPage.path, data: {"course": course});
                    }
                  },
                  child: Text(
                    "Back to Course",
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _retakeTest() {
    // Reset quiz state
    setState(() {
      _currentQuizIndex = 0;
      _selectedAnswers.clear();
      _score = 0;
      _quizCompleted = false;
      _showSummary = false;
      _showResults = false;
      _correctAnswers.clear();
    });
  }
}
