import 'dart:ui';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:notely/core/analytics/analytics_service.dart';
import 'package:notely/models/homework.dart';
import 'package:notely/data/database/homework_database.dart';
import 'package:notely/features/home/helpers/text_styles.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage(
      {Key? key, required this.homeworkList, required this.callBack})
      : super(key: key);
  final List<Homework> homeworkList;
  final Function callBack;

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  bool isDone = false;
  DateTime? selectedDate = DateTime.now();

  @override
  initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'HomeworkPage');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<Homework> homeworkList = widget.homeworkList;
    final titleStyle = pageTitleTextStyle(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: (homeworkList.isNotEmpty)
                  ? Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        shrinkWrap: false,
                        padding: EdgeInsets.only(
                          top: 68,
                          bottom: MediaQuery.of(context).padding.bottom + 84,
                        ),
                        itemCount: homeworkList.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          Homework homework = homeworkList[index];
                          return _buildHomeworkCard(
                            homework: homework,
                            index: index,
                            homeworkList: homeworkList,
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_seal,
                              size: 72,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Keine Hausaufgaben vorhanden!",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Hausaufgaben kannst du hier hinzufügen oder indem du auf eine zukünftige Lektion unter \"Plan\" tippst.",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CNButton.icon(
                    icon: const CNSymbol('plus', size: 22.0),
                    size: 52.0,
                    style: CNButtonStyle.glass,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.35),
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (BuildContext context) {
                          return DisplayDialog(
                              initialDate: selectedDate!,
                              onHomeworkAdded: (homework) async {
                                await HomeworkDatabase.instance
                                    .create(homework);
                                AnalyticsService().logHomeworkCreated(
                                  subject: homework.lessonName,
                                  hasDueDate: true,
                                );
                                setState(() {
                                  homeworkList.add(homework);
                                });
                                widget.callBack(homeworkList);
                              });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16.0, 10.0, 8.0, 10.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .canvasColor
                          .withValues(alpha: isDark ? 0.75 : 0.7),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Hausaufgaben",
                            style: titleStyle,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.xmark,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard({
    required Homework homework,
    required int index,
    required List<Homework> homeworkList,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime dueDate = homework.dueDate.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final int diffDays = dueDay.difference(today).inDays;

    final bool isOverdue = !homework.isDone && diffDays < 0;
    final bool isToday = diffDays == 0;
    final bool isTomorrow = diffDays == 1;

    final Color statusAccentColor = homework.isDone
        ? const Color(0xFF34C759)
        : isOverdue
            ? const Color(0xFFFF3B30)
            : isToday
                ? const Color(0xFFFF9500)
                : isTomorrow
                    ? Colors.blueAccent
                    : (isDark ? Colors.white70 : const Color(0xFF636366));

    final String timeStr = DateFormat("HH:mm").format(dueDate);
    final String baseDateText = isToday
        ? "Heute · $timeStr"
        : isTomorrow
            ? "Morgen · $timeStr"
            : DateFormat("EEE, dd. MMM · HH:mm", 'de_CH').format(dueDate);

    final String dateBadgeText = isOverdue
        ? "Überfällig · ${DateFormat("dd.MM. · HH:mm").format(dueDate)}"
        : baseDateText;

    final Color cardColor = homework.isDone
        ? (isDark ? const Color(0xFF161618) : const Color(0xFFFAFAFA))
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

    final Color dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    Future<void> handleDelete() async {
      HapticFeedback.mediumImpact();
      await HomeworkDatabase.instance.delete(homework.id);
      AnalyticsService().logHomeworkDeleted(subject: homework.lessonName);
      setState(() {
        homeworkList.removeAt(index);
      });
      widget.callBack(homeworkList);
    }

    Future<void> handleToggle(bool value) async {
      HapticFeedback.lightImpact();
      Homework updatedHomework = homework.copyWith(isDone: value);
      await HomeworkDatabase.instance.update(updatedHomework);
      AnalyticsService().logHomeworkToggled(
        isDone: value,
        subject: homework.lessonName,
      );

      setState(() {
        homeworkList[index] = updatedHomework;
      });
      widget.callBack(homeworkList);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: homework.isDone
              ? const Color(0xFF34C759).withValues(alpha: isDark ? 0.35 : 0.4)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.book_fill,
                      size: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      homework.lessonName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (homework.isDone || isOverdue || isToday || isTomorrow)
                      ? statusAccentColor.withValues(alpha: isDark ? 0.18 : 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      homework.isDone
                          ? CupertinoIcons.checkmark_circle_fill
                          : isOverdue
                              ? CupertinoIcons.exclamationmark_circle_fill
                              : CupertinoIcons.clock_fill,
                      size: 11.5,
                      color: statusAccentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateBadgeText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: statusAccentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            homework.title,
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.2,
              decoration: homework.isDone ? TextDecoration.lineThrough : null,
              decorationColor: isDark ? Colors.white38 : Colors.black38,
              color: homework.isDone
                  ? (isDark ? Colors.white38 : Colors.black38)
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          if (homework.details.trim().isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.035)
                    : Colors.black.withValues(alpha: 0.025),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.text_quote,
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      homework.details,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: homework.isDone
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.75)
                                : Colors.black.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                sizeStyle: CupertinoButtonSize.small,
                onPressed: handleDelete,
                color: Colors.redAccent.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(6.0),
                child: const Icon(
                  CupertinoIcons.trash,
                  size: 15,
                  color: Colors.redAccent,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => handleToggle(!homework.isDone),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: homework.isDone
                        ? const Color(0xFF34C759)
                            .withValues(alpha: isDark ? 0.18 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Erledigt",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: homework.isDone
                              ? const Color(0xFF34C759)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        homework.isDone
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: 20,
                        color: homework.isDone
                            ? const Color(0xFF34C759)
                            : (isDark ? Colors.white38 : Colors.black26),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DisplayDialog extends StatefulWidget {
  final DateTime initialDate;
  final String? initialSubject;
  final Function(Homework) onHomeworkAdded;

  const DisplayDialog(
      {super.key,
      required this.initialDate,
      required this.onHomeworkAdded,
      this.initialSubject});

  @override
  State<DisplayDialog> createState() => _DisplayDialogState();
}

class _DisplayDialogState extends State<DisplayDialog> {
  late DateTime _date;
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    if (widget.initialSubject != null) {
      subjectController.text = widget.initialSubject!;
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    DateTime tempDate = _date;
    final selectedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final Color backgroundColor =
            CupertinoTheme.of(context).scaffoldBackgroundColor;
        return SafeArea(
          top: false,
          bottom: false,
          child: Container(
            height: 320,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Abbrechen'),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        onPressed: () => Navigator.of(context).pop(tempDate),
                        child: const Text(
                          'Fertig',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    use24hFormat: true,
                    initialDateTime: _date,
                    minimumYear: 2000,
                    maximumYear: 3000,
                    onDateTimeChanged: (DateTime value) {
                      tempDate = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _date = selectedDate;
      });
    }
  }

  Widget _buildTextField({
    required String placeholder,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    final Color fieldBackground =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textInputAction:
          maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
    );
  }

  void _saveHomework() {
    FocusScope.of(context).unfocus();
    String subject = subjectController.text.trim();
    String title = titleController.text.trim();
    String details = detailsController.text.trimRight();

    if (title.isEmpty && details.isEmpty) {
      title = "Kein Titel";
      details = "Keine Details";
    }

    if (subject.isEmpty) {
      subject = "Kein Fach";
    }

    if (title.isEmpty) {
      title = "Kein Titel";
    }

    if (details.isEmpty) {
      details = "Keine Details";
    }

    try {
      Homework homework = Homework(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lessonName: subject,
        title: title,
        details: details,
        dueDate: _date,
        isDone: false,
      );
      widget.onHomeworkAdded(homework);
      Navigator.of(context).pop();
    } catch (e) {
      showToast(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 32.0),
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.all(
              Radius.circular(12.0),
            ),
          ),
          padding: const EdgeInsets.all(6.0),
          child: const Text(
            "Etwas ist schiefgelaufen",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        ),
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        CupertinoTheme.of(context).scaffoldBackgroundColor;
    final Color fieldBackground =
        CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
    final TextStyle helperStyle =
        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 13,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
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
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
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
                const SizedBox(height: 16),
                Text(
                  "Hausaufgabe eintragen",
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .navTitleTextStyle
                      .copyWith(fontSize: 22),
                ),
                const SizedBox(height: 20),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _presentDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: fieldBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Fällig am",
                              style: helperStyle,
                            ),
                            Text(
                              DateFormat("dd.MM.yyyy · HH:mm").format(_date),
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .textStyle
                                  .copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 18,
                          color:
                              CupertinoColors.systemGrey2.resolveFrom(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  placeholder: "Fach",
                  controller: subjectController,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  placeholder: "Titel",
                  controller: titleController,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  placeholder: "Details",
                  controller: detailsController,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(14),
                        color: fieldBackground,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Abbrechen",
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(14),
                        onPressed: _saveHomework,
                        child: const Text(
                          "Hinzufügen",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
