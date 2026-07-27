import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/request_draft.dart';
import 'package:linko/features/home/presentation/widgets/professional_summary_card.dart';
import 'package:linko/features/home/presentation/widgets/request_info_banner.dart';
import 'package:linko/features/home/presentation/widgets/request_section_title.dart';
import 'package:linko/features/home/presentation/widgets/request_summary_item.dart';

class ConfirmRequestScreen extends StatelessWidget {
  const ConfirmRequestScreen({
    required this.draft,
    required this.onSubmit,
    super.key,
  });

  final RequestDraft draft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final photoSummary = switch (draft.attachedPhotoCount) {
      0 => 'No se agregaron fotos',
      1 => '1 foto adjunta',
      final count => '$count fotos adjuntas',
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Confirmar solicitud'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RequestSectionTitle(label: 'Profesional'),
                    const SizedBox(height: 10),
                    ProfessionalSummaryCard(professional: draft.professional),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RequestSectionTitle(label: 'Detalles del servicio'),
                      const SizedBox(height: 4),
                      RequestSummaryItem(
                        icon: Icons.description_outlined,
                        label: 'Descripción',
                        value: draft.description,
                      ),
                      RequestSummaryItem(
                        icon: Icons.location_on_outlined,
                        label: 'Ubicación',
                        value: draft.location,
                      ),
                      RequestSummaryItem(
                        icon: Icons.schedule_outlined,
                        label: 'Cuándo',
                        value: draft.timing.label,
                      ),
                      if (draft.selectedDate != null)
                        RequestSummaryItem(
                          icon: Icons.calendar_month_outlined,
                          label: 'Fecha',
                          value: draft.selectedDate!.spanishDate,
                        ),
                      RequestSummaryItem(
                        icon: Icons.photo_library_outlined,
                        label: 'Fotos adjuntas',
                        value: photoSummary,
                        showDivider: false,
                      ),
                      const SizedBox(height: 18),
                      const RequestInfoBanner(
                        message:
                            'El profesional revisará tu solicitud y podrá '
                            'enviarte una cotización.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onSubmit,
                  child: const Text('Enviar solicitud'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
