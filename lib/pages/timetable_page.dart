import 'dart:convert';
import 'dart:math';

import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:notely/Globals.dart';
import 'package:notely/Models/Homework.dart';
import 'package:notely/helpers/HomeworkDatabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Event.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int timeShift = 0;
  DateTime today = DateTime.now();
  List<Event> _eventList = List.empty(growable: true);
  List<double> itemPositions = [];

// Define start and end of the day as DateTime objects
  final startOfDay = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0);
  final endOfDay = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59);

  // Define variables to calculate the position of the line
  final now = DateTime.now();
  late double currentTime;

  @override
  initState() {
    super.initState();
    getData();
    final totalDuration = endOfDay.difference(startOfDay).inMinutes;
    currentTime = now.difference(startOfDay).inMinutes / totalDuration;
  }

  double calculateItemHeight(DateTime startTime, DateTime endTime,
      DateTime minStartTime, DateTime maxEndTime, double minHeight) {
    final itemDuration = endTime.difference(startTime).inMinutes;
    final dayDuration = maxEndTime.difference(minStartTime).inMinutes;
    final itemHeight = itemDuration / dayDuration;
    return max(itemHeight * minHeight, minHeight);
  }

  void getData() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "";
    String dateFormatted = DateFormat('yyyy-MM-dd').format(today);
    String url = Globals().apiBase +
        school.toLowerCase() +
        "/rest/v1" +
        "/me/events?min_date=$dateFormatted&max_date=$dateFormatted";
    print(url);
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals().accessToken,
      }).then((response) {
        if (mounted) {
          setState(() {
            _eventList = (json.decode(response.body) as List)
                .map((i) => Event.fromJson(i))
                .toList();
            _eventList.forEach((element) {
              print(element.id);
            });
          });
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Widget _eventWidget(BuildContext context, Event event) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(top: 5, bottom: 5, left: 10.0, right: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  // Get data of TextFields
                  TextEditingController titleController =
                      TextEditingController();
                  TextEditingController detailsController =
                      TextEditingController();
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0))),
                    title: Text("Hausaufgabe eintragen"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Titel",
                        ),
                        TextField(
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText1!.color,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(8.0),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          controller: titleController,
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Details",
                        ),
                        TextField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(8.0),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          controller: detailsController,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text("Abbrechen"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text("Speichern"),
                        onPressed: () async {
                          // Get text of TextFields
                          String title = titleController.text;
                          String details = detailsController.text.trimRight();
                          DateTime startDate = DateTime.parse(event.startDate!);

                          if (title.isEmpty && details.isEmpty) {
                            title = "Kein Titel";
                            details = "Keine Details";
                          }

                          if (title.isEmpty) {
                            title = "Kein Titel";
                          }

                          if (details.isEmpty) {
                            details = "Keine Details";
                          }
                          try {
                            Homework homework = Homework(
                              id: event.id!,
                              lessonName: event.courseName!,
                              title: title,
                              details: details,
                              dueDate: startDate,
                              isDone: false,
                            );

                            await HomeworkDatabase.instance.create(homework);
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
                });
          },
          child: Container(
            padding: EdgeInsets.all(12),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          event.startDate!
                              .substring(event.startDate!.length - 5),
                          style: TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        Opacity(
                          opacity: 0.75,
                          child: Text(
                            event.endDate!
                                .substring(event.endDate!.length - 5)
                                .toString(),
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 9.0,
                  ),
                  Container(
                    width: 3,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: (DateTime.now()
                                  .isAfter(DateTime.parse(event.startDate!)) &&
                              DateTime.now()
                                  .isBefore(DateTime.parse(event.endDate!)))
                          ? Colors.blue
                          : Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 9.0,
                  ),
                  Expanded(
                    flex: 12,
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            event.courseName.toString(),
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                                fontSize: 21,
                                height: 1.1,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            event.teachers!.first.toString(),
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    event.roomToken.toString(),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Stundenplan",
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
        /*DatePicker(
          DateTime.now(),
          height: 90,
          initialSelectedDate: today,
          selectionColor: Globals().isDark
              ? Color.fromARGB(255, 46, 46, 46)
              : Colors.grey.withOpacity(0.2),
          selectedTextColor: Globals().isDark ? Colors.white : Colors.black,
          dayTextStyle: TextStyle(color: Colors.grey),
          monthTextStyle: TextStyle(color: Colors.grey),
          dateTextStyle: TextStyle(color: Colors.grey),
          locale: "de",
          onDateChange: (date) {
            setState(() {
              today = date;
            });
            getData();
          },
        ),*/
        CalendarTimeline(
          initialDate: today,
          firstDate: DateTime.now(),
          lastDate:
              DateTime(DateTime.now().year, 12, 31).add(Duration(days: 60)),
          onDateSelected: (date) {
            setState(() {
              today = date;
            });
            getData();
          },
          leftMargin: 20,
          monthColor: Colors.blueGrey,
          dayColor: Theme.of(context).textTheme.headlineLarge!.color,
          activeDayColor: Colors.white,
          activeBackgroundDayColor: Colors.blueAccent,
          dotsColor: Color(0xFF333A47),
          locale: 'de',
        ),
        Expanded(
          child: (_eventList.isNotEmpty)
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: _eventList.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    Event event = _eventList[index];
                    return LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return _eventWidget(context, event);
                    });
                  })
              : Center(
                  child: Text(
                    "Keine Lektionen eingetragen",
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
        ),
      ],
    );
  }
}
