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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useHorizontalLayout = constraints.maxWidth >= 720;
            final cards = [
              _UserTypeCard(
                icon: Icons.home_repair_service_rounded,
                title: 'I need a professional',
                description: 'Find trusted professionals near you.',
                onTap: onCustomerSelected,
              ),
              _UserTypeCard(
                icon: Icons.handshake_rounded,
                title: "I'm a professional",
                description: 'Grow your business and receive requests.',
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
                        'Who are you?',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Choose how you'd like to use Linko.",
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (useHorizontalLayout)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: cards.first),
                            const SizedBox(width: 20),
                            Expanded(child: cards.last),
                          ],
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
  static const _accentColor = Color(0xFF2F80ED);

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF7FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? _accentColor : const Color(0xFFDCE4EE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.10 : 0.05),
              blurRadius: _isHovered ? 24 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (value) => setState(() => _isHovered = value),
            onHighlightChanged: (value) => setState(() => _isPressed = value),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(widget.icon, size: 34, color: _accentColor),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
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
    );
  }
}
