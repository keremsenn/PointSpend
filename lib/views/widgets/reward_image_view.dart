import 'dart:convert';
import 'package:flutter/material.dart';

class RewardImageView extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget fallback;

  const RewardImageView({
    super.key,
    required this.imageUrl,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    this.borderRadius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return fallback;

    Widget imageWidget;
    try {
      if (trimmed.startsWith('data:image') || trimmed.startsWith('base64,')) {
        final commaIdx = trimmed.indexOf(',');
        final raw = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(raw);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        imageWidget = Image.network(
          trimmed,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        );
      } else {
        imageWidget = fallback;
      }
    } catch (_) {
      imageWidget = fallback;
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
