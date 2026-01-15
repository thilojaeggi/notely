import 'dart:io';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WhatsNew extends StatefulWidget {
  const WhatsNew({super.key, required this.school});
  final String school;
  static final List<WhatsNewEntry> updates = [];

  @override
  State<WhatsNew> createState() => _WhatsNewState();
}

class _WhatsNewState extends State<WhatsNew> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.colorScheme.surface;
    final updates = WhatsNew.updates;

    return SafeArea(
      bottom: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28.0),
            topRight: Radius.circular(28.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, -16),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: isDark ? 0.5 : 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Scrollbar(
                radius: const Radius.circular(12),
                thumbVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeader(context),
                    for (int i = 0; i < updates.length; i++)
                      _WhatsNewTile(
                        entry: updates[i],
                        isLast: i == updates.length - 1,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 4,
              ),
              child: CNButton(
                  style: CNButtonStyle.prominentGlass,
                  height: 48,
                  onPressed: () => Navigator.pop(context),
                  label: "Weiter"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Was ist neu",
            style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ) ??
                const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class WhatsNewEntry {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final bool highlighted;

  const WhatsNewEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    this.highlighted = false,
  });
}

class _WhatsNewTile extends StatelessWidget {
  final WhatsNewEntry entry;
  final bool isLast;

  const _WhatsNewTile({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final isHighlighted = entry.highlighted;
    final highlightColor = isHighlighted
        ? entry.accent.withValues(alpha: isDark ? 0.3 : 0.12)
        : Colors.transparent;
    final highlightPadding = isHighlighted
        ? const EdgeInsets.symmetric(vertical: 6, horizontal: 6)
        : EdgeInsets.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Transform.scale(
        scale: isHighlighted ? 1.05 : 1.0,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: BoxBorder.all(width: 2, color: highlightColor),
              ),
              padding: highlightPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          entry.accent.withValues(alpha: isDark ? 0.18 : 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      entry.icon,
                      color: entry.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                              ) ??
                              const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 18),
              Divider(
                height: 1,
                thickness: 1,
                color: borderColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
