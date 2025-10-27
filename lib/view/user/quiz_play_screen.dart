import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:quiz_app/view/user/quiz_result_screen.dart';
import '../../model/question.dart';
import '../../model/quiz.dart';

class QuizPlayScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  Map<int, int?> _selectedAnswers = {};
  int _totalMinutes = 0;
  int _remainingMinutes = 0;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _totalMinutes = widget.quiz.timeLimit;
    _remainingMinutes = _totalMinutes;
    _remainingSeconds = 0;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          if (_remainingMinutes > 0) {
            _remainingMinutes--;
            _remainingSeconds = 59;
          } else {
            _timer?.cancel();
            _completeQuiz();
          }
        }
      });
    });
  }

  void _selectAnswer(int optionIndex) {
    if (_selectedAnswers[_currentQuestionIndex] == null) {
      setState(() {
        _selectedAnswers[_currentQuestionIndex] = optionIndex;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() {
    _timer?.cancel();
    int correctAnswers = _calculateScore();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Quiz Completed")),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          quiz: widget.quiz,
          totalQuestions: widget.quiz.questions.length,
          correctAnswers: correctAnswers,
          selectedAnswers: _selectedAnswers,
        ),
      ),
    );
  }

  int _calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final selectAnswer = _selectedAnswers[i];
      if (selectAnswer != null &&
          selectAnswer == widget.quiz.questions[i].correctOptionIndex) {
        correctAnswers++;
      }
    }
    return correctAnswers;
  }

  Color _getTimerColor() {
    double timeProgress =
        1 - ((_remainingMinutes * 60 + _remainingSeconds) / (_totalMinutes * 60));
    if (timeProgress < 0.4) return Colors.green;
    if (timeProgress < 0.6) return Colors.orange;
    if (timeProgress < 0.8) return Colors.deepOrangeAccent;
    return Colors.redAccent;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textPrimary = theme.textTheme.bodyLarge?.color;
    final textSecondary =
    isDark ? Colors.grey[400] : AppTheme.textSecondaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Timer + Progress
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: theme.primaryColor,
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 55,
                            width: 55,
                            child: CircularProgressIndicator(
                              value: (_remainingMinutes * 60 + _remainingSeconds) /
                                  (_totalMinutes * 60),
                              strokeWidth: 5,
                              backgroundColor:
                              isDark ? Colors.grey[800] : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTimerColor(),
                              ),
                            ),
                          ),
                          Text(
                            "$_remainingMinutes:${_remainingSeconds.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getTimerColor(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: (_currentQuestionIndex + 1) /
                          widget.quiz.questions.length,
                    ),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, progress, child) {
                      return LinearProgressIndicator(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10),
                          right: Radius.circular(10),
                        ),
                        value: progress,
                        backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                        minHeight: 6,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Questions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.quiz.questions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentQuestionIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final question = widget.quiz.questions[index];
                  return _buildQuestionCard(
                    question,
                    index,
                    theme,
                    textPrimary,
                    textSecondary,
                    isDark,
                    cardColor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
      Question question,
      int index,
      ThemeData theme,
      Color? textPrimary,
      Color? textSecondary,
      bool isDark,
      Color cardColor,
      ) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1}',
            style: TextStyle(fontSize: 16, color: textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            final isSelected = _selectedAnswers[index] == optionIndex;
            final isCorrect =
                _selectedAnswers[index] == question.correctOptionIndex;

            final bgColor = isSelected
                ? (isCorrect
                ? AppTheme.secondaryColor.withOpacity(0.15)
                : Colors.redAccent.withOpacity(0.15))
                : cardColor;

            final borderColor = isSelected
                ? (isCorrect ? AppTheme.secondaryColor : Colors.redAccent)
                : (isDark ? Colors.grey[700]! : Colors.grey.shade300);

            final textColor = isSelected
                ? (isCorrect
                ? AppTheme.secondaryColor
                : Colors.redAccent)
                : (_selectedAnswers[index] != null
                ? (isDark ? Colors.grey[500]! : Colors.grey.shade600)
                : textPrimary);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: ListTile(
                  onTap: _selectedAnswers[index] == null
                      ? () => _selectAnswer(optionIndex)
                      : null,
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.close,
                    color:
                    isCorrect ? AppTheme.secondaryColor : Colors.redAccent,
                  )
                      : null,
                ),
              ),
            )
                .animate(delay: const Duration(milliseconds: 300))
                .slideX(begin: 0.5, end: 0, duration: const Duration(milliseconds: 300))
                .fadeIn();
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _selectedAnswers[index] != null ? _nextQuestion : null,
              child: Text(
                index == widget.quiz.questions.length - 1
                    ? "Finish Quiz"
                    : "Next Question",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
