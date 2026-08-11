import 'package:flutter/material.dart';

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({
    required this.onCustomerSelected,
    required this.onProfessionalSelected,
    super.key,
  });

  final VoidCallback onCustomerSelected;
  final VoidCallback onProfessionalSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(automaticallyImplyLeading: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useHorizontalLayout = constraints.maxWidth >= 720;
            final cards = [
              _UserTypeCard(
                icon: Icons.search_rounded,
                title: 'Necesito un servicio',
                description:
                    'Encuentra profesionales de confianza para cualquier necesidad.',
                onTap: onCustomerSelected,
              ),
              _UserTypeCard(
                icon: Icons.handshake_rounded,
                title: 'Quiero ofrecer mis servicios',
                description:
                    'Conecta con nuevos clientes y recibe solicitudes de trabajo.',
                onTap: onProfessionalSelected,
              ),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Text(
                        '¿Cómo deseas usar LinkO?',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Selecciona la opción que mejor se adapte a ti.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (useHorizontalLayout)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: cards.first),
                              const SizedBox(width: 32),
                              Expanded(child: cards.last),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            cards.first,
                            const SizedBox(height: 16),
                            cards.last,
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatefulWidget {
  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  State<_UserTypeCard> createState() => _UserTypeCardState();
}

class _UserTypeCardState extends State<_UserTypeCard> {
  static const _contentPadding = 28.0;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 376),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? colorScheme.primary : colorScheme.outline,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: _isHovered ? 0.10 : 0.05,
                ),
                blurRadius: _isHovered ? 24 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: colorScheme.surface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (value) => setState(() => _isHovered = value),
              onHighlightChanged: (value) => setState(() => _isPressed = value),
              child: Padding(
                padding: const EdgeInsets.all(_contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 34,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
