import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'manage_categories_screen.dart';
import 'manage_quizes_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _statsData;

  Future<void> _refreshData() async {
    try {
      final data = await _fetchStatistics();
      if (mounted) {
        setState(() {
          _statsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to refresh data: $e")));
      }
    }
  }

  Future<Map<String, dynamic>> _fetchStatistics() async {
    final categoriesCount = await _firestore.collection('categories').count().get();
    final quizzesCount = await _firestore.collection('quizzes').count().get();
    final latestQuizzes = await _firestore
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    final categories = await _firestore.collection('categories').get();
    final categoryData = await Future.wait(
      categories.docs.map((category) async {
        final quizCount = await _firestore
            .collection('quizzes')
            .where('categoryId', isEqualTo: category.id)
            .count()
            .get();
        return {
          'name': category.data()['name'] as String,
          'count': quizCount.count,
        };
      }),
    );

    return {
      'totalCategories': categoriesCount.count,
      'totalQuizzes': quizzesCount.count,
      'latestQuizzes': latestQuizzes.docs,
      'categoryData': categoryData,
    };
  }

  String _formatDateTime(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7);
    final cardColor = Theme.of(context).cardColor;

    return Card(
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Card(
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7);
    final cardColor = Theme.of(context).cardColor;

    if (_statsData == null) {
      return const Center(child: Text('No data available. Pull down to refresh.'));
    }

    final stats = _statsData!;
    final categoryData = stats['categoryData'] as List<dynamic>;
    final latestQuizzes = stats['latestQuizzes'] as List<QueryDocumentSnapshot>;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome User',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 8),
            Text("Here's your quiz application overview",
                style: TextStyle(fontSize: 16, color: textSecondary)),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Total Categories',
                        stats['totalCategories'].toString(),
                        Icons.category_rounded,
                        AppTheme.primaryColor,
                        context)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                        'Total Quizzes',
                        stats['totalQuizzes'].toString(),
                        Icons.quiz_rounded,
                        AppTheme.secondaryColor,
                        context)),
              ],
            ),
            const SizedBox(height: 24),

            // Category Statistics
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.pie_chart_rounded,
                          color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Text('Category Statistics',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary)),
                    ]),
                    const SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categoryData.length,
                      itemBuilder: (context, index) {
                        final category = categoryData[index];
                        final totalQuizzes = categoryData.fold<int>(
                            0, (sum, item) => sum + (item['count'] as int));
                        final percentage = totalQuizzes > 0
                            ? (category['count'] as int) / totalQuizzes * 100
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(category['name'] as String,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary)),
                                    const SizedBox(height: 5),
                                    Text(
                                        "${category['count']} ${(category['count'] == 1 ? 'quiz' : 'quizzes')}",
                                        style: TextStyle(
                                            fontSize: 14, color: textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.history_rounded,
                          color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Text('Recent Activity',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary)),
                    ]),
                    const SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: latestQuizzes.length,
                      itemBuilder: (context, index) {
                        final quiz =
                        latestQuizzes[index].data() as Map<String, dynamic>;
                        final title = quiz['title'] ?? 'No Title';
                        final Timestamp? timestamp =
                        quiz['createdAt'] as Timestamp?;
                        final createdAt =
                            timestamp?.toDate() ?? DateTime.now();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.quiz_rounded,
                                  color: AppTheme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Created on: ${_formatDateTime(createdAt)}',
                                        style: TextStyle(
                                            color: textSecondary, fontSize: 12)),
                                  ]),
                            ),
                          ]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quiz Actions
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.speed_rounded,
                          color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Text('Quiz Actions',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary)),
                    ]),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                      children: [
                        _buildDashboardCard(
                            context, 'Quizzes', Icons.quiz_rounded, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ManageQuizesScreen()));
                        }),
                        _buildDashboardCard(
                            context, 'Categories', Icons.category_rounded, () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ManageCategoriesScreen()));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Quiz Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryColor,
        child: _buildContent(context),
      ),
    );
  }
}
