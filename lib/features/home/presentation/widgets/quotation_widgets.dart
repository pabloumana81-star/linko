import 'package:flutter/material.dart';
import 'package:linko/core/utils/currency_formatter.dart';
import 'package:linko/features/home/presentation/models/incoming_service_request.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';

class QuotationRequestSummary extends StatelessWidget {
  const QuotationRequestSummary({required this.request, super.key});
  final IncomingServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.customerName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          request.serviceCategory,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(request.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _Metadata(
              icon: Icons.location_on_outlined,
              text: 'Ubicación: ${request.location}',
            ),
            _Metadata(
              icon: Icons.schedule_outlined,
              text: 'Disponibilidad: ${request.timing.label}',
            ),
          ],
        ),
      ],
    );
  }
}

class CurrencyInputField extends StatelessWidget {
  const CurrencyInputField({
    required this.label,
    required this.controller,
    required this.validator,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: const [DigitsOnlyInputFormatter()],
      decoration: InputDecoration(labelText: label, prefixText: '₡ '),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class QuotationCostSummary extends StatelessWidget {
  const QuotationCostSummary({
    required this.labor,
    required this.materials,
    this.totalLabel = 'Total estimado',
    super.key,
  });

  final int labor;
  final int materials;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuotationSummaryItem(label: 'Mano de obra', value: labor),
        QuotationSummaryItem(label: 'Materiales', value: materials),
        const Divider(height: 20),
        QuotationSummaryItem(
          label: totalLabel,
          value: labor + materials,
          prominent: true,
        ),
      ],
    );
  }
}

class QuotationSummaryItem extends StatelessWidget {
  const QuotationSummaryItem({
    required this.label,
    required this.value,
    this.prominent = false,
    super.key,
  });
  final String label;
  final int value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final style = prominent
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(CurrencyFormatter.formatColones(value), style: style),
        ],
      ),
    );
  }
}

class QuotationInfoBanner extends StatelessWidget {
  const QuotationInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'El cliente podrá revisar tu cotización antes de aceptarla.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
