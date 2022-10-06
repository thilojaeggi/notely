import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Models/Grade.dart';
import '../Globals.dart' as Globals;

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<Grade> _gradeList = List.empty(growable: true);
  Map _groupedCoursesMap = Map();
  Map _averageGradeMap = Map();
  Color goodEnough = Colors.orange;
  Color good = Colors.blueAccent;
  Color bad = Colors.redAccent;
  late double targetGrade;

  final ScrollController _scrollController = ScrollController();

  void _scrollToSelectedContent({required GlobalKey expansionTileKey}) {
    final keyContext = expansionTileKey.currentContext;
    HapticFeedback.selectionClick();

    if (keyContext != null) {
      Future.delayed(Duration(milliseconds: 250)).then((value) async {
        await Scrollable.ensureVisible(keyContext,
            duration: Duration(milliseconds: 1000));
      });
    }
  }

  Color gradeColor(double grade) {
    if (grade >= 4.5) {
      return good;
    } else if (grade >= 4) {
      return goodEnough;
    } else {
      return bad;
    }
  }

  Future<void> getGrades() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "ksso";
    String url =
        Globals.apiBase + school.toLowerCase() + "/rest/v1" + "/me/grades";
    if (Globals.debug) {
      url = "https://api.mocki.io/v2/e3516d96/grades";
    }
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        _gradeList = (json.decode(response.body) as List)
            .map((i) => Grade.fromJson(i))
            .toList();
      });
    } catch (e) {
      print(e.toString());
    }
    if (mounted) {
      setState(() {
        _groupedCoursesMap = _gradeList.groupBy((m) => m.subject);
        for (var i = 0; i < _groupedCoursesMap.length; i++) {
          double combinedGrade = 0;
          double combinedWeight = 0;
          for (var grade in _groupedCoursesMap.values.elementAt(i)) {
            combinedGrade = combinedGrade + (grade.mark * grade.weight);
            combinedWeight += grade.weight;
          }

          _averageGradeMap.addAll({
            _groupedCoursesMap.keys.elementAt(i):
                (combinedGrade / combinedWeight).toStringAsFixed(3)
          });
        }
      });
    }
    prefs.setString("gradeList", json.encode(_gradeList));
  }

  @override
  initState() {
    super.initState();
    getGrades();
  }

  Widget _buildGradeCard(BuildContext context, int index) {
    final GlobalKey expansionTileKey = GlobalKey();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 10, left: 10.0, right: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.transparent.withOpacity(0.5),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: expansionTileKey,
          onExpansionChanged: (isExpanded) {
            if (isExpanded) {
              _scrollToSelectedContent(expansionTileKey: expansionTileKey);
            }
          },
          title: Padding(
            padding: const EdgeInsets.all(5),
            child: Text(
              _groupedCoursesMap.keys.elementAt(index),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Text(
            "Ø " + _averageGradeMap.values.elementAt(index),
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
                      /* Padding(
                        padding: const EdgeInsets.only(left: 7.0),
                        child: Text(
                          "Note benötigt für Ø $targetGrade: ",
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),*/
                      for (var i = 0;
                          i < _groupedCoursesMap.values.elementAt(index).length;
                          i++)
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          shadowColor: gradeColor(_groupedCoursesMap.values
                              .elementAt(index)[i]
                              .mark
                              .toDouble()),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          _groupedCoursesMap.values
                                              .elementAt(index)[i]
                                              .title,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      _groupedCoursesMap.values
                                          .elementAt(index)[i]
                                          .mark
                                          .toString(),
                                      style: TextStyle(
                                          color: gradeColor(_groupedCoursesMap
                                              .values
                                              .elementAt(index)[i]
                                              .mark
                                              .toDouble()),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Gewichtung: ${_groupedCoursesMap.values.elementAt(index)[i].weight}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      DateFormat("dd.MM.yyyy").format(
                                          DateTime.parse(_groupedCoursesMap
                                              .values
                                              .elementAt(index)[i]
                                              .date)),
                                      style: const TextStyle(fontSize: 16),
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
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        interval: 1, showTitles: true)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: false,
                              ),
                              gridData: FlGridData(
                                  horizontalInterval: 1, verticalInterval: 1),
                              lineTouchData: LineTouchData(
                                getTouchedSpotIndicator:
                                    (barData, spotIndexes) {
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                          color: gradeColor(
                                              barData.spots.elementAt(index).y),
                                          strokeWidth: 4.0),
                                      FlDotData(
                                        show: true,
                                      ),
                                    );
                                  }).toList();
                                },
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipRoundedRadius: 8,
                                  fitInsideHorizontally: true,
                                  tooltipPadding: EdgeInsets.all(8.0),
                                  getTooltipItems:
                                      (List<LineBarSpot> lineBarsSpot) {
                                    return lineBarsSpot.map((lineBarSpot) {
                                      return LineTooltipItem(
                                        lineBarSpot.y.toString(),
                                        TextStyle(
                                            color: gradeColor(lineBarSpot.y),
                                            fontWeight: FontWeight.bold),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                      radius: 6,
                                      color: gradeColor(spot.y),
                                      strokeColor: Colors.transparent,
                                    ),
                                  ),
                                  gradient: LinearGradient(
                                      colors: (_groupedCoursesMap.values
                                                  .elementAt(index)
                                                  .toList()
                                                  .length >
                                              1)
                                          ? [
                                              for (var i = 0;
                                                  i <
                                                      _groupedCoursesMap.values
                                                          .elementAt(index)
                                                          .length;
                                                  i++)
                                                gradeColor(List.from(
                                                        _groupedCoursesMap
                                                            .values
                                                            .elementAt(index))
                                                    .reversed
                                                    .toList()[i]
                                                    .mark!
                                                    .toDouble())
                                            ]
                                          : [
                                              gradeColor(List.from(
                                                      _groupedCoursesMap.values
                                                          .elementAt(index))
                                                  .reversed
                                                  .toList()[0]
                                                  .mark!
                                                  .toDouble()),
                                              gradeColor(List.from(
                                                      _groupedCoursesMap.values
                                                          .elementAt(index))
                                                  .reversed
                                                  .toList()[0]
                                                  .mark!
                                                  .toDouble())
                                            ]),
                                  spots: [
                                    for (var i = 0;
                                        i <
                                            _groupedCoursesMap.values
                                                .elementAt(index)
                                                .length;
                                        i++)
                                      FlSpot(
                                        i.toDouble(),
                                        List.from(_groupedCoursesMap.values
                                                .elementAt(index))
                                            .reversed
                                            .toList()[i]
                                            .mark!
                                            .toDouble(),
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
              itemCount: _groupedCoursesMap.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return _buildGradeCard(
                  ctxt,
                  index,
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
