import 'dart:io';
import 'dart:math';

import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notely/Models/Homework.dart';
import 'package:notely/config/CustomScrollBehavior.dart';
import 'package:notely/helpers/HomeworkDatabase.dart';

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: new BoxDecoration(
        color: Theme.of(context).canvasColor.withOpacity(0.96),
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(16.0),
          topRight: const Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    // Make text full width
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      "Hausaufgaben",
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
              child: Stack(
            children: [
              (homeworkList.isNotEmpty)
                  ? ScrollConfiguration(
                      behavior: CustomScrollBehavior(),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          shrinkWrap: false,
                          itemCount: homeworkList.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            Homework homework = homeworkList[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(
                                  bottom: 10, left: 10.0, right: 10.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              homeworkList[index]
                                                  .lessonName
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          DateFormat("dd.MM.yyyy HH:mm").format(
                                              DateTime.parse(homeworkList[index]
                                                  .dueDate
                                                  .toLocal()
                                                  .toString())),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark
                                                ? Colors.white.withOpacity(0.5)
                                                : Colors.black.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 15.0),
                                        height: 2.0,
                                        width: 100.0,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        )),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        homeworkList[index].title.toString(),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      homeworkList[index].details.toString(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                            onPressed: () async {
                                              await HomeworkDatabase.instance
                                                  .delete(homework.id);
                                              setState(() {
                                                homeworkList.removeAt(index);
                                              });
                                              widget.callBack(homeworkList);
                                            },
                                            child: Text(
                                              "Löschen",
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 16),
                                            )),
                                        Transform.scale(
                                          scale: 1.7,
                                          child: Checkbox(
                                              value: homework.isDone,
                                              fillColor:
                                                  MaterialStateProperty.all(
                                                      Theme.of(context)
                                                          .primaryColor),
                                              // Rounded checkbox
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              onChanged: (newVal) async {
                                                Homework updatedHomework =
                                                    homework.copyWith(
                                                        isDone: newVal!);
                                                await HomeworkDatabase.instance
                                                    .update(updatedHomework);

                                                setState(() {
                                                  homeworkList[index] =
                                                      updatedHomework;
                                                });
                                                widget.callBack(homeworkList);
                                              }),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
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
                          const SizedBox(
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
                  padding: const EdgeInsets.all(32.0),
                  child: SizedBox(
                    height: 64,
                    width: 64,
                    child: FloatingActionButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16))),
                      onPressed: () {
                        showDialog(
                          context: context,
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
                      child: Icon(
                        Icons.add,
                        size: 46,
                      ),
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
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
}

class DisplayDialog extends StatefulWidget {
  final DateTime initialDate;
  final Function(Homework) onHomeworkAdded;

  DisplayDialog({required this.initialDate, required this.onHomeworkAdded});

  @override
  _DisplayDialogState createState() => _DisplayDialogState();
}

class _DisplayDialogState extends State<DisplayDialog> {
  late DateTime _date;
  TextEditingController subjectController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController detailsController = TextEditingController();

  iosDatePicker(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (BuildContext builder) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    use24hFormat: true,
                    onDateTimeChanged: (value) {
                      setState(() {
                        _date = value;
                      });
                    },
                    initialDateTime: DateTime.now(),
                    minimumYear: 2000,
                    maximumYear: 3000,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: CupertinoButton(
                    child: const Text(
                      'Fertig',
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              ],
            ),
          );
        });
  }

  androidDatePicker(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(3000),
      locale: Locale('de'),
    );
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    // Show date picker
    final pickedDate = (Platform.isIOS || Platform.isMacOS || kDebugMode)
        ? await iosDatePicker(context)
        : await androidDatePicker(context);
    print("Getting selected date");
    if (pickedDate != null) {
      selectedDate = pickedDate;

      // Show time picker
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        // 24 hour time
      );

      if (pickedTime != null) {
        selectedTime = pickedTime;
        final DateTime combinedDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute);
        print(combinedDateTime);
        setState(() {
          _date = combinedDateTime;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0))),
      title: Text("Hausaufgabe eintragen"),
      content: Container(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: [
            GestureDetector(
              onTap: () {
                _showDateTimePicker(context);
              },
              child: Container(
                padding: EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .color!
                        .withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                // String as date in format dd.MM.yyyy HH:mm
                child: Text(
                  DateFormat("dd.MM.yyyy HH:mm").format(_date),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Fach",
                labelStyle: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .color!
                      .withOpacity(0.4),
                ),
                contentPadding: EdgeInsets.all(8.0),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              controller: subjectController,
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: "Titel",
                labelStyle: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .color!
                      .withOpacity(0.4),
                ),
                contentPadding: EdgeInsets.all(8.0),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              controller: titleController,
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Details",
                labelStyle: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .color!
                      .withOpacity(0.4),
                ),
                contentPadding: EdgeInsets.all(8.0),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              controller: detailsController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text("Abbrechen"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          child: Text("Speichern"),
          onPressed: () async {
            // Get text of TextFields
            String subject = subjectController.text;
            String title = titleController.text;
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
            } catch (e) {
              showToast(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: EdgeInsets.only(bottom: 32.0),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.all(
                      Radius.circular(12.0),
                    ),
                  ),
                  padding: EdgeInsets.all(6.0),
                  child: Text(
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
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
