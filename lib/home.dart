import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'memories.dart';
import 'record.dart';
import 'ai_word_game.dart';
import 'speech_recognition.dart';
import 'memory_analysis.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> memories = [];

  @override
  void initState() {
    super.initState();
    _loadMemories(); // Load memories on app start
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedMemories = prefs.getStringList('memories');

    if (storedMemories != null) {
      setState(() {
        memories =
            storedMemories
                .map((mem) => jsonDecode(mem) as Map<String, dynamic>)
                .toList();
      });
    }
  }

  Future<void> _saveMemories() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> memoryData = memories.map((mem) => jsonEncode(mem)).toList();
    await prefs.setStringList('memories', memoryData);
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecordScreen()),
      );

      if (result != null) {
        setState(() {
          memories.add(result);
        });
        _saveMemories(); // Save updated memories
      }
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RemMe")),
      body:
          _selectedIndex == 0
              ? Column(
                children: [
                  Expanded(child: MemoriesScreen(memories: memories)),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpeechRecognitionPage(),
                              ),
                            );
                          },
                          child: const Text("Speak Memory"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemoryAnalysisPage(),
                              ),
                            );
                          },
                          child: const Text("Memory Analysis"),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : RecordScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Memories'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Record'),
        ],
      ),
    );
  }
}
