import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/Globals.dart' as Globals;

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int timeShift = 0;
  DateTime today = DateTime.now();

  @override
  initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    String school = prefs.getString("school") ?? "ksso";
    DateTime tomorrowDate = today.add(const Duration(days: 1));

    String currentDateFormatted = DateFormat('yyyy-MM-dd').format(today);
    String tomorrowDateFormatted =
        DateFormat('yyyy-MM-dd').format(tomorrowDate);

    String url =
        "https://kaschuso.so.ch/public/${school.toLowerCase()}/rest/v1/me/events?min_date=$currentDateFormatted&max_date=$tomorrowDateFormatted";
    print(url);
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {});
    } catch (e) {
      print(e.toString());
    }
    if (mounted) {
      setState(() {});
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
          initialSelectedDate: DateTime.now(),
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
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: 1,
              itemBuilder: (BuildContext ctxt, int index) {
                return Text("");
              }),
        ),
      ],
    );
  }
}
