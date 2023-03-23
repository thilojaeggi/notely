import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:fluttericon/brandico_icons.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/fontelico_icons.dart';
import 'package:fluttericon/iconic_icons.dart';
import 'package:fluttericon/linecons_icons.dart';
import 'package:fluttericon/maki_icons.dart';
import 'package:fluttericon/mfg_labs_icons.dart';
import 'package:fluttericon/octicons_icons.dart';

class WhatsNew extends StatefulWidget {
  const WhatsNew({super.key, required this.school});
  final String school;

  @override
  State<WhatsNew> createState() => _WhatsNewState();
}

class _WhatsNewState extends State<WhatsNew> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: new BoxDecoration(
          color: Theme.of(context).canvasColor.withOpacity(0.96),
          borderRadius: new BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
          ),
        ),
        child: Column(children: [
          SizedBox(
            height: 20,
          ),
          Text(
            "Was ist neu?",
            textAlign: TextAlign.center,
            style: const TextStyle(
              // Text Style Needed to Look like iOS 11
              fontSize: 46.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesome5.bug,
                        size: 32,
                        color: Colors.blue.shade500,
                      ),
                    ],
                  ),
                  title: Text(
                    'Fehlerbehebung',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ), //Title is the only Required Item
                  subtitle: 
                      Text(
                        'Auf der Startseite wurden fälschlicherweise Noten von alt nach neu dargestellt. ',
                      ),
                ),
                SizedBox(
                  height: 20,
                ),
                ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesome5.tasks,
                        size: 32,
                        color: Colors.blue.shade500,
                      ),
                    ],
                  ),
                  title: Text(
                    'Hausaufgaben',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Du kannst nun auf eine Lektion im Stundenplan tippen um eine Hausaufgabe einzutragen.',
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                (widget.school.toLowerCase() == "ksso")
                    ? ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesome5.percent,
                              size: 32,
                              color: Colors.blue.shade500,
                            ),
                          ],
                        ),
                        title: Text(
                          'Promotionspunkte',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                            'Auf der Noten Seite werden dir nun deine Promotionspunkte angezeigt.'),
                      )
                    : SizedBox.shrink(),
                SizedBox(
                  height: 20,
                ),
                ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesome5.pencil_ruler,
                        size: 32,
                        color: Colors.blue.shade500,
                      ),
                    ],
                  ),
                  title: Text(
                    'Überarbeitete Startseite',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                      'Die Kacheln auf der Startseite wurden überarbeitet, tippe auf eine davon, um alle Tests/Hausaufgaben anzuzeigen.'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: MaterialButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  "Ok",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              color: Colors.blue.shade500,
              minWidth: double.infinity,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          )
        ]),
      ),
    );
  }
}
