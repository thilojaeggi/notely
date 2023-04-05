import 'package:flutter/material.dart';
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
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesome5.tachometer_alt,
                          size: 32,
                          color: Colors.blue.shade500,
                        ),
                      ],
                    ),
                    title: Text(
                      'Ladezeiten verringert',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ), //Title is the only Required Item
                    subtitle: Text(
                      'Die Ladezeiten in der ganzen App wurden verbessert und sie sollte nun auch schneller starten.',
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesome5.pen_nib,
                          size: 32,
                          color: Colors.blue.shade500,
                        ),
                      ],
                    ),
                    title: Text(
                      'Anpassung Startseite',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ), //Title is the only Required Item
                    subtitle: Text(
                      'Bei den neuesten Noten werden nun Testnamen grösser angezeigt und andere kleine Designänderungen wurden vorgenommen.',
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesome5.plus,
                          size: 32,
                          color: Colors.blue.shade500,
                        ),
                      ],
                    ),
                    title: Text(
                      'Manuelle Hausaufgaben',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ), //Title is the only Required Item
                    subtitle: Text(
                      'Hausaufgaben können nun auch manuell hinzugefügt werden auch ausserhalb des Stundenplans.\nZudem wurde die Darstellung überarbeitet.',
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  ListTile(
                    title: Text(
                      'Fehlerbehebungen:',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      children: [
                        ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesome5.bug,
                                size: 24,
                                color: Colors.blue.shade500,
                              ),
                            ],
                          ),
                          title: Text(
                            'Fehlerbehebung Startseite',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Auf der Startseite wurden fälschlicherweise Noten von alt nach neu dargestellt. ',
                            style: TextStyle(fontSize: 13.0),
                          ),
                        ),
                        ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesome5.bug,
                                size: 24,
                                color: Colors.blue.shade500,
                              ),
                            ],
                          ),
                          title: Text(
                            'Fehlerbehebung Login',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ), //Title is the only Required Item
                          subtitle: Text(
                            'Bei einigen Usern war es möglich dass man nicht angemeldet bleibt, dies sollte nun behoben sein.',
                            style: TextStyle(fontSize: 13.0),
                          ),
                        ),
                        ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesome5.bug,
                                size: 24,
                                color: Colors.blue.shade500,
                              ),
                            ],
                          ),
                          title: Text(
                            'Fehlerbehebung Hausaufgaben',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ), //Title is the only Required Item
                          subtitle: Text(
                            'Zeilenumbrüche in Hausaufgaben sollten nun korrekt dargestellt werden.',
                            style: TextStyle(fontSize: 13.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
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
