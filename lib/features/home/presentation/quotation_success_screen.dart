import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/widgets/quotation_success_content.dart';

class QuotationSuccessScreen extends StatelessWidget {
  const QuotationSuccessScreen({required this.onViewRequests, super.key});
  final VoidCallback onViewRequests;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: QuotationSuccessContent(onViewRequests: onViewRequests),
      ),
    );
  }
}
