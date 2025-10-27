import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_app/model/category.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:quiz_app/view/user/quiz_play_screen.dart';
import '../../model/quiz.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Quiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('categoryId', isEqualTo: widget.category.id)
          .get();

      setState(() {
        _quizzes = snapshot.docs
            .map((doc) => Quiz.fromMap(doc.id, doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load quizzes")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = theme.scaffoldBackgroundColor;
    final textPrimary = theme.textTheme.bodyLarge?.color;
    final textSecondary = isDark ? Colors.grey[400] : AppTheme.textSecondaryColor;
    final cardColor = theme.cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      )
          : _quizzes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              "No quizzes available in this category",
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Go Back"),
            ),
          ],
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            foregroundColor: Colors.white,
            backgroundColor: theme.primaryColor,
            expandedHeight: 230,
            floating: false,
            pinned: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.category.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              background: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.category_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = _quizzes[index];
                  return _buildQuizCard(quiz, index, theme, textPrimary, textSecondary, cardColor);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(
      Quiz quiz,
      int index,
      ThemeData theme,
      Color? textPrimary,
      Color? textSecondary,
      Color cardColor,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuizPlayScreen(quiz: quiz)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz_rounded,
                  color: theme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.question_answer_outlined, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "${quiz.questions.length} Questions",
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer_outlined, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "${quiz.timeLimit} mins",
                            style: TextStyle(fontSize: 12, color: textSecondary),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 35,
                color: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .slideX(begin: 0.5, end: 0, duration: const Duration(milliseconds: 300))
        .fadeIn();
  }
}
