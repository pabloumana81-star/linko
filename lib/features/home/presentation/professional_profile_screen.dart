import 'package:flutter/material.dart';
import 'package:linko/features/home/presentation/models/professional_profile_data.dart';
import 'package:linko/features/home/presentation/widgets/review_card.dart';
import 'package:linko/features/home/presentation/widgets/service_chip.dart';
import 'package:linko/features/home/presentation/widgets/trust_indicator.dart';
import 'package:linko/features/home/presentation/widgets/work_gallery_item.dart';

class ProfessionalProfileScreen extends StatelessWidget {
  const ProfessionalProfileScreen({required this.professional, super.key});

  final ProfessionalProfileData professional;

  static const _services = [
    'Instalaciones eléctricas',
    'Reparaciones',
    'Mantenimiento',
    'Revisión de sistemas',
  ];

  static const _reviews = [
    _ReviewData(
      clientName: 'Laura M.',
      rating: 5,
      comment: 'Excelente servicio, muy puntual y profesional.',
      date: 'Hace 2 semanas',
    ),
    _ReviewData(
      clientName: 'José A.',
      rating: 4.9,
      comment: 'Explicó el trabajo con claridad y resolvió todo rápidamente.',
      date: 'Hace 1 mes',
    ),
    _ReviewData(
      clientName: 'Andrea R.',
      rating: 5,
      comment: 'Trabajo ordenado, confiable y con muy buena comunicación.',
      date: 'Hace 2 meses',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Perfil profesional'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        size: 62,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      professional.name,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      professional.profession,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _ProfileDetail(
                          icon: Icons.star_rounded,
                          label:
                              '${professional.rating.toStringAsFixed(1)} '
                              '(${professional.reviewCount} reseñas)',
                          iconColor: const Color(0xFFF59E0B),
                        ),
                        _ProfileDetail(
                          icon: Icons.location_on_outlined,
                          label: professional.location,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Profesional verificado',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    TrustIndicator(
                      icon: Icons.workspace_premium_outlined,
                      label: '8 años de experiencia',
                    ),
                    TrustIndicator(
                      icon: Icons.task_alt_rounded,
                      label: '145 servicios completados',
                    ),
                    TrustIndicator(
                      icon: Icons.schedule_rounded,
                      label: 'Responde en menos de 1 hora',
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                const _ProfileSectionTitle(label: 'Acerca de'),
                const SizedBox(height: 12),
                Text(
                  'Profesional con experiencia en instalaciones, reparaciones '
                  'y mantenimiento eléctrico residencial y comercial.',
                  style: textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                const _ProfileSectionTitle(label: 'Servicios'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final service in _services)
                      ServiceChip(label: service),
                  ],
                ),
                const SizedBox(height: 32),
                const _ProfileSectionTitle(label: 'Trabajos realizados'),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columnCount = constraints.maxWidth >= 700 ? 3 : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 4 / 3,
                      ),
                      itemBuilder: (context, index) {
                        return WorkGalleryItem(label: 'Trabajo ${index + 1}');
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                const _ProfileSectionTitle(label: 'Reseñas'),
                const SizedBox(height: 10),
                for (var index = 0; index < _reviews.length; index++) ...[
                  ReviewCard(
                    clientName: _reviews[index].clientName,
                    rating: _reviews[index].rating,
                    comment: _reviews[index].comment,
                    date: _reviews[index].date,
                  ),
                  if (index != _reviews.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
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
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Solicitar servicio'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: iconColor ?? color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ReviewData {
  const _ReviewData({
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String clientName;
  final double rating;
  final String comment;
  final String date;
}
