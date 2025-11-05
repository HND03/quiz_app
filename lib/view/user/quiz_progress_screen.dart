import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuizProgressScreen extends StatefulWidget {
  const QuizProgressScreen({super.key});

  @override
  State<QuizProgressScreen> createState() => _QuizProgressScreenState();
}

class _QuizProgressScreenState extends State<QuizProgressScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<Map<String, List<Map<String, dynamic>>>> _fetchUserResults() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quizResults')
        .where('userId', isEqualTo: user?.uid)
        .orderBy('completedAt', descending: true)
        .get();

    // Gom nhóm theo quizId
    final Map<String, List<Map<String, dynamic>>> groupedResults = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final quizId = data['quizId'] ?? 'unknown';
      groupedResults.putIfAbsent(quizId, () => []);
      groupedResults[quizId]!.add(data);
    }

    print("Fetching results for userId: ${user?.uid}");
    print("Total docs found: ${snapshot.docs.length}");
    for (var doc in snapshot.docs) {
      print(doc.data());
    }
    return groupedResults;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Progress"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _fetchUserResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No quiz results yet."));
          }

          final results = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: results.entries.map((entry) {
              final quizId = entry.key;
              final quizAttempts = entry.value;
              final quizTitle = quizAttempts.first['quizTitle'] ?? "Untitled Quiz";

              // Dữ liệu biểu đồ (điểm theo thứ tự thời gian)
              final List<FlSpot> scoreSpots = quizAttempts.asMap().entries.map((e) {
                final i = quizAttempts.length - e.key; // đảo thứ tự để mới nhất lên đầu
                final scorePercentage = (e.value['scorePercentage'] ?? 0).toDouble();
                return FlSpot(i.toDouble(), scorePercentage);
              }).toList().reversed.toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quizTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt() - 1;
                                    if (index >= 0 && index < quizAttempts.length) {
                                      final date = (quizAttempts[index]['completedAt'] as Timestamp).toDate();
                                      return Text(DateFormat('d/MM').format(date),
                                          style: const TextStyle(fontSize: 10));
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}%',
                                        style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                            ),
                            minY: 0,
                            maxY: 100,
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                color: Colors.blueAccent,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: false),
                                spots: scoreSpots,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Lần gần nhất: ${DateFormat('dd/MM/yyyy – HH:mm').format((quizAttempts.first['completedAt'] as Timestamp).toDate())}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
