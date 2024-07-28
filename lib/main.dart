import 'package:flutter/material.dart';
import 'Form/ai.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AiChatPage(), // Langsung navigasi ke halaman utama
    );
  }
}
