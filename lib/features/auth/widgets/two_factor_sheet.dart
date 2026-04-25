import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TwoFactorSheet extends StatefulWidget {
  final TextEditingController textController;

  const TwoFactorSheet({Key? key, required this.textController})
      : super(key: key);

  @override
  State<TwoFactorSheet> createState() => _TwoFactorSheetState();
}

class _TwoFactorSheetState extends State<TwoFactorSheet> {
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _hasInput) {
      setState(() {
        _hasInput = hasText;
      });
    }
  }

  void _submit() {
    Navigator.of(context).pop(widget.textController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final backgroundColor = cupertinoTheme.scaffoldBackgroundColor;
    final helperStyle = cupertinoTheme.textTheme.textStyle.copyWith(
          fontSize: 15,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        );
    final fieldBackground =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4.resolveFrom(context),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '2-Faktor-Code',
                        style: cupertinoTheme.textTheme.navTitleTextStyle
                            .copyWith(fontSize: 22),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size.square(32.0),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 24,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Bitte gib den aktuellen Code aus deiner Authentifizierungs-App ein.',
                  style: helperStyle,
                ),
                const SizedBox(height: 18),
                CupertinoTextField(
                  controller: widget.textController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: BoxDecoration(
                    color: fieldBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Der Code ändert sich alle paar Sekunden und aktualisiert sich hier automatisch. In den Einstellungen kannst du automatisches Ausfüllen für künftige Logins aktivieren.',
                  style: helperStyle,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: fieldBackground,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Abbrechen',
                          style: cupertinoTheme.textTheme.textStyle.copyWith(
                            color:
                                CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _hasInput ? _submit : null,
                        child: const Text('Senden'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
