import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notely/models/homework.dart';
import 'package:notely/helpers/homework_database.dart';
import 'package:notely/helpers/text_styles.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    List<Homework> homeworkList = widget.homeworkList;
    final titleStyle = pageTitleTextStyle(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hausaufgaben",
                        style: titleStyle,
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: SizedBox(
                    height: 44,
                    width: 44,
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: Stack(
            children: [
              (homeworkList.isNotEmpty)
                  ? Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        shrinkWrap: false,
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
                  : const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "😄",
                            style: TextStyle(fontSize: 128),
                          ),
                          Text(
                            "Keine Hausaufgaben vorhanden!",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Hausaufgaben kannst du hier hinzufügen oder indem du auf eine zukünftige Lektion unter \"Plan\" tippst.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CupertinoButton(
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
                                setState(() {
                                  homeworkList.add(homework);
                                });
                                widget.callBack(homeworkList);
                              });
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: Theme.of(context).primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.add,
                        color: Colors.white,
                        size: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard({
    required Homework homework,
    required int index,
    required List<Homework> homeworkList,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = homework.isDone
        ? const Color(0xFF34C759)
        : Theme.of(context).primaryColor;
    final Color cardColor = homework.isDone
        ? (isDark
            ? const Color(0xFF1F1F1F)
            : Colors.white.withValues(alpha: 0.05))
        : (isDark
            ? const Color(0xFF1C1C1E)
            : Colors.white.withValues(alpha: 0.05));
    final Color dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final TextStyle subtitleStyle = TextStyle(
      color: isDark
          ? Colors.white.withValues(alpha: 0.6)
          : Colors.black.withValues(alpha: 0.6),
      fontSize: 14,
    );
    final String formattedDate =
        DateFormat("dd.MM.yyyy · HH:mm").format(homework.dueDate.toLocal());

    Future<void> handleDelete() async {
      await HomeworkDatabase.instance.delete(homework.id);
      setState(() {
        homeworkList.removeAt(index);
      });
      widget.callBack(homeworkList);
    }

    Future<void> handleToggle(bool value) async {
      Homework updatedHomework = homework.copyWith(isDone: value);
      await HomeworkDatabase.instance.update(updatedHomework);

      setState(() {
        homeworkList[index] = updatedHomework;
      });
      widget.callBack(homeworkList);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: homework.isDone
              ? accentColor.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: isDark ? 0 : -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  homework.lessonName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.time,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            homework.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            homework.details,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: dividerColor, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: handleDelete,
                color: Colors.redAccent.withValues(alpha: 0.1),
                sizeStyle: CupertinoButtonSize.medium,
                borderRadius: BorderRadius.circular(8.0),
                child: const Row(
                  children: [
                    Icon(
                      CupertinoIcons.trash,
                      size: 24,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                "Erledigt",
                style: subtitleStyle.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 2),
              Transform.scale(
                scale: 1.5,
                child: Checkbox(
                  value: homework.isDone,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  checkColor: Colors.white,
                  activeColor: accentColor,
                  side: BorderSide(
                    color: accentColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? value) {
                    if (value == null) return;
                    handleToggle(value);
                  },
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
