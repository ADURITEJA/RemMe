import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // Ensure this is explicitly imported
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart' as p;
import 'dart:io';
import 'package:path/path.dart' as path; // Alias to avoid conflicts

class SpeechRecognitionPage extends StatefulWidget {
  @override
  _SpeechRecognitionPageState createState() => _SpeechRecognitionPageState();
}

class _SpeechRecognitionPageState extends State<SpeechRecognitionPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "Tap the button and start speaking...";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    _speech.stop();
  }

  Future<void> _saveMemory() async {
    if (_recognizedText.isNotEmpty &&
        _recognizedText != "Tap the button and start speaking...") {
      await insertMemory(_recognizedText);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Memory saved successfully!")),
      );
    }
  }

  Future<void> insertMemory(String memoryText) async {
    final Database db = await openDatabase(
      path.join(await getDatabasesPath(), 'memory.db'), // Use alias 'path'
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE memories(id INTEGER PRIMARY KEY, text TEXT, timestamp TEXT)",
        );
      },
      version: 1,
    );

    await db.insert('memories', {
      'text': memoryText,
      'timestamp': DateTime.now().toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Speak Your Memory"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _recognizedText,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? "Stop Listening" : "Start Speaking"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _saveMemory, child: const Text("Save Memory")),
          ],
        ),
      ),
    );
  }
}