import 'package:flutter/material.dart';

import '../product_repo.dart';
import '../product_theme.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.image, this.size = 64, this.fit = BoxFit.cover});
  final String image;
  final double size;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes(image);
    final fallback = Container(
      color: canvas,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: muted, size: 32),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: bytes == null || bytes.isEmpty
            ? fallback
            : Image.memory(
                bytes,
                fit: fit,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
