import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/model/quiz.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:quiz_app/model/category.dart';
import 'package:quiz_app/view/admin/edit_quiz_screen.dart';

import 'add_quiz_screen.dart';

class ManageQuizesScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  const ManageQuizesScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<ManageQuizesScreen> createState() => _ManageQuizesScreenState();
}

class _ManageQuizesScreenState extends State<ManageQuizesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategoryId;
  List<Category> _categories = [];
  Category? _initialCategory;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final querySnapshot = await _firestore.collection('categories').get();
      final categories = querySnapshot.docs
          .map((doc) => Category.fromMap(doc.id, doc.data()))
          .toList();

      setState(() {
        _categories = categories;
        if (widget.categoryId != null) {
          _initialCategory = _categories.firstWhere(
            (category) => category.id == widget.categoryId,
            orElse: () => Category(
              id: widget.categoryId!,
              name: "Unknown Category",
              description: '',
            ),
          );
          _selectedCategoryId = _initialCategory!.id;
        }
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Stream<QuerySnapshot> _getQuizStream() {
    Query query = _firestore.collection('quizzes');
    String? filterCategoryId = _selectedCategoryId ?? widget.categoryId;
    if (_selectedCategoryId != null) {
      query = query.where('categoryId', isEqualTo: filterCategoryId);
    }
    return query.snapshots();
  }

  Widget _buildTitle(BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color;

    String? categoryId = _selectedCategoryId ?? widget.categoryId;
    if (categoryId == null) {
      return Text(
        "All Quizzes",
        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
      );
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('categories').doc(categoryId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            "Loading....",
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            "Unknown Category",
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          );
        }
        final category = Category.fromMap(
          categoryId,
          snapshot.data!.data() as Map<String, dynamic>,
        );
        return Text(
          category.name,
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color;
    final textSecondary = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);
    final cardColor = theme.cardColor;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardColor,
        title: _buildTitle(context),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddQuizScreen(
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: false,
                fillColor: cardColor,
                hintText: "Search Quizzes",
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search, color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: false,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: "Category",
                hintStyle: TextStyle(color: textSecondary),
              ),
              value: _selectedCategoryId,
              items: [
                const DropdownMenuItem(
                  child: Text("All Categories"),
                  value: null,
                ),
                if (_initialCategory != null &&
                    _categories.every((c) => c.id != _initialCategory!.id))
                  DropdownMenuItem(
                    child: Text(_initialCategory!.name),
                    value: _initialCategory!.id,
                  ),
                ..._categories.map(
                  (category) => DropdownMenuItem(
                    child: Text(category.name),
                    value: category.id,
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getQuizStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(
                    child: Text("Error", style: TextStyle(color: textPrimary)),
                  );
                if (!snapshot.hasData)
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );

                final quizzes = snapshot.data!.docs
                    .map(
                      (doc) => Quiz.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .where(
                      (quiz) =>
                          _searchQuery.isEmpty ||
                          quiz.title.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

                if (quizzes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No quizzes yet",
                          style: TextStyle(color: textSecondary, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddQuizScreen(
                                  categoryId: widget.categoryId,
                                  categoryName: widget.categoryName,
                                ),
                              ),
                            );
                          },
                          child: const Text("Add Quiz"),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final Quiz quiz = quizzes[index];
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.quiz_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          quiz.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.question_answer_outlined,
                                  size: 16,
                                  color: textSecondary,
                                ),
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
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: textSecondary,
                                ),
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
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "edit",
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.edit,
                                  color: AppTheme.primaryColor,
                                ),
                                title: const Text("Edit"),
                              ),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                title: const Text("Delete"),
                              ),
                            ),
                          ],
                          onSelected: (value) =>
                              _handleQuizAction(context, value, quiz),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuizAction(
    BuildContext context,
    String value,
    Quiz quiz,
  ) async {
    if (value == "edit") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditQuizScreen(quiz: quiz)),
      );
    } else if (value == "delete") {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Quiz"),
          content: const Text("Are you sure you want to delete this quiz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _firestore.collection('quizzes').doc(quiz.id).delete();
      }
    }
  }
}
