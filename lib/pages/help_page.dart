import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);

  static const Map<String, String> helpItems = {
    "Anmeldung fehlgeschlagen?":
        "Die Zugangsdaten sind dieselben wie auf der Kaschuso Website, überprüfe dass die richtige Schule gewählt ist und du dein Passwort richtig eingegeben hast.\nDein Benutzername ist normalerweise \"vorname.nachname\".",
    "Erste Anmeldung geht nicht?":
        "Falls du dich zum ersten mal anmeldest und es trotz richtigen Zugangsdaten nicht funktioniert, melde dich zuerst auf der Kaschuso Website bei \"schulnetz-mobile\" an.\nProbiere es danach erneut.",
    "Bringt alles nichts?": "Kontaktiere mich unter thilo.jaeggi@ksso.ch",
  };

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  Widget helpCard(BuildContext context, String problem, String answer) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.transparent.withOpacity(0.5),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            problem,
            style: TextStyle(fontSize: 22.0),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(14.0),
              child: Text(
                answer,
                style: TextStyle(fontSize: 18.0),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(16.0),
          topRight: const Radius.circular(16.0),
        ),
          color: Theme.of(context).canvasColor.withOpacity(0.96),
      ),
      child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Hilfe",
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
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: HelpPage.helpItems.length,
                  itemBuilder: (BuildContext context, int index) {
                    return helpCard(
                        context,
                        HelpPage.helpItems.keys.elementAt(index),
                        HelpPage.helpItems.values.elementAt(index));
                  },
                ),
              ),
            ],
          )),
    );
  }
}
