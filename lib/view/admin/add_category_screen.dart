import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/model/category.dart';
import 'package:quiz_app/theme/theme.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? category;
  const AddCategoryScreen({super.key, this.category});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>(); // Thêm _formKey tương tác với form
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _descriptionController = TextEditingController(
      text: widget.category?.description,
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      if (widget.category != null) {
        final updatedCategory = widget.category!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        await _firestore
            .collection("categories")
            .doc(widget.category!.id)
            .update(updatedCategory.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Category updated successfully")),
        );
      } else {
        await _firestore
            .collection("categories")
            .add(
              Category(
                id: _firestore.collection("categories").doc().id,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                createdAt: DateTime.now(),
              ).toMap(),
            );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Category added successfully")));
      }
      Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
    }
    finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<bool> _onWillPop() async {
    if(_nameController.text.isNotEmpty || _descriptionController.text.isNotEmpty){
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Discard Changes"),
          content: Text("Are you sure you want to discard changes?"),
          actions: [
            TextButton(
                onPressed: (){
                  Navigator.pop(context, false);
                },
                child: Text("Cancel"),
            ),
            TextButton(
              onPressed: (){
                Navigator.pop(context, true);
              },
              child: Text(
                  "Discard",
                  style: TextStyle(
                      color: Colors.redAccent,
                  ),
              ),
            ),
          ],
        )
      ) ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
        child: Scaffold(
            appBar: AppBar(
                backgroundColor: AppTheme.backgroundColor
            ),
        ),
    );
  }
}
