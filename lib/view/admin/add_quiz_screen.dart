import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/model/category.dart';
import 'package:quiz_app/model/question.dart';
import 'package:quiz_app/model/quiz.dart';
import 'package:quiz_app/theme/theme.dart';

class AddQuizScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  const AddQuizScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
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
    for (var controller in optionsControllers) {
      controller.dispose();
    }
  }
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  bool _isLoading = false;
  String? _selectedCategoryId;
  String? _displayCategoryName;
  List<QuestionFromItem> _questionsItems = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _displayCategoryName = widget.categoryName;
    if (widget.categoryId != null && widget.categoryName == null) {
      _loadCategoryName(widget.categoryId!);
    }
    _addQuestion();
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

  Future<void> _loadCategoryName(String categoryId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String?;
        if (mounted) {
          setState(() {
            _displayCategoryName = name ?? 'Selected Category';
            // ensure _selectedCategoryId is set
            _selectedCategoryId = categoryId;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _displayCategoryName = widget.categoryName ?? 'Selected Category';
            _selectedCategoryId = categoryId;
          });
        }
      }
    } catch (e) {
      // ignore errors but set safe defaults
      if (mounted) {
        setState(() {
          _displayCategoryName = widget.categoryName ?? 'Selected Category';
          _selectedCategoryId = categoryId;
        });
      }
    }
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
    setState(() {
      _questionsItems[index].dispose();
      _questionsItems.removeAt(index);
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final questions = _questionsItems
          .map(
            (item) => Question(
          text: item.questionController.text.trim(),
          options: item.optionsControllers.map((e) => e.text.trim()).toList(),
          correctOptionIndex: item.correctOptionIndex,
        ),
      )
          .toList();

      final quizId = _firestore.collection("quizzes").doc().id;

      await _firestore.collection("quizzes").doc(quizId).set(
        Quiz(
          id: quizId,
          title: _titleController.text.trim(),
          categoryId: _selectedCategoryId!,
          timeLimit: int.parse(_timeLimitController.text),
          questions: questions,
          createdBy: FirebaseAuth.instance.currentUser!.uid,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add quiz: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty ||
        _selectedCategoryId != null ||
        _timeLimitController.text.isNotEmpty ||
        _questionsItems.isNotEmpty) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            "Discard Changes",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            "Are you sure you want to discard changes?",
            style:
            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
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
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.categoryName != null
                ? "Add ${widget.categoryName} Quiz"
                : "Add Quiz",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _saveQuiz,
              icon: Icon(Icons.save, color: theme.primaryColor),
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 20),
              // Nếu categoryId đã được truyền -> hiển thị category cố định (không chọn lại)
              if (widget.categoryId != null)
                TextFormField(
                  enabled: false,
                  initialValue: _displayCategoryName ?? widget.categoryName ?? "Selected Category",
                  decoration: const InputDecoration(
                    labelText: "Category",
                    prefixIcon: Icon(Icons.category, color: AppTheme.primaryColor),
                  ),
                )
              else
              // dropdown bình thường (giữ nguyên code hiện tại)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection("categories").orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Text("Error loading categories");
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }

                    final categories = snapshot.data!.docs
                        .map((doc) => Category.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                        .toList();

                    return DropdownButtonFormField<String>(
                      value: categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        hintText: "Select category",
                        prefixIcon: Icon(Icons.category, color: AppTheme.primaryColor),
                      ),
                      items: categories
                          .map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategoryId = value);
                      },
                      validator: (value) => value == null || value.isEmpty ? "Please select a category" : null,
                    );
                  },
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
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Question"),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            if (_questionsItems.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
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
                            prefixIcon: Icon(Icons.help_outline,
                                color: AppTheme.primaryColor),
                          ),
                          validator: (value) =>
                          value == null || value.isEmpty ? "Please enter question" : null,
                        ),
                        const SizedBox(height: 16),
                        ...item.optionsControllers.asMap().entries.map((entry) {
                          final optionIndex = entry.key;
                          final controller = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                                      labelText: "Option ${optionIndex + 1}",
                                      hintText: "Enter Option",
                                    ),
                                    validator: (value) => value == null || value.isEmpty
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
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveQuiz,
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
                      "Save Quiz",
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
