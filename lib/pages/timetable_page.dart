import 'dart:async';

import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notely/models/exam.dart';
import 'package:notely/models/homework.dart';
import 'package:notely/helpers/homework_database.dart';
import 'package:notely/helpers/api_client.dart';
import '../models/Event.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int timeShift = 0;
  DateTime today = DateTime.now();
  final StreamController<List<Event>> _eventStreamController =
      StreamController<List<Event>>();
  final APIClient _apiClient = APIClient();

  void _getEvents() async {
    if (!mounted) return;
    try {
      List<Event> cachedEvents = await _apiClient.getEvents(today, true);
      _eventStreamController.sink.add(cachedEvents);

      // Then get the latest data and update the UI again
      List<Event> currentEvents = await _apiClient.getEvents(today, false);
      List<Exam> cachedExams = await _apiClient
          .getExams(true); // Cached exams is good enough I think

      // Go through all events and exams and check if id and startDate match
      for (int i = 0; i < currentEvents.length; i++) {
        for (int j = 0; j < cachedExams.length; j++) {
          if (currentEvents[i].id == cachedExams[j].id &&
              currentEvents[i].startDate == cachedExams[j].startDate) {
            currentEvents[i].isExam = true;
          }
        }
      }
      _eventStreamController.sink.add(currentEvents);
    } catch (e) {
      // Handle the StateError here
      debugPrint('Error adding event to stream controller: $e');
    }
  }

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
    _getEvents();
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
            HapticFeedback.selectionClick();
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  // Get data of TextFields
                  TextEditingController titleController =
                      TextEditingController();
                  TextEditingController detailsController =
                      TextEditingController();
                  return AlertDialog(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0))),
                    title: const Text("Hausaufgabe eintragen"),
                    content: SizedBox(
                      width: 300,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          TextField(
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall!.color,
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
                              contentPadding: const EdgeInsets.all(8.0),
                              isDense: true,
                              border: const OutlineInputBorder(),
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
                              contentPadding: const EdgeInsets.all(8.0),
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            controller: detailsController,
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Abbrechen"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: const Text("Speichern"),
                        onPressed: () async {
                          // Get text of TextFields
                          String title = titleController.text;
                          String details = detailsController.text.trimRight();
                          DateTime startDate = event.startDate!;

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
                          if (!mounted) return;

                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                });
          },
          child: Stack(
            children: [
              event.isExam ?? false
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 1),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                        child: const Text("Test"),
                      ),
                    )
                  : const SizedBox.shrink(),
              Container(
                padding: const EdgeInsets.all(12),
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
                              // Format startdate as HH:MM without using substring
                              event.startDate!.toString().substring(11, 16),

                              style: const TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            Opacity(
                              opacity: 0.75,
                              child: Text(
                                event.endDate!.toString().substring(11, 16),
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 9.0,
                      ),
                      Container(
                        width: 3,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: (DateTime.now().isAfter(event.startDate!) &&
                                  DateTime.now().isBefore(event.endDate!))
                              ? Colors.blue
                              : Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .color,
                        ),
                      ),
                      const SizedBox(
                        width: 9.0,
                      ),
                      Expanded(
                        flex: 12,
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
                      const SizedBox(
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
              ),
            ],
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
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
        CalendarTimeline(
          initialDate: today,
          firstDate: DateTime.now(),
          lastDate: DateTime(DateTime.now().year, 12, 31)
              .add(const Duration(days: 60)),
          onDateSelected: (date) {
            setState(() {
              today = date;
            });
            _getEvents();
          },
          leftMargin: 20,
          monthColor: Colors.blueGrey,
          dayColor: Theme.of(context).textTheme.headlineLarge!.color,
          activeDayColor: Colors.white,
          activeBackgroundDayColor: Colors.blueAccent,
          dotsColor: const Color(0xFF333A47),
          locale: 'de',
        ),
        StreamBuilder<List<Event>>(
            stream: _eventStreamController.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text("Error"),
                );
              }
              List<Event> eventList = snapshot.data!;
              return Expanded(
                child: (eventList.isNotEmpty)
                    ? Scrollbar(
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: eventList.length,
                            itemBuilder: (BuildContext ctxt, int index) {
                              Event event = eventList[index];
                              return LayoutBuilder(builder:
                                  (BuildContext context,
                                      BoxConstraints constraints) {
                                return _eventWidget(context, event);
                              });
                            }),
                      )
                    : const Center(
                        child: Text(
                          "Keine Lektionen eingetragen",
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
              );
            }),
      ],
    );
  }
}
