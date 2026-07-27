import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/widgets/request_success_content.dart';

class RequestSuccessScreen extends StatelessWidget {
  const RequestSuccessScreen({
    required this.professionalName,
    required this.onViewRequests,
    required this.onBackHome,
    super.key,
  });

  final String professionalName;
  final VoidCallback onViewRequests;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: RequestSuccessContent(
              professionalName: professionalName,
              onViewRequests: onViewRequests,
              onBackHome: onBackHome,
            ),
          ),
        ),
      ),
    );
  }
}
