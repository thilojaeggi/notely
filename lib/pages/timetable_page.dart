import 'dart:async';

import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:notely/models/exam.dart';
import 'package:notely/helpers/homework_database.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/text_styles.dart';
import 'package:notely/pages/homework_page.dart';
import '../models/Event.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int timeShift = 0;
  DateTime today = DateTime.now();
  late Future<List<Event>> _eventsFuture;
  final APIClient _apiClient = APIClient();

  Future<List<Event>> _loadEvents(DateTime date) async {
    try {
      final cachedEvents = await _apiClient.getEvents(date, true);
      final cachedExams = await _apiClient.getExams(true);
      _markExams(cachedEvents, cachedExams);

      _refreshEvents(date);
      return cachedEvents;
    } catch (e) {
      debugPrint('Error loading cached events: $e');
      return [];
    }
  }

  Future<void> _refreshEvents(DateTime date) async {
    try {
      final currentEvents = await _apiClient.getEvents(date, false);
      final cachedExams = await _apiClient.getExams(true);
      _markExams(currentEvents, cachedExams);

      if (!mounted) return;
      setState(() {
        _eventsFuture = Future.value(currentEvents);
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
  }

  void _markExams(List<Event> events, List<Exam> cachedExams) {
    for (final event in events) {
      event.isExam = cachedExams.any((exam) =>
          exam.id == event.id && exam.startDate == event.startDate);
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
    _eventsFuture = _loadEvents(today);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _humanReadableDuration(Duration duration) {
    if (duration.inMinutes <= 0) {
      return '';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} Min.';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '$hours Std.';
    }
    return '$hours Std. $minutes Min.';
  }


  Widget _eventWidget(BuildContext context, Event event) {
    // Return early if required fields are null
    if (event.startDate == null || event.endDate == null) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5, left: 10.0, right: 10.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            // Check if required fields are available before showing dialog
            if (event.id == null ||
                event.courseName == null ||
                event.startDate == null) {
              return;
            }
            showModalBottomSheet(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.35),
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (BuildContext context) {
                return DisplayDialog(
                  initialDate: event.startDate!,
                  initialSubject: event.courseName,
                  onHomeworkAdded: (homework) async {
                    try {
                      await HomeworkDatabase.instance.create(
                        homework.copyWith(
                          id: event.id!,
                          lessonName: event.courseName,
                        ),
                      );
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
                  },
                );
              },
            );
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
                              event.courseName?.toString() ?? '',
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(),
                            ),
                            Text(
                              (event.teachers != null &&
                                      event.teachers!.isNotEmpty)
                                  ? event.teachers!.first.toString()
                                  : '',
                              textAlign: TextAlign.start,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : Colors.black.withValues(alpha: 0.75),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        event.roomToken?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
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
    final titleStyle = pageTitleTextStyle(context);
    return SafeArea(
      top: true, bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Stundenplan",
                  style: titleStyle,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          EasyDateTimeLinePicker.itemBuilder(
            firstDate: DateTime.now(),
            lastDate: DateTime(DateTime.now().year, 12, 31)
                .add(const Duration(days: 60)),
            focusedDate: today,
            locale: const Locale('de', 'CH'),
            selectionMode: const SelectionMode.alwaysFirst(
                // ignore: deprecated_member_use
                duration: Duration(milliseconds: 300)),
            headerOptions: const HeaderOptions(
              headerType: HeaderType.none,
            ),
            timelineOptions: const TimelineOptions(height: 80.0),
            onDateChange: (date) {
              setState(() {
                today = date;
              });
              _eventsFuture = _loadEvents(date);
            },
            itemExtent: 60.0,
            itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : null,
                      borderRadius: BorderRadius.circular(8.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            DateFormat.MMM('de_CH').format(date),
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 12.0,
                                      height: 2,
                                    ),
                          ),
                        ),
                      ),
      
                      // Day number – stays perfectly vertically centered
                      Center(
                        child: Text(
                          date.day.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 32.0,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                        ),
                      ),
      
                      Expanded(
                        child: Center(
                          child: Text(
                            DateFormat.E('de_CH').format(date),
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 18.0,
                                      height: 1,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
                    const SizedBox(height: 10,),

          FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error"),
                  );
                }
                List<Event> eventList = snapshot.data ?? [];
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
      ),
    );
  }
}
