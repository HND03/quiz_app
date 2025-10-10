import 'dart:async';

import 'package:flutter/material.dart';
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
  late Timer? _timer;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pageController = PageController();
    _totalMinutes = widget.quiz.timeLimit;
    _remainingMinutes = _totalMinutes;
    _remainingSeconds = 0;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() {
    _timer?.cancel();
    int correctAnswers = _calculateScore();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Quiz Completed")));
    // Navigator.pushReplacement(context, MaterialPageRoute(
    //     builder: QuizResultScreen(
    //       quiz: widget.quiz,
    //       totalQuestions: widget.quiz.questions.length,
    //       correctAnswers: correctAnswers,
    //       selectedAnswers: _selectedAnswers,
    //     )));
  }

  int _calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final selectAnswer = _selectedAnswers[i];
      if(selectAnswer != null && selectAnswer == widget.quiz.questions[i].correctOptionIndex){
        correctAnswers++;
      }
    }
    return correctAnswers;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
