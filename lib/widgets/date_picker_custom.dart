import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

typedef OnDateSelected(date);

class DatePickerCustom extends StatefulWidget {
  final OnDateSelected onDateSelected;
  const DatePickerCustom({Key? key, required this.onDateSelected})
      : super(key: key);

  @override
  State<DatePickerCustom> createState() => _DatePickerCustomState();
}

class _DatePickerCustomState extends State<DatePickerCustom> {
  int selectedIndex = 0;
  DateTime currentDate = DateTime.now();
  DateTime selectedDate = DateTime.now();
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    selectedIndex = selectedDate.day - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: List.generate(
              DateTime(currentDate.year, currentDate.month + 1, 0).day,
              (index) {
                final dayName = DateFormat.EEEE(Platform.localeName).format(
                    DateTime(currentDate.year, currentDate.month, index + 1));
                return Padding(
                  padding: EdgeInsets.only(
                      left: (index == 0) ? 10.0 : 0.0,
                      right:
                          (DateTime(currentDate.year, currentDate.month + 1, 0)
                                      .day ==
                                  selectedIndex)
                              ? 10.0
                              : 0.0),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      selectedIndex = index;
                      selectedDate = DateTime(currentDate.year,
                          currentDate.month, selectedIndex + 1);
                      widget.onDateSelected(selectedDate);
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: selectedIndex == index
                            ? Colors.blue
                            : Colors.transparent,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 36.0,
                              width: 42.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(44.0),
                              ),
                              child: Text(
                                dayName.substring(0, 2),
                                style: TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              "${index + 1}",
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              height: 2.0,
                              width: 28.0,
                              color: selectedIndex == index
                                  ? Colors.blue
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
