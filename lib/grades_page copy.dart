import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'Globals.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  bool _isLoading = true;
  List _subjects = List.empty(growable: true);
  final ScrollController _scrollController = ScrollController();

  void _scrollToSelectedContent({required GlobalKey expansionTileKey}) {
    final keyContext = expansionTileKey.currentContext;
    if (keyContext != null) {
      Future.delayed(Duration(milliseconds: 250)).then((value) {
        Scrollable.ensureVisible(keyContext,
            duration: Duration(milliseconds: 1000));
      });
    }
  }

  /*void getExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    String gradeList = await prefs.getString("gradeList") ?? "[]";
    _gradeList =
        (json.decode(gradeList) as List).map((i) => Grade.fromJson(i)).toList();
    setState(() {
      _groupedCoursesMap = _gradeList.groupBy((m) => m.subject);
      for (var i = 0; i < _groupedCoursesMap.length; i++) {
        double combinedGrade = 0;
        double combinedWeight = 0;
        for (var grade in _groupedCoursesMap.values.elementAt(i)) {
          combinedGrade = combinedGrade + (grade.mark * grade.weight);
          combinedWeight = combinedWeight + grade.weight;
        }
        _averageGradeMap.addAll({
          _groupedCoursesMap.keys.elementAt(i):
              (combinedGrade / combinedWeight).toStringAsFixed(3)
        });
      }
    });
  }*/

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    const storage = FlutterSecureStorage();
    String username = await storage.read(key: "username") as String;
    String password = await storage.read(key: "password") as String;
    String school = await prefs.getString("school") ?? "ksso";
    print(school);
    String url = Globals.apiBase +
        "grades?mandator=" +
        school.toLowerCase() +
        "&username=" +
        username +
        "&password=" +
        password;
    print(url);
    try {
      await http.get(Uri.parse(url)).then((response) {
        Map<String, dynamic> decoded = Map();
        decoded = jsonDecode(response.body);
        setState(() {
          _subjects = decoded['subjects'] as List;
        });
        print(_subjects.elementAt(0)['name']);
      });
    } catch (e) {
      print(e.toString());
    } /*
    _groupedCoursesMap = _gradeList.groupBy((m) => m.subject);
    for (var i = 0; i < _groupedCoursesMap.length; i++) {
      double combinedGrade = 0;
      double combinedWeight = 0;
      for (var grade in _groupedCoursesMap.values.elementAt(i)) {
        combinedGrade = combinedGrade + (grade.mark * grade.weight);
        combinedWeight = combinedWeight + grade.weight;
      }
      _averageGradeMap.addAll({
        _groupedCoursesMap.keys.elementAt(i):
            (combinedGrade / combinedWeight).toStringAsFixed(3)
      });
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    prefs.setString("gradeList", json.encode(_gradeList));*/
  }

  @override
  initState() {
    super.initState();
    // getExistingData();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            "Noten",
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.start,
          ),
        ),
        Expanded(
          child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _subjects.length,
              itemBuilder: (BuildContext ctxt, int index) {
                final GlobalKey expansionTileKey = GlobalKey();
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(
                      bottom: 10, left: 10.0, right: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  shadowColor: Colors.transparent.withOpacity(0.5),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: expansionTileKey,
                      onExpansionChanged: (isExpanded) {
                        if (isExpanded) {
                          _scrollToSelectedContent(
                              expansionTileKey: expansionTileKey);
                        }
                      },
                      title: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          _subjects.elementAt(index)['name'],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                      ),
                      trailing: Text(
                        "Ø " + _subjects.elementAt(index)['average'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0;
                                      i <
                                          _subjects
                                              .elementAt(index)['grades']
                                              .length;
                                      i++)
                                    Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      shadowColor: (double.parse(_subjects
                                                  .elementAt(index)['grades']
                                                  .reversed
                                                  .toList()[i]['value']) >=
                                              4.0)
                                          ? Colors.blue
                                          : Colors.red,
                                      clipBehavior: Clip.antiAlias,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: Text(
                                                      _subjects
                                                          .elementAt(
                                                              index)['grades']
                                                          .reversed
                                                          .toList()[i]['name'],
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  _subjects
                                                      .elementAt(index)[
                                                          'grades'][i]['value']
                                                      .toString(),
                                                  style: TextStyle(
                                                      color: (double.parse(_subjects
                                                                      .elementAt(index)[
                                                                          'grades']
                                                                      .reversed
                                                                      .toList()[i]
                                                                  ['value']) >=
                                                              4.0)
                                                          ? Colors.blue
                                                          : Colors.red,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w400),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Gewichtung: ${_subjects.elementAt(index)['grades'].reversed.toList()[i]['weighting']}",
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                                Text(
                                                  "${_subjects.elementAt(index)['grades'].reversed.toList()[i]['date']}",
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.only(
                                        right: 16, top: 16, bottom: 16),
                                    width: double.infinity,
                                    height: 200,
                                    child: LineChart(
                                      LineChartData(
                                          minY: 1.0,
                                          maxY: 6.0,
                                          titlesData: FlTitlesData(
                                            rightTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: false)),
                                            topTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: false)),
                                            leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    interval: 1,
                                                    showTitles: true)),
                                            bottomTitles: AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: false),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          gridData: FlGridData(
                                              horizontalInterval: 1,
                                              verticalInterval: 1),
                                          lineTouchData: LineTouchData(
                                            getTouchedSpotIndicator:
                                                (barData, spotIndexes) {
                                              return spotIndexes.map((index) {
                                                return TouchedSpotIndicatorData(
                                                  FlLine(
                                                      color: (barData.spots
                                                                  .elementAt(
                                                                      index)
                                                                  .y >=
                                                              4)
                                                          ? Colors.blueAccent
                                                          : Colors.redAccent,
                                                      strokeWidth: 4.0),
                                                  FlDotData(
                                                    show: true,
                                                  ),
                                                );
                                              }).toList();
                                            },
                                            touchTooltipData:
                                                LineTouchTooltipData(
                                              tooltipRoundedRadius: 8,
                                              getTooltipItems:
                                                  (List<LineBarSpot>
                                                      lineBarsSpot) {
                                                return lineBarsSpot
                                                    .map((lineBarSpot) {
                                                  return LineTooltipItem(
                                                    lineBarSpot.y.toString(),
                                                    TextStyle(
                                                        color: (lineBarSpot.y >=
                                                                4.0)
                                                            ? Colors.blueAccent
                                                            : Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  );
                                                }).toList();
                                              },
                                            ),
                                          ),
                                          lineBarsData: [
                                            LineChartBarData(
                                              dotData: FlDotData(
                                                show: true,
                                                getDotPainter: (spot, percent,
                                                        barData, index) =>
                                                    FlDotCirclePainter(
                                                  radius: 6,
                                                  color: (spot.y >= 4)
                                                      ? Colors.blueAccent
                                                      : Colors.redAccent,
                                                  strokeColor:
                                                      Colors.transparent,
                                                ),
                                              ),
                                              gradient: LinearGradient(
                                                  colors:
                                                      // This is really ugly, I know.
                                                      // TODO Make this prettier.
                                                      (_subjects
                                                                  .elementAt(index)[
                                                                      'grades']
                                                                  .toList()
                                                                  .length >
                                                              1)
                                                          ? [
                                                              for (var i = 0;
                                                                  i <
                                                                      _subjects
                                                                          .elementAt(index)[
                                                                              'grades']
                                                                          .length;
                                                                  i++)
                                                                (double.parse(_subjects.elementAt(index)['grades'].reversed.toList()[i]
                                                                            [
                                                                            'value']) >=
                                                                        4)
                                                                    ? Colors
                                                                        .blueAccent
                                                                    : Colors
                                                                        .redAccent
                                                            ]
                                                          : [
                                                              (double.parse(_subjects
                                                                          .elementAt(
                                                                              index)['grades']
                                                                          .reversed
                                                                          .toList()
                                                                          .toList()[0]['value']) >=
                                                                      4)
                                                                  ? Colors.blueAccent
                                                                  : Colors.redAccent,
                                                              (double.parse(_subjects
                                                                          .elementAt(
                                                                              index)['grades']
                                                                          .reversed
                                                                          .toList()
                                                                          .toList()[0]['value']) >=
                                                                      4)
                                                                  ? Colors.blueAccent
                                                                  : Colors.redAccent
                                                            ]),
                                              spots: [
                                                for (var i = 0;
                                                    i <
                                                        _subjects
                                                            .elementAt(
                                                                index)['grades']
                                                            .reversed
                                                            .toList()
                                                            .length;
                                                    i++)
                                                  FlSpot(
                                                    i.toDouble(),
                                                    double.parse(_subjects
                                                        .elementAt(
                                                            index)['grades']
                                                        .reversed
                                                        .toList()[i]['value']),
                                                  ),
                                              ],
                                            )
                                          ]),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              }),
        ),
      ],
    );
  }
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}

Color lerpGradient(List<Color> colors, List<double> stops, double t) {
  if (colors.isEmpty) {
    throw ArgumentError('"colors" is empty.');
  } else if (colors.length == 1) {
    return colors[0];
  }

  if (stops.length != colors.length) {
    stops = [];

    /// provided gradientColorStops is invalid and we calculate it here
    colors.asMap().forEach((index, color) {
      final percent = 1.0 / (colors.length - 1);
      stops.add(percent * index);
    });
  }

  for (var s = 0; s < stops.length - 1; s++) {
    final leftStop = stops[s], rightStop = stops[s + 1];
    final leftColor = colors[s], rightColor = colors[s + 1];
    if (t <= leftStop) {
      return leftColor;
    } else if (t < rightStop) {
      final sectionT = (t - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT)!;
    }
  }
  return colors.last;
}
