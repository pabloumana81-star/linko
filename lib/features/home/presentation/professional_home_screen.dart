import 'package:flutter/material.dart';

class ProfessionalHomeScreen extends StatelessWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: true),
      body: const SafeArea(child: Center(child: Text('Panel del profesional'))),
    );
  }
}
