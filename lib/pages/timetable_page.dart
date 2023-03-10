import 'dart:convert';
import 'dart:math';

import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Event.dart';
import '../Globals.dart' as Globals;

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
    String url = Globals.apiBase +
        school.toLowerCase() +
        "/rest/v1" +
        "/me/events?min_date=$dateFormatted&max_date=$dateFormatted";
    print(url);
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        if (mounted) {
          setState(() {
            _eventList = (json.decode(response.body) as List)
                .map((i) => Event.fromJson(i))
                .toList();
          });
        }
      });
    } catch (e) {
      print(e.toString());
    }
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
                "Plan",
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.start,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd.MM.yyyy').format(today).toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        DatePicker(
          DateTime.now(),
          height: 90,
          initialSelectedDate: today,
          selectionColor: Globals.isDark
              ? Color.fromARGB(255, 46, 46, 46)
              : Colors.grey.withOpacity(0.2),
          selectedTextColor: Globals.isDark ? Colors.white : Colors.black,
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
        ),
        Expanded(
          child: (_eventList.length != 0)
              ? Stack(
                  children: [
                    ListView.builder(
                        shrinkWrap: true,
                        itemCount: _eventList.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          Event event = _eventList[index];
                          return LayoutBuilder(builder: (BuildContext context,
                              BoxConstraints constraints) {
                                
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(
                                  top: 5, bottom: 5, left: 10.0, right: 10.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  if (Globals.debug) {
                                    showToast(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: 32.0),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12.0),
                                          ),
                                        ),
                                        padding: EdgeInsets.all(6.0),
                                        child: Text(
                                          "Tapped",
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
                                child: Container(
                                    padding: EdgeInsets.only(
                                        left: 7.0,
                                        right: 7.0,
                                        top: 2.0,
                                        bottom: 2.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.courseName.toString(),
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                    fontSize: 23,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              Text(
                                                event.teachers!.first
                                                    .toString(),
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  height: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          event.roomToken.toString(),
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              event.startDate!.substring(
                                                  event.startDate!.length - 5),
                                              style: TextStyle(fontSize: 18.0),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "-",
                                              style: TextStyle(fontSize: 18.0),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              event.endDate!
                                                  .substring(
                                                      event.startDate!.length -
                                                          5)
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 18.0,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ],
                                    )),
                              ),
                            );
                          });
                        }),
                    Positioned(
                      top: currentTime * 200,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: Colors.red,
                      ),
                    ),
                  ],
                )
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
