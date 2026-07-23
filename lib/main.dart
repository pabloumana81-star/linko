import 'package:flutter/material.dart';

void main() {
  runApp(const LinkoApp());
}

class LinkoApp extends StatelessWidget {
  const LinkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linko',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake_rounded, size: 90, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'LINKO',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Connecting trusted professionals\nwith people who need them.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
