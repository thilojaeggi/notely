import 'package:flutter/material.dart';

TextStyle pageTitleTextStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodyMedium?.color,
      ) ??
      const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
      );
}
