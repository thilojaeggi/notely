import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:fluttericon/font_awesome5_icons.dart';

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
                child: Column(children: [
                  Text(
                    "Was ist neu?",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      // Text Style Needed to Look like iOS 11
                      fontSize: 46.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FontAwesome5.bell, size: 32),
                      ],
                    ),
                    title: Text(
                      'Benachrichtigungen',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ), //Title is the only Required Item
                    subtitle: Text(
                      'Bei einer neuen Note erhältst du nun automatisch eine Benachrichtigung sofern du die Berechtigung akzeptierst.',
                    ),
                  ),
                  ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesome5.tasks,
                          size: 32,
                        ),
                      ],
                    ),
                    title: Text(
                      'Hausaufgaben',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Du kannst nun auf eine Lektion im Stundenplan tippen um eine Hausaufgabe einzutragen.',
                    ),
                  ),
                  (widget.school.toLowerCase() == "ksso")
                      ? ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesome5.percent,
                                size: 32,
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
                  ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesome5.pencil_ruler,
                          size: 32,
                        ),
                      ],
                    ),
                    title: Text(
                      'Überarbeitete Startseite',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                        'Die Kacheln auf der Startseite wurden überarbeitet, tippe auf eine davon, um alle Tests/Hausaufgaben anzuzeigen.'),
                  ),
                  Spacer(),
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