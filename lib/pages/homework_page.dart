import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notely/Models/Homework.dart';
import 'package:notely/helpers/HomeworkDatabase.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage(
      {Key? key, required this.homeworkList, required this.callBack})
      : super(key: key);
  final List<Homework> homeworkList;
  final Function callBack;

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  bool isDone = false;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Homework> homeworkList = widget.homeworkList;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: new BoxDecoration(
        color: Theme.of(context).canvasColor.withOpacity(0.96),
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(16.0),
          topRight: const Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    // Make text full width
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      "Hausaufgaben",
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
              child: (homeworkList.isNotEmpty)
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: homeworkList.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        Homework homework = homeworkList[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(
                              bottom: 10, left: 10.0, right: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
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
                                          homeworkList[index]
                                              .lessonName
                                              .toString(),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      DateFormat("dd.MM.yyyy").format(
                                          DateTime.parse(homeworkList[index]
                                              .dueDate
                                              .toString())),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await HomeworkDatabase.instance
                                            .delete(homework.id);
                                        setState(() {
                                          homeworkList.removeAt(index);
                                        });
                                        widget.callBack(homeworkList);
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      iconSize: 32,
                                    ),
                                  ],
                                ),
                                Container(
                                    margin: const EdgeInsets.only(bottom: 15.0),
                                    height: 2.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                      borderRadius: BorderRadius.circular(8.0),
                                    )),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    homeworkList[index].title.toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          homeworkList[index]
                                              .details
                                              .toString(),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                    
                                  ],
                                ),
                                Align(
                                      alignment: Alignment.bottomRight,
                                      child: Transform.scale(
                                        scale: 1.7,
                                        child: Checkbox(
                                            value: homework.isDone,
                                            fillColor:
                                                MaterialStateProperty.all(
                                                    Theme.of(context)
                                                        .primaryColor),
                                            // Rounded checkbox
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            onChanged: (newVal) async {
                                              Homework updatedHomework =
                                                  homework.copyWith(
                                                      isDone: newVal!);
                                              await HomeworkDatabase.instance
                                                  .update(updatedHomework);

                                              setState(() {
                                                homeworkList[index] =
                                                    updatedHomework;
                                              });
                                              widget.callBack(homeworkList);
                                            }),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("😄", style: TextStyle(fontSize: 128),),
                          Text(
                            "Keine Hausaufgaben vorhanden!",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                              "Hausaufgaben kannst du hinzufügen, indem du auf eine zukünftige Lektion unter \"Plan\" tippst.",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )),
        ],
      ),
    );
  }
}
