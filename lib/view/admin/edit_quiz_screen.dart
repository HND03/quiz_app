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
    for (var c in optionsControllers) {
      c.dispose();
    }
  }
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _timeLimitController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  late List<QuestionFromItem> _questionsItems;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    _titleController = TextEditingController(text: widget.quiz.title);
    _timeLimitController =
        TextEditingController(text: widget.quiz.timeLimit.toString());
    _questionsItems = widget.quiz.questions
        .map(
          (q) => QuestionFromItem(
        questionController: TextEditingController(text: q.text),
        optionsControllers:
        q.options.map((o) => TextEditingController(text: o)).toList(),
        correctOptionIndex: q.correctOptionIndex,
      ),
    )
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    for (var item in _questionsItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionsItems.add(
        QuestionFromItem(
          questionController: TextEditingController(),
          optionsControllers: List.generate(4, (_) => TextEditingController()),
          correctOptionIndex: 0,
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    if (_questionsItems.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quiz must have at least one question"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _questionsItems[index].dispose();
      _questionsItems.removeAt(index);
    });
  }

  Future<void> _updateQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final questions = _questionsItems
          .map(
            (item) => Question(
          text: item.questionController.text.trim(),
          options:
          item.optionsControllers.map((e) => e.text.trim()).toList(),
          correctOptionIndex: item.correctOptionIndex,
        ),
      )
          .toList();

      final updatedQuiz = widget.quiz.copyWith(
        title: _titleController.text.trim(),
        timeLimit: int.parse(_timeLimitController.text),
        questions: questions,
      );

      await _firestore
          .collection("quizzes")
          .doc(widget.quiz.id)
          .update(updatedQuiz.toMap(isUpdate: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quiz updated successfully"),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update quiz: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty ||
        _timeLimitController.text.isNotEmpty ||
        _questionsItems.isNotEmpty) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text("Discard Changes"),
          content: const Text("Are you sure you want to discard changes?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimaryColor
        : AppTheme.textPrimaryColor;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Quiz"),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _updateQuiz,
              icon: const Icon(Icons.save),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "Quiz Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Quiz Title",
                  hintText: "Enter quiz title",
                  prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Please enter quiz title" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeLimitController,
                decoration: const InputDecoration(
                  labelText: "Time Limit (in minutes)",
                  hintText: "Enter time limit",
                  prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter time limit";
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return "Please enter a valid time limit";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Questions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    label: const Text("Add Question"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._questionsItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Question ${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (_questionsItems.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _removeQuestion(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: item.questionController,
                          decoration: const InputDecoration(
                            labelText: "Question",
                            hintText: "Enter question",
                            prefixIcon: Icon(Icons.question_answer,
                                color: AppTheme.primaryColor),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? "Please enter question"
                              : null,
                        ),
                        const SizedBox(height: 16),
                        ...item.optionsControllers.asMap().entries.map((opt) {
                          final optionIndex = opt.key;
                          final controller = opt.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: optionIndex,
                                  groupValue: item.correctOptionIndex,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    setState(() {
                                      item.correctOptionIndex = val!;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: "Option ${optionIndex + 1}",
                                      hintText: "Enter option",
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? "Please enter option"
                                        : null,
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
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateQuiz,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
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
        ),
      ),
    );
  }
}
