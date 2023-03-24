import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notely/Globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../Models/Absence.dart';

class AbsencesPage extends StatefulWidget {
  const AbsencesPage({Key? key}) : super(key: key);

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  Future<List<Absence?>> getAbsences() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "ksso";
    String url = Globals().apiBase +
        school.toLowerCase() +
        "/rest/v1" +
        "/me/absencenotices";
    List<Absence> absenceList = <Absence>[];
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${Globals().accessToken}',
      }).then((response) {
        absenceList = (json.decode(response.body) as List)
            .reversed
            .map((i) => Absence.fromJson(i))
            .toList();
      });
    } catch (e) {
      print(e.toString());
    }
    return absenceList;
  }

  @override
  initState() {
    super.initState();
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
            child: FutureBuilder<List<Absence?>>(
                future: getAbsences(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error"),
                    );
                  }
                  List<Absence?>? absenceList = snapshot.data;
                  print(snapshot.data);
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: absenceList!.length,
                    itemBuilder: (BuildContext ctxt, int index) {
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(
                            bottom: 10, left: 10.0, right: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        shadowColor:
                            (absenceList.elementAt(index)!.status == "nz" ||
                                    absenceList.elementAt(index)!.status == "e")
                                ? Colors.blue
                                : Colors.red,
                        child: Container(
                          padding: EdgeInsets.only(
                              left: 7.0, right: 7.0, top: 2.0, bottom: 2.0),
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
                                        absenceList[index]!.course.toString(),
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
                                    DateFormat("dd.MM.yyyy").format(
                                        DateTime.parse(
                                            absenceList[index]!.date!)),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    absenceList[index]!
                                            .hourFrom
                                            .toString()
                                            .substring(
                                                0,
                                                absenceList[index]!
                                                        .hourFrom!
                                                        .toString()
                                                        .length -
                                                    3) +
                                        " - " +
                                        absenceList[index]!
                                            .hourTo
                                            .toString()
                                            .substring(
                                                0,
                                                absenceList[index]!
                                                        .hourTo!
                                                        .toString()
                                                        .length -
                                                    3),
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    (absenceList.elementAt(index)!.status ==
                                            "nz")
                                        ? 'Nicht zählend'
                                        : (absenceList
                                                    .elementAt(index)!
                                                    .status ==
                                                "e")
                                            ? 'Entschuldigt'
                                            : (absenceList
                                                        .elementAt(index)!
                                                        .status ==
                                                    "o")
                                                ? "Offen"
                                                : "Unbekannt",
                                    style: const TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}
