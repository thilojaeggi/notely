import 'dart:io';

import 'package:flutter/cupertino.dart';
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
                  (Platform.isIOS)
                      ? ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.app_badge_fill,
                                size: 32,
                                color: Colors.blue.shade500,
                              ),
                            ],
                          ),
                          title: Text(
                            'App Icon ändern',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ), //Title is the only Required Item
                          subtitle: Text(
                            'Das App Icon kann nun in den Einstellungen geändert werden.',
                          ),
                        )
                      : SizedBox.shrink(),
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
                            'Fehlerbehebung Tests',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Fälschlicherweise wurden Tests nicht mehr nach Datum sortiert.',
                            style: TextStyle(fontSize: 13.0),
                          ),
                        ),
                        (widget.school == "ksso")
                            ? ListTile(
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
                                  'Fehlerbehebung Promotionspunkte',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ), //Title is the only Required Item
                                subtitle: Text(
                                  'Die Promotionspunkte wurden nicht mehr angezeigt, sollten nun wieder angezeigt und mittels gerundeten Noten berechnet werden.',
                                  style: TextStyle(fontSize: 13.0),
                                ),
                              )
                            : SizedBox.shrink(),

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
