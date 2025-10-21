import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_app/model/category.dart';
import 'package:quiz_app/theme/theme.dart';
import '../admin/admin_home_screen.dart';
import 'category_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];

  List<String> _categoryFilters = ['All'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .get();
      // Kiểm tra xem widget có còn trên cây widget không trước khi gọi setState
      if (mounted) {
        setState(() {
          _allCategories = snapshot.docs
              .map((doc) => Category.fromMap(doc.id, doc.data()))
              .toList();
          _categoryFilters =
              ['All'] +
              _allCategories.map((category) => category.name).toSet().toList();
          _filteredCategories = _allCategories;
          // THÊM DÒNG NÀY ĐỂ ĐƯA BỘ LỌC VỀ BAN ĐẦU
          _selectedFilter = 'All';
          // Cũng nên reset cả ô tìm kiếm
          _searchController.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading =
              false; // Tải xong (thành công hoặc thất bại), đặt lại thành false
        });
      }
    }
  }

  void _filterCategories(String query, {String? categoryFilter}) {
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        final matchesSearch =
            category.name.toLowerCase().contains(query.toLowerCase()) ||
            category.description.toLowerCase().contains(query.toLowerCase());
        final matchesCategory =
            categoryFilter == null ||
            categoryFilter == 'All' ||
            category.name.toLowerCase() == categoryFilter.toLowerCase();

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Điều hướng đến màn hình AdminHomeScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor, // Sử dụng màu chủ đạo
        child: Icon(
          Icons.add, // Hoặc bạn có thể dùng Icons.add hoặc Icons.settings
          color: Colors.white,
        ),
        tooltip: 'Quiz Manager', // Gợi ý nhỏ khi người dùng nhấn giữ nút
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchCategories,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              floating: true,
              centerTitle: false,
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  // Gọi lại hàm fetch để làm mới dữ liệu
                  _refreshIndicatorKey.currentState?.show();
                },
                child: Text(
                  "Quiz App",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0, top: 11.0),
                  child: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged out successfully'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logout failed: $e')),
                            );
                          }
                        }
                      }
                    },
                    icon: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.account_circle, color: AppTheme.primaryColor),
                            SizedBox(width: 10),
                            Text('Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Column(
                    children: [
                      SizedBox(height: kToolbarHeight + 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, Learner",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Let's test your knowledge today!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => _filterCategories(value),
                                decoration: InputDecoration(
                                  hintText: "Search categories...",
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppTheme.primaryColor,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            _filterCategories('');
                                          },
                                          icon: Icon(Icons.clear),
                                          color: AppTheme.primaryColor,
                                        )
                                      : null,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                collapseMode: CollapseMode.pin,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(16),
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categoryFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _categoryFilters[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            color: _selectedFilter == filter
                                ? Colors.white
                                : AppTheme.textPrimaryColor,
                          ),
                        ),
                        selected: _selectedFilter == filter,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Colors.white,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedFilter = filter;
                            _filterCategories(
                              _searchController.text,
                              categoryFilter: filter,
                            );
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: _isLoading && _filteredCategories.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 50.0,
                          ), // Đẩy vòng xoay xuống
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    )
                  : _filteredCategories.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          "No Categories found",
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    )
                  : SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCategoryCard(
                          _filteredCategories[index],
                          index,
                        ),
                        childCount: _filteredCategories.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: category),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.quiz,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                  ),
                  SizedBox(height: 12),
                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .slideY(begin: 0.5, end: 0, duration: Duration(milliseconds: 300))
        .fadeIn();
  }
}
