import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/question.dart';
import '../../model/quiz.dart';
import '../../theme/theme.dart';

class EditQuizScreen extends StatefulWidget {
  final Quiz quiz;
  const EditQuizScreen({super.key, required this.quiz});

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class QuestionFromItem {
  final TextEditingController questionController;
  final List<TextEditingController> optionsControllers;
  int correctOptionIndex;

  QuestionFromItem({
    required this.questionController,
    required this.optionsControllers,
    required this.correctOptionIndex,
  });

  void dispose() {
    questionController.dispose();
    optionsControllers.forEach((element) => element.dispose());
  }
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController
  _titleController; //Khoi tao tri hoan, doi gia tri ban dau
  late TextEditingController _timeLimitController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  late List<QuestionFromItem> _questionsItems;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _titleController.dispose();
    _timeLimitController.dispose();
    for (var item in _questionsItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _initData() {
    _titleController = TextEditingController(text: widget.quiz.title);
    _timeLimitController = TextEditingController(
      text: widget.quiz.timeLimit.toString(),
    );

    _questionsItems = widget.quiz.questions.map((question) {
      return QuestionFromItem(
        questionController: TextEditingController(text: question.text),
        optionsControllers: question.options
            .map((option) => TextEditingController(text: option))
            .toList(),
        correctOptionIndex: question.correctOptionIndex,
      );
    }).toList();
  }

  void _addQuestion() {
    setState(() {
      _questionsItems.add(
        QuestionFromItem(
          questionController: TextEditingController(),
          optionsControllers: List.generate(4, (e) => TextEditingController()),
          correctOptionIndex: 0,
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    if (_questionsItems.length > 1) {
      setState(() {
        _questionsItems[index].dispose();
        _questionsItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Quiz must have at least one question",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _updateQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final questions = _questionsItems
          .map(
            (item) => Question(
              text: item.questionController.text.trim(),
              options: item.optionsControllers
                  .map((e) => e.text.trim())
                  .toList(),
              correctOptionIndex: item.correctOptionIndex,
            ),
          )
          .toList();
      final updateQuiz = widget.quiz.copyWith(
        title: _titleController.text.trim(),
        timeLimit: int.parse(_timeLimitController.text),
        questions: questions,
      );

      await _firestore
          .collection("quizzes")
          .doc(widget.quiz.id)
          .update(updateQuiz.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Quiz updated successfully",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to update quiz: $e",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: Text("Edit Quiz", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _updateQuiz,
            icon: Icon(
                Icons.save,
                color: AppTheme.primaryColor
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [],
        ),
      ),
    );
  }
}
