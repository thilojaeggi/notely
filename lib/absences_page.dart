import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:schulnetz/Absence.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AbsencesPage extends StatefulWidget {
  const AbsencesPage({Key? key}) : super(key: key);

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  List<dynamic> _absenceList = List.empty(growable: true);

  void getExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    String absences = await prefs.getString("absences") ?? "[]";
    setState(() {
      _absenceList = (json.decode(absences) as List)
          .map((i) => Absence.fromJson(i))
          .toList();
    });
  }

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    String _accessToken = prefs.getString('accessToken') ?? "";
    String school = prefs.getString("school") ?? "ksso";
    String url =
        "https://kaschuso.so.ch/public/${school.toLowerCase()}/rest/v1/me/absencenotices";
    print(url);
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $_accessToken',
      }).then((response) {
        print(response.body.toString());
        setState(() {
          _absenceList = (json.decode(response.body) as List)
              .reversed
              .map((i) => Absence.fromJson(i))
              .toList();
        });
      });
    } catch (e) {
      print(e.toString());
    }
    prefs.setString("absences", jsonEncode(_absenceList));
  }

  @override
  initState() {
    super.initState();
    getExistingData();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              "Absenzen",
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.start,
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _absenceList.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(
                      bottom: 10, left: 10.0, right: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  shadowColor: Colors.transparent.withOpacity(0.5),
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
                                  _absenceList[index].course.toString(),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Text(
                              _absenceList[index].date.toString(),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          _absenceList[index].hourFrom.toString() +
                              " - " +
                              _absenceList[index].hourTo.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
