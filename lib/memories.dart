import 'package:flutter/material.dart';
import 'dart:io';

class MemoriesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> memories;

  const MemoriesScreen({super.key, required this.memories});

  @override
  _MemoriesScreenState createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("Memories"),
        backgroundColor: Colors.pink[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: widget.memories.isEmpty
            ? const Center(
                child: Text(
                  "No memories added yet!",
                  style: TextStyle(fontSize: 18),
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: widget.memories.length,
                itemBuilder: (context, index) {
                  final memory = widget.memories[index];
                  String? imagePath = memory['imagePath']; // Ensure correct key is used

                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync()
                            ? Image.file(
                                File(imagePath),
                                height: 130,
                                width: 130,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 130,
                                width: 130,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        memory['text'] ?? 'No description',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}