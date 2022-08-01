import 'dart:convert';

import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Event.dart';
import '../config/Globals.dart' as Globals;

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int timeShift = 0;
  DateTime today = DateTime.now();
  List<Event> _eventList = List.empty(growable: true);

  @override
  initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    String school = prefs.getString("school") ?? "ksso";
    String dateFormatted = DateFormat('yyyy-MM-dd').format(today);

    String url =
        "https://kaschuso.so.ch/public/${school.toLowerCase()}/rest/v1/me/events?min_date=$dateFormatted&max_date=$dateFormatted";
    print(url);
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        print(response.body);
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
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 10.0, right: 10.0),
          child: DatePicker(
            DateTime.now(),
            initialSelectedDate: today,
            selectionColor: Colors.white.withOpacity(0.2),
            selectedTextColor: Colors.white,
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
        ),
        Expanded(
          child: (_eventList.length != 0)
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: _eventList.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    Event event = _eventList[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(
                          top: 5, bottom: 5, left: 10.0, right: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                          padding: EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.courseName.toString(),
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      event.teachers!.first.toString(),
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Column(
                                children: [
                                  Text(
                                    event.startDate!
                                        .substring(event.startDate!.length - 5),
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                  Text(
                                    event.endDate!
                                        .substring(event.startDate!.length - 5)
                                        .toString(),
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                event.roomToken.toString(),
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w500),
                              ),
                            ],
                          )),
                    );
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
