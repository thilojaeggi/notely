import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:shimmer/shimmer.dart';

import '../models/grade.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  Color goodEnough = Colors.orange;
  Color good = Color.fromARGB(255, 0, 110, 255);
  Color bad = Color.fromARGB(255, 255, 33, 46);
  double lowestGradePoints = 0.0;
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

  Color _gradeColor(double grade) {
    if (grade >= 4.5) {
      return good;
    } else if (grade >= 4) {
      return goodEnough;
    } else {
      return bad;
    }
  }

  final StreamController<Map<String, dynamic>> _gradesStreamController =
      StreamController<Map<String, dynamic>>();

  Map<String, dynamic> _calculateGrades(List<Grade> gradeList) {
    var groupedCoursesMap = gradeList.groupBy((m) => m.subject);
    final averageGradeMap = {};
    for (var i = 0; i < groupedCoursesMap.length; i++) {
      double combinedGrade = 0;
      double combinedWeight = 0;
      for (var grade in groupedCoursesMap.values.elementAt(i)) {
        combinedGrade = combinedGrade + (grade.mark! * grade.weight!);
        combinedWeight += grade.weight!;
      }

      averageGradeMap.addAll({
        groupedCoursesMap.keys.elementAt(i):
            (combinedGrade / combinedWeight).toStringAsFixed(3)
      });
    }
    final lowestAverages = averageGradeMap.values
        .map((value) => double.parse(value))
        .toList()
      ..sort();
    final numLowest = min(5, averageGradeMap.length);
    final lowestValues = lowestAverages.take(numLowest).toList();
    lowestGradePoints = 0;
    for (var i = 0; i < lowestValues.length; i++) {
      // Round lowestValues to 0.5
      lowestGradePoints += (lowestValues[i] * 2).round() / 2;
    }
    setState(() {
      lowestGradePoints = double.parse(lowestGradePoints.toStringAsFixed(1));
    });
    return {
      'groupedCoursesMap': groupedCoursesMap,
      'averageGradeMap': averageGradeMap,
      'lowestGradePoints': lowestGradePoints,
    };
  }

  void _getGrades() async {
    if (!mounted) return;
    try {
      final cachedGrades = await APIClient().getGrades(true);
      _gradesStreamController.add(_calculateGrades(cachedGrades));
      final newGrades = await APIClient().getGrades(false);
      _gradesStreamController.add(_calculateGrades(newGrades));
    } catch (e) {
      // Handle the StateError here
      debugPrint('Error adding event to stream controller: $e');
    }
  }

  @override
  void dispose() {
    _gradesStreamController.close();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _getGrades();
  }

  Widget _buildGradeCard(BuildContext context, int index, Map groupedCoursesMap,
      Map averageGradeMap) {
    final GlobalKey expansionTileKey = GlobalKey();
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 10, left: 10.0, right: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
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
              groupedCoursesMap.keys.elementAt(index),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Text(
            "Ø " + averageGradeMap.values.elementAt(index),
            style: const TextStyle(fontSize: 22),
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
                          i < groupedCoursesMap.values.elementAt(index).length;
                          i++)
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          shadowColor: _gradeColor(groupedCoursesMap.values
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
                                          groupedCoursesMap.values
                                              .elementAt(index)[i]
                                              .title,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      groupedCoursesMap.values
                                          .elementAt(index)[i]
                                          .mark
                                          .toString(),
                                      style: TextStyle(
                                          color: _gradeColor(groupedCoursesMap
                                              .values
                                              .elementAt(index)[i]
                                              .mark
                                              .toDouble()),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Gewichtung: ${groupedCoursesMap.values.elementAt(index)[i].weight}",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      DateFormat("dd.MM.yyyy").format(
                                          DateTime.parse(groupedCoursesMap
                                              .values
                                              .elementAt(index)[i]
                                              .date)),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(
                            right: 16, top: 16, bottom: 16),
                        width: double.infinity,
                        height: 200,
                        // make corners of container rounded
                        decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade900
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(6)),

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
                                  horizontalInterval: 1, verticalInterval: 0.5),
                              lineTouchData: LineTouchData(
                                getTouchedSpotIndicator:
                                    (barData, spotIndexes) {
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                        color: _gradeColor(
                                            barData.spots.elementAt(index).y),
                                        strokeWidth: 4.0,
                                      ),
                                      FlDotData(
                                        show: true,
                                      ),
                                    );
                                  }).toList();
                                },
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipRoundedRadius: 4,
                                  tooltipBgColor:
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade900,
                                  fitInsideHorizontally: true,
                                  tooltipPadding: EdgeInsets.all(8.0),
                                  getTooltipItems:
                                      (List<LineBarSpot> lineBarsSpot) {
                                    return lineBarsSpot.map((lineBarSpot) {
                                      return LineTooltipItem(
                                        lineBarSpot.y.toString(),
                                        TextStyle(
                                            color: _gradeColor(lineBarSpot.y),
                                            fontWeight: FontWeight.bold),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                    barWidth: 5,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter:
                                          (spot, percent, barData, index) =>
                                              FlDotCirclePainter(
                                        radius: 6,
                                        color: _gradeColor(spot.y),
                                        strokeColor: Colors.transparent,
                                      ),
                                    ),
                                    gradient: LinearGradient(
                                        colors: (groupedCoursesMap.values
                                                    .elementAt(index)
                                                    .toList()
                                                    .length >
                                                1)
                                            ? [
                                                for (var i = 0;
                                                    i <
                                                        groupedCoursesMap.values
                                                            .elementAt(index)
                                                            .length;
                                                    i++)
                                                  _gradeColor(List.from(
                                                          groupedCoursesMap
                                                              .values
                                                              .elementAt(index))
                                                      .reversed
                                                      .toList()[i]
                                                      .mark!
                                                      .toDouble())
                                              ]
                                            : [
                                                _gradeColor(List.from(
                                                        groupedCoursesMap.values
                                                            .elementAt(index))
                                                    .reversed
                                                    .toList()[0]
                                                    .mark!
                                                    .toDouble()),
                                                _gradeColor(List.from(
                                                        groupedCoursesMap.values
                                                            .elementAt(index))
                                                    .reversed
                                                    .toList()[0]
                                                    .mark!
                                                    .toDouble())
                                              ]),
                                    spots: [
                                      for (var i = 0;
                                          i <
                                              groupedCoursesMap.values
                                                  .elementAt(index)
                                                  .length;
                                          i++)
                                        FlSpot(
                                          i.toDouble(),
                                          List.from(groupedCoursesMap.values
                                                  .elementAt(index))
                                              .reversed
                                              .toList()[i]
                                              .mark!
                                              .toDouble(),
                                        ),
                                    ],
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                          colors: (groupedCoursesMap.values
                                                      .elementAt(index)
                                                      .toList()
                                                      .length >
                                                  1)
                                              ? [
                                                  for (var i = 0;
                                                      i <
                                                          groupedCoursesMap
                                                              .values
                                                              .elementAt(index)
                                                              .length;
                                                      i++)
                                                    _gradeColor(List.from(
                                                                groupedCoursesMap
                                                                    .values
                                                                    .elementAt(
                                                                        index))
                                                            .reversed
                                                            .toList()[i]
                                                            .mark!
                                                            .toDouble())
                                                        .withOpacity(0.3)
                                                ]
                                              : [
                                                  _gradeColor(List.from(
                                                              groupedCoursesMap
                                                                  .values
                                                                  .elementAt(
                                                                      index))
                                                          .reversed
                                                          .toList()[0]
                                                          .mark!
                                                          .toDouble())
                                                      .withOpacity(0.3),
                                                  _gradeColor(List.from(
                                                              groupedCoursesMap
                                                                  .values
                                                                  .elementAt(
                                                                      index))
                                                          .reversed
                                                          .toList()[0]
                                                          .mark!
                                                          .toDouble())
                                                      .withOpacity(0.3)
                                                ]),
                                    ))
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
        Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Noten",
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.start,
              ),
              SizedBox(
                width: 10,
              ),
              (APIClient().school == "ksso")
                  ? (lowestGradePoints == 0.0)
                      ? Padding(
                          padding:
                              const EdgeInsets.only(right: 10.0, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Promotionspunkte"),
                              Shimmer.fromColors(
                                child: Text(
                                  "..........",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                                baseColor: Theme.of(context).canvasColor,
                                highlightColor: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!,
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding:
                              const EdgeInsets.only(right: 10.0, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("Promotionspunkte"),
                              Text(
                                "${lowestGradePoints.toString()}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  color: lowestGradePoints >= 19
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        )
                  : SizedBox.shrink(),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<Map<String, dynamic>>(
              stream: _gradesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  final groupedCoursesMap =
                      snapshot.data?['groupedCoursesMap'] ?? {};
                  final averageGradeMap =
                      snapshot.data?['averageGradeMap'] ?? {};

                  return Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: groupedCoursesMap.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          return _buildGradeCard(
                            ctxt,
                            index,
                            groupedCoursesMap,
                            averageGradeMap,
                          );
                        }),
                  );
                }
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
