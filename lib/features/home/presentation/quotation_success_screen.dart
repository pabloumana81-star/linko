import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/widgets/quotation_success_content.dart';

class QuotationSuccessScreen extends StatelessWidget {
  const QuotationSuccessScreen({
    required this.customerName,
    required this.onViewRequests,
    required this.onBackHome,
    super.key,
  });
  final String customerName;
  final VoidCallback onViewRequests;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: QuotationSuccessContent(
          customerName: customerName,
          onViewRequests: onViewRequests,
          onBackHome: onBackHome,
        ),
      ),
    );
  }
}
