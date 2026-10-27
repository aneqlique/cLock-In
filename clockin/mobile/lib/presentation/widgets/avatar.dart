import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

/// Round profile picture with an initial-letter fallback.
class Avatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double radius;

  const Avatar({super.key, required this.imageUrl, required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.8,
        ),
      ),
    );
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? fallback
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

/// The cLock-In mark, tinted to the current theme's text color.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Logo.png',
      height: size,
      color: context.cs.onSurface,
      colorBlendMode: BlendMode.srcIn,
      semanticLabel: 'cLock-In',
      errorBuilder: (_, __, ___) => SizedBox(height: size),
    );
  }
}
