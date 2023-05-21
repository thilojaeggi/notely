import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notely/config/custom_scroll_behavior.dart';
import '../models/exam.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({Key? key, required this.examList}) : super(key: key);
  final List<Exam> examList;
  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  List<Exam> get examList => widget.examList;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor.withOpacity(0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            child: Row(
              children: [
                const Text(
                  "Tests",
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.start,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: (examList.isNotEmpty)
                ? ScrollConfiguration(
                    behavior: const CustomScrollBehavior(),
                    child: Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: examList.length,
                        itemBuilder: (BuildContext ctxt, int index) {
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(
                                bottom: 10, left: 10.0, right: 10.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
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
                                            examList[index]
                                                .courseName
                                                .toString(),
                                            style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Text(
                                        DateFormat("dd.MM.yyyy").format(
                                            DateTime.parse(examList[index]
                                                .startDate
                                                .toString())),
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            examList[index].text.toString(),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "😄",
                          style: TextStyle(fontSize: 128),
                        ),
                        Text(
                          "Keine Tests vorhanden!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                            "Tests werden automatisch aus dem Kaschuso ausgelesen.",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
