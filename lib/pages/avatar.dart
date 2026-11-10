import 'dart:convert';

import 'package:flutter/material.dart';

import '../academic_theme.dart';
import '../profile_validation.dart';

class Avatar extends StatelessWidget {
  const Avatar(this.base64, {super.key, this.radius = 24});
  final String? base64;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget image = Icon(
      Icons.person_outline,
      size: radius,
      color: academicSlate,
    );
    try {
      final bytes = base64Decode(base64 ?? '');
      if (validatePhotoBytes(bytes) == null) {
        image = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Icon(Icons.person_outline, size: radius, color: academicSlate),
        );
      }
    } on FormatException {
      image = Icon(Icons.person_outline, size: radius, color: academicSlate);
    }
    return Semantics(
      label: 'Ảnh đại diện',
      image: true,
      child: ClipOval(
        child: ColoredBox(
          color: academicIvory,
          child: SizedBox.square(dimension: radius * 2, child: image),
        ),
      ),
    );
  }
}
