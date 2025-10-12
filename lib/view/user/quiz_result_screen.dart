import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:quiz_app/model/quiz.dart';
import 'package:quiz_app/theme/theme.dart';

class QuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final int totalQuestions;
  final int correctAnswers;
  final Map<int, int?> selectedAnswers;
  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.selectedAnswers,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 24, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    ).animate().scale(
      duration: Duration(milliseconds: 400),
      delay: Duration(milliseconds: 300),
    );
  }

  Widget _builAnswerRow(String label, String answer, Color answerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: answerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            answer,
            style: TextStyle(color: answerColor, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  IconData _getPerformanceIcon(double score) {
    if (score >= 0.9) return Icons.emoji_events;
    if (score >= 0.8) return Icons.star;
    if (score >= 0.6) return Icons.thumb_up;
    if (score >= 0.4) return Icons.trending_up;
    return Icons.refresh;
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.redAccent;
  }

  String _getPerformanceMessage(double score) {
    if (score >= 0.9) return "Outstanding!";
    if (score >= 0.8) return "Great Job!";
    if (score >= 0.6) return "Good Effort!";
    if (score >= 0.4) return "Keep Praticing!";
    return "Try Again!";
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.correctAnswers / widget.totalQuestions;
    final scorePercentage = (score * 100).round();
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Quiz Result',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CircularPercentIndicator(
                          radius: 100,
                          lineWidth: 15,
                          animation: true,
                          animationDuration: 1500,
                          percent: score,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${scorePercentage}%',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${widget.correctAnswers / widget.totalQuestions}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ).animate().scale(
                    delay: Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                  ),
                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPerformanceIcon(score),
                          color: _getScoreColor(score),
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _getPerformanceMessage(score),
                          style: TextStyle(
                            color: _getScoreColor(score),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(
                    begin: 0.1,
                    duration: Duration(milliseconds: 500),
                    delay: Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Correct",
                      widget.correctAnswers.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "InCorrect",
                      (widget.totalQuestions - widget.correctAnswers).toString(),
                      Icons.cancel,
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                          Icons.analytics,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
