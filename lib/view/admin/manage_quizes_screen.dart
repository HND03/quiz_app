import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/theme/theme.dart';

import 'package:quiz_app/model/category.dart';



class ManageQuizesScreen extends StatefulWidget {
  final String? categoryId;
  const ManageQuizesScreen({super.key, this.categoryId});

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
    // TODO: implement initState
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try{
      final querySnapshot = await _firestore.collection('categories').get();
      final categories = querySnapshot.docs.map((doc) => Category.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    }catch(e){
      print("Error fetching categories: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}
