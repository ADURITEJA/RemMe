import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_word_game.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool isRecording = false;
  File? _selectedImage;
  String recordedText = "";
  List<String> previousMemories = [];
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    _loadPreviousMemories();
  }

  Future<void> _loadPreviousMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedMemories = prefs.getStringList('memories');
    if (storedMemories != null) {
      setState(() {
        previousMemories = storedMemories;
      });
    }
  }

  Future<void> _saveMemoryText() async {
    if (recordedText.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      previousMemories.add(recordedText);
      await prefs.setStringList('memories', previousMemories);
    }
  }

  Future<String> _saveImagePermanently(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final String newPath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File newImage = await imageFile.copy(newPath);
    return newImage.path;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      String savedPath = await _saveImagePermanently(File(pickedFile.path));
      setState(() {
        _selectedImage = File(savedPath);
      });
    }
  }

  void _toggleRecording() async {
    if (!isRecording) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => isRecording = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              recordedText = result.recognizedWords;
            });
          },
        );
      }
    } else {
      _speech.stop();
      setState(() => isRecording = false);
    }
  }

  void _saveMemory() {
    if (_selectedImage != null && recordedText.isNotEmpty) {
      _saveMemoryText();
      Navigator.pop(context, {
        'imagePath': _selectedImage!.path,
        'text': recordedText,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image and record text!"),
        ),
      );
    }
  }

  void _openAIWordGame() {
    if (previousMemories.isNotEmpty || recordedText.isNotEmpty) {
      List<String> allTexts = List.from(previousMemories);
      if (recordedText.isNotEmpty) {
        allTexts.add(recordedText);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIWordGameScreen(memoryTexts: allTexts),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No memory texts available! Please record something."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("Record Memory"),
        backgroundColor: Colors.pink[100],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Press Microphone to start",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          GestureDetector(
            onTap: _pickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child:
                  _selectedImage != null
                      ? Image.file(
                        _selectedImage!,
                        height: 150,
                        width: 250,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        height: 150,
                        width: 250,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.black54,
                        ),
                      ),
            ),
          ),

          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              recordedText.isNotEmpty
                  ? recordedText
                  : "Your recorded text will appear here...",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: _toggleRecording,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: isRecording ? Colors.red[200] : Colors.black,
                  child: const Icon(Icons.mic, size: 30, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: _saveMemory,
                child: const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.check, size: 30, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(thickness: 1, color: Colors.black),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: _openAIWordGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Play AI Word Game",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
