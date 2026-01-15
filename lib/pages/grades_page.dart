import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/grade_color.dart';
import 'package:notely/helpers/text_styles.dart';
import 'package:shimmer/shimmer.dart';

import '../models/grade.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  double lowestGradePoints = 0.0;
  final ScrollController _scrollController = ScrollController();
  final APIClient _apiClient = APIClient();
  late Future<Map<String, dynamic>> _gradesFuture;

  void _scrollToSelectedContent({required GlobalKey expansionTileKey}) {
    final keyContext = expansionTileKey.currentContext;
    HapticFeedback.selectionClick();

    if (keyContext == null) return;

    final renderBox = keyContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewport = RenderAbstractViewport.of(renderBox);

    final revealOffset = viewport.getOffsetToReveal(renderBox, 0.0).offset;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 12.0;
    final targetOffset = (revealOffset - topInset).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    Future.delayed(const Duration(milliseconds: 250)).then((_) async {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;

      await _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  Color _gradeColor(double grade) {
    return gradeColor(Grade(mark: grade));
  }

  BoxDecoration _sharedCardDecoration(BuildContext context,
      {double radius = 12, Color? backgroundColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : theme.colorScheme.surface);
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(radius),
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
    );
  }

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
    double computedLowestGradePoints = 0;
    for (var i = 0; i < lowestValues.length; i++) {
      // Round lowestValues to 0.5
      computedLowestGradePoints += (lowestValues[i] * 2).round() / 2;
    }
    final roundedLowestPoints =
        double.parse(computedLowestGradePoints.toStringAsFixed(1));
    return {
      'groupedCoursesMap': groupedCoursesMap,
      'averageGradeMap': averageGradeMap,
      'lowestGradePoints': roundedLowestPoints,
    };
  }

  void _updateLowestGradePoints(double points) {
    if (!mounted) return;
    if (lowestGradePoints == points) return;
    setState(() {
      lowestGradePoints = points;
    });
  }

  Future<Map<String, dynamic>> _loadGrades(bool useCache) async {
    try {
      final grades = await _apiClient.getGrades(useCache);
      final data = _calculateGrades(grades);
      _updateLowestGradePoints(data['lowestGradePoints'] as double? ?? 0.0);
      return data;
    } catch (e) {
      debugPrint('Error loading grades: $e');
      return {};
    }
  }

  Future<void> _refreshGrades() async {
    final latestData = await _loadGrades(false);
    if (!mounted) return;
    setState(() {
      _gradesFuture = Future.value(latestData);
    });
  }

  @override
  initState() {
    super.initState();
    _gradesFuture = _loadGrades(true);
    _refreshGrades();
  }

  Widget _buildGradeCard(BuildContext context, int index, Map groupedCoursesMap,
      Map averageGradeMap) {
    final GlobalKey expansionTileKey = GlobalKey();
    const double cardRadius = 12.0;
    final borderRadius = BorderRadius.circular(cardRadius);
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 10.0, right: 10.0),
      decoration: _sharedCardDecoration(context, radius: cardRadius),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            collapsedShape: RoundedRectangleBorder(borderRadius: borderRadius),
            clipBehavior: Clip.antiAlias,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Text(
              "Ø ${averageGradeMap.values.elementAt(index)}",
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
                            i <
                                groupedCoursesMap.values
                                    .elementAt(index)
                                    .length;
                            i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: _sharedCardDecoration(
                              context,
                              radius: 10,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        groupedCoursesMap.values
                                                    .elementAt(index)[i]
                                                    .date !=
                                                null
                                            ? DateFormat("dd.MM.yyyy").format(
                                                groupedCoursesMap.values
                                                    .elementAt(index)[i]
                                                    .date!)
                                            : "-",
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
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.only(
                              right: 16, top: 16, bottom: 16),
                          width: double.infinity,
                          height: 200,
                          // make corners of container rounded
                          decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6)),

                          child: LineChart(
                            LineChartData(
                                minY: 1.0,
                                maxY: 6.0,
                                titlesData: const FlTitlesData(
                                  rightTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
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
                                gridData: const FlGridData(
                                    horizontalInterval: 1,
                                    verticalInterval: 0.5),
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
                                        const FlDotData(
                                          show: true,
                                        ),
                                      );
                                    }).toList();
                                  },
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBorderRadius:
                                        BorderRadius.circular(4),
                                    getTooltipColor: (lineBarSpot) =>
                                        Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade900,
                                    fitInsideHorizontally: true,
                                    tooltipPadding: const EdgeInsets.all(8.0),
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
                                                ]
                                              : [
                                                  _gradeColor(List.from(
                                                          groupedCoursesMap
                                                              .values
                                                              .elementAt(index))
                                                      .reversed
                                                      .toList()[0]
                                                      .mark!
                                                      .toDouble()),
                                                  _gradeColor(List.from(
                                                          groupedCoursesMap
                                                              .values
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
                                                                .elementAt(
                                                                    index)
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
                                                          .withValues(
                                                              alpha: 0.3)
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
                                                        .withValues(alpha: 0.3),
                                                    _gradeColor(List.from(
                                                                groupedCoursesMap
                                                                    .values
                                                                    .elementAt(
                                                                        index))
                                                            .reversed
                                                            .toList()[0]
                                                            .mark!
                                                            .toDouble())
                                                        .withValues(alpha: 0.3)
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = pageTitleTextStyle(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: SafeArea(
          top: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Noten",
                style: titleStyle,
                textAlign: TextAlign.start,
              ),
              const Spacer(),
              // Promotionspunkte moved into the AppBar
              if (_apiClient.school == "ksso")
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Promotionspunkte",
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    if (lowestGradePoints == 0.0)
                      Shimmer.fromColors(
                        baseColor: Theme.of(context).canvasColor,
                        highlightColor:
                            Theme.of(context).textTheme.bodyMedium!.color!,
                        child: const Text(
                          "..........",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      )
                    else
                      Text(
                        lowestGradePoints.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: lowestGradePoints >= 19
                              ? Colors.green
                              : Colors.red,
                        ),
                        textAlign: TextAlign.end,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),

      // Body is now only the scroll area
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gradesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final groupedCoursesMap = snapshot.data?['groupedCoursesMap'] ?? {};
            final averageGradeMap = snapshot.data?['averageGradeMap'] ?? {};

            return Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: groupedCoursesMap.length,
                itemBuilder: (ctxt, index) {
                  return _buildGradeCard(
                    ctxt,
                    index,
                    groupedCoursesMap,
                    averageGradeMap,
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}
