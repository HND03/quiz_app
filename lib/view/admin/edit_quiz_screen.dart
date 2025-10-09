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

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty ||
        _timeLimitController.text.isNotEmpty ||
        _questionsItems.isNotEmpty) {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Discard Changes"),
              content: Text("Are you sure you want to discard changes?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    "Discard",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          title: Text(
            "Edit Quiz",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _updateQuiz,
              icon: Icon(Icons.save, color: AppTheme.primaryColor),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              Text(
                "Quiz Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                  labelText: "Quiz Title",
                  hintText: "Enter quiz title",
                  prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter quiz title";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _timeLimitController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                  labelText: "Time Limit (in minutes)",
                  hintText: "Enter time limit",
                  prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter time limit";
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return "Please enter a valid time limit";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        label: Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ..._questionsItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final QuestionFromItem item = entry.value;
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Question ${index + 1}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                if (_questionsItems.length > 1)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _removeQuestion(index),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: item.questionController,
                              decoration: InputDecoration(
                                labelText: "Question",
                                hintText: "Enter question",
                                prefixIcon: Icon(
                                  Icons.question_answer,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter question";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            ...item.optionsControllers.asMap().entries.map((
                              entry,
                            ) {
                              final optionIndex = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      activeColor: AppTheme.primaryColor,
                                      value: optionIndex,
                                      groupValue: item.correctOptionIndex,
                                      onChanged: (value) {
                                        setState(() {
                                          item.correctOptionIndex = value!;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          labelText:
                                              "Option ${optionIndex + 1}",
                                          hintText: "Enter Option",
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please enter option";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateQuiz,
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Update Quiz",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
