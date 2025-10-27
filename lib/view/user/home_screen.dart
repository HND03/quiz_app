import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quiz_app/model/category.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:quiz_app/view/user/profile_screen.dart';
import '../admin/admin_home_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final TextEditingController _searchController = TextEditingController();

  String? _photoUrl;
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
    _loadUserPhoto();
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
      if (mounted) {
        setState(() {
          _allCategories = snapshot.docs
              .map((doc) => Category.fromMap(doc.id, doc.data()))
              .toList();
          _categoryFilters =
              ['All'] +
              _allCategories.map((category) => category.name).toSet().toList();
          _filteredCategories = _allCategories;
          // ADD THIS LINE TO RESET THE FILTER TO INITIAL
          _selectedFilter = 'All';
          // reset the entire search box
          _searchController.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading =
              false; // Download complete (success or failure), reset to false
        });
      }
    }
  }

  Future<void> _loadUserPhoto() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      _photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    });
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

  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadUser(); //reload user
  }

  Future<void> _reloadUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
    isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final textPrimary =
    isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final textSecondary =
    isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;
    final cardColor = isDark ? AppTheme.darkCardColor : AppTheme.cardColor;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminHomeScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Quiz Manager',
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
                  // Call the fetch function again to refresh the data
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
                  padding: const EdgeInsets.only(right: 20, top: 4),
                  child: GestureDetector(
                    onTap: () {
                      // ✅ Get new avatar value when returning
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            onThemeChanged: widget.onThemeChanged ?? (mode) {},
                          ),
                        ),
                      ).then((newPhotoUrl) async {
                        if (newPhotoUrl != null && newPhotoUrl is String) {
                          setState(() {
                            _photoUrl = newPhotoUrl;
                          });
                        } else {
                          await _loadUserPhoto();
                        }
                      });
                    },
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(
                              '$_photoUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                            )
                          : const AssetImage("assets/images/default_avatar.png")
                                as ImageProvider,
                      child: _photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: AppTheme.primaryColor,
                              size: 26,
                            )
                          : null,
                    ),
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
                                borderRadius: BorderRadius.circular(16),
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
                                  hintStyle: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : AppTheme.textSecondaryColor),
                                  prefixIcon: Icon(Icons.search,
                                      color: AppTheme.primaryColor),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            _filterCategories('');
                                          },
                                    icon: const Icon(Icons.clear),
                                    color: AppTheme.primaryColor,
                                        )
                                      : null,
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(color: textPrimary),
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
                                : textPrimary,
                          ),
                        ),
                        selected: _selectedFilter == filter,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: cardColor,
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
              padding: const EdgeInsets.all(16),
              sliver: _isLoading && _filteredCategories.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50.0),
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
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  : SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCategoryCard(
                    _filteredCategories[index],
                    index,
                    isDark,
                    textPrimary,
                  ),
                  childCount: _filteredCategories.length,
                ),
                gridDelegate: const  SliverGridDelegateWithFixedCrossAxisCount(
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

  Widget _buildCategoryCard(
      Category category, int index, bool isDark, Color textPrimary) {
    final cardColor = isDark ? AppTheme.darkCardColor : AppTheme.cardColor;
    return Card(
      elevation: 0,
      color: cardColor,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              Text(
                category.description,
                style: TextStyle(
                  fontSize: 10,
                  color: textPrimary.withOpacity(0.8),
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
        .slideY(begin: 0.5, end: 0, duration: const Duration(milliseconds: 300))
        .fadeIn();
  }
}
