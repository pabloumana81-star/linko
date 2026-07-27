import 'dart:async';

import 'package:flutter/material.dart';

class LinkoSplashScreen extends StatefulWidget {
  const LinkoSplashScreen({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<LinkoSplashScreen> createState() => _LinkoSplashScreenState();
}

class _LinkoSplashScreenState extends State<LinkoSplashScreen> {
  late final Timer _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), widget.onComplete);
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.handshake_rounded,
                    size: 58,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'LinkO',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Conectamos profesionales de confianza con quienes los necesitan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
