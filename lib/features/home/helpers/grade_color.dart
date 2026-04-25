import 'package:flutter/material.dart';
import 'package:notely/models/grade.dart';

Color gradeColor(Grade grade) {
  final mark = grade.mark?.toDouble() ?? 0.0;

  if (mark >= 4.5) {
    return const Color.fromARGB(255, 0, 110, 255);
  } else if (mark >= 4) {
    return Colors.orange;
  } else {
    return const Color.fromARGB(255, 255, 33, 46);
  }
}
