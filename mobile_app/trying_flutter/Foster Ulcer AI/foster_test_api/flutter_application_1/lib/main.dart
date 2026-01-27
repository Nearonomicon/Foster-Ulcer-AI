import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEST_API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const ApiTestScreen(),
    );
  }
}

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String result = "Tap a button to test API";

  // Android Emulator → use this instead of localhost
  final String baseUrl = "http://10.0.2.2:8000";

  Future<void> callHealth() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/health"));
      setState(() => result = response.body);
    } catch (e) {
      setState(() => result = "ERROR: $e");
    }
  }

  Future<void> callPing() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/ping"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": "hello from Flutter TEST_API"}),
      );
      setState(() => result = response.body);
    } catch (e) {
      setState(() => result = "ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter → FastAPI Test"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: callHealth,
              child: const Text("GET /health"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: callPing,
              child: const Text("POST /ping"),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(result),
            ),
          ],
        ),
      ),
    );
  }
}
