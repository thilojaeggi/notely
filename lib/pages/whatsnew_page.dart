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
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor.withOpacity(0.96),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Column(children: [
          const SizedBox(
            height: 20,
          ),
          const Text(
            "Was ist neu?",
            textAlign: TextAlign.center,
            style: TextStyle(
              // Text Style Needed to Look like iOS 11
              fontSize: 46.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
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
                          FontAwesome5.graduation_cap,
                          size: 32,
                          color: Colors.blue.shade500,
                        ),
                      ],
                    ),
                    title: const Text(
                      'Performance Verbesserungen',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ), //Title is the only Required Item
                    subtitle: const Text(
                      'Es wurden mehrere Performance Verbesserungen vorgenommen, welche die App schneller machen.',
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const SizedBox(
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
              color: Colors.blue.shade500,
              minWidth: double.infinity,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Text(
                  "Ok",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }
}
