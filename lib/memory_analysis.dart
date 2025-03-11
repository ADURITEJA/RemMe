import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class MemoryAnalysisPage extends StatefulWidget {
  @override
  _MemoryAnalysisPageState createState() => _MemoryAnalysisPageState();
}

class _MemoryAnalysisPageState extends State<MemoryAnalysisPage> {
  List<MemoryData> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadMemoryData();
  }

  Future<void> _loadMemoryData() async {
    try {
      List<String> memories = await fetchMemories();
      List<MemoryData> analyzedData = await analyzeMemoryData(memories);

      if (analyzedData.isNotEmpty) {
        setState(() {
          _chartData = analyzedData;
        });
      } else {
        print("⚠️ No valid memory data to display.");
      }
    } catch (e) {
      print("Error loading memory data: $e");
    }
  }

  Future<List<String>> fetchMemories() async {
    try {
      final Database db = await openDatabase(
        join(await getDatabasesPath(), 'memory.db'),
      );
      final List<Map<String, dynamic>> maps = await db.query('memories');

      return maps.map((map) => map['text'] as String).toList();
    } catch (e) {
      print("Error fetching memories: $e");
      return [];
    }
  }

  Future<List<MemoryData>> analyzeMemoryData(List<String> memories) async {
    double strong = 0, moderate = 0, weak = 0, forgotten = 0;

    for (var memory in memories) {
      List<String> keywords = await extractKeywordsUsingMLKit(memory);
      print("🔹 Extracted Keywords for '$memory': $keywords");

      int keywordCount = keywords.length;
      if (keywordCount > 3) {
        strong++;
      } else if (keywordCount == 3) {
        moderate++;
      } else if (keywordCount == 2) {
        weak++;
      } else {
        forgotten++;
      }
    }

    double total = strong + moderate + weak + forgotten;
    if (total == 0) {
      print("⚠️ No valid memory recall data found! Assigning default values.");
      return [
        MemoryData('Strongly Remembered', 25, Colors.green),
        MemoryData('Moderately Remembered', 25, Colors.blue),
        MemoryData('Weakly Remembered', 25, Colors.orange),
        MemoryData('Forgotten', 25, Colors.red),
      ];
    }

    return [
      MemoryData(
        'Strongly Remembered',
        ((strong / total) * 100).clamp(1, 100),
        Colors.green,
      ),
      MemoryData(
        'Moderately Remembered',
        ((moderate / total) * 100).clamp(1, 100),
        Colors.blue,
      ),
      MemoryData(
        'Weakly Remembered',
        ((weak / total) * 100).clamp(1, 100),
        Colors.orange,
      ),
      MemoryData(
        'Forgotten',
        ((forgotten / total) * 100).clamp(1, 100),
        Colors.red,
      ),
    ];
  }

  /// **ML Kit-Based Keyword Extraction (Fixed Version)**
  Future<List<String>> extractKeywordsUsingMLKit(String text) async {
    final entityExtractor = EntityExtractor(
      language: EntityExtractorLanguage.english,
    );
    final extractedEntities = await entityExtractor.annotateText(text);

    List<String> keywords =
        extractedEntities
            .expand(
              (e) => e.entities.map((entity) => entity.type.toString()),
            ) // ✅ Corrected
            .toList();

    await entityExtractor.close(); // Free up resources
    return keywords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Memory Analysis"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "AI-Based Memory Recall Analysis",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              padding: const EdgeInsets.all(10),
              child:
                  _chartData.isNotEmpty
                      ? SfCircularChart(
                        title: ChartTitle(text: "Memory Recall Percentage"),
                        legend: const Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                        ),
                        series: <DoughnutSeries<MemoryData, String>>[
                          DoughnutSeries<MemoryData, String>(
                            dataSource: _chartData,
                            pointColorMapper:
                                (MemoryData data, _) => data.color,
                            xValueMapper: (MemoryData data, _) => data.category,
                            yValueMapper:
                                (MemoryData data, _) => data.percentage,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
                          ),
                        ],
                      )
                      : const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryData {
  final String category;
  final double percentage;
  final Color color;

  MemoryData(this.category, this.percentage, this.color);
}
