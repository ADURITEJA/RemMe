import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIWordGameScreen extends StatefulWidget {
  final List<String> memoryTexts; // List of memory texts from the database

  const AIWordGameScreen({super.key, required this.memoryTexts});

  @override
  _AIWordGameScreenState createState() => _AIWordGameScreenState();
}

class _AIWordGameScreenState extends State<AIWordGameScreen> {
  final String apiKey =
      "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"; // Replace with actual Groq API Key
  final String endpoint = "https://api.groq.com";
  final String model = "llama-3.3-70b-versatile"; // AI model name

  String currentWord = "";
  String hint = "Fetching hint...";
  int score = 0;
  int timeLeft = 30;
  bool gameOver = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateAIWord(widget.memoryTexts.join(" "));
  }

  Future<void> _generateAIWord(String memoryText) async {
    setState(() {
      isLoading = true;
      hint = "Analyzing memory...";
    });

    try {
      final response = await http.post(
        Uri.parse("$endpoint/openai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": model,
          "messages": [
            {
              "role": "system",
              "content":
                  "You are an AI that extracts important words from a memory text and provides a related hint.",
            },
            {
              "role": "user",
              "content":
                  "Analyze the following memory text and generate a word along with a hint.\nMemory: $memoryText\nFormat: Word - Hint",
            },
          ],
          "max_tokens": 50,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String aiResponse =
            data['choices'][0]['message']['content'] ?? "Unknown - No Hint";

        List<String> parts = aiResponse.split(" - ");
        setState(() {
          currentWord = parts[0].trim();
          hint = parts.length > 1 ? parts[1].trim() : "Guess the word!";
          isLoading = false;
        });
      } else {
        throw Exception("Failed to get AI response: ${response.body}");
      }
    } catch (e) {
      setState(() {
        hint = "Error: ${e.toString()}";
        currentWord = "Error";
        isLoading = false;
      });
    }
  }

  void _checkAnswer(String input) {
    if (input.toLowerCase() == currentWord.toLowerCase()) {
      setState(() {
        score += 10;
        timeLeft += 5;
        _generateAIWord(widget.memoryTexts.join(" "));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Word Game")),
      body:
          gameOver
              ? Center(
                child: Text(
                  "Game Over! Your Score: $score",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Time Left: $timeLeft s",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                          children: [
                            Text(
                              "Hint: $hint",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              decoration: const InputDecoration(
                                labelText: "Enter the word",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: _checkAnswer,
                            ),
                          ],
                        ),
                    const SizedBox(height: 20),
                    Text(
                      "Score: $score",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Memories:",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: widget.memoryTexts.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(
                                      widget.memoryTexts[index],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
