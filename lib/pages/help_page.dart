import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.only(
          topLeft: const Radius.circular(25.0),
          topRight: const Radius.circular(25.0),
        ),
        color: Color.fromARGB(255, 36, 36, 36).withOpacity(0.95),
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
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                shadowColor: Colors.transparent.withOpacity(0.5),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      "Anmeldung fehlgeschlagen?",
                      style: TextStyle(fontSize: 22.0),
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Text(
                          "Die Zugangsdaten sind dieselben wie auf der Kaschuso Website, überprüfe dass die richtige Schule gewählt ist und du dein Passwort richtig eingegeben hast.\nDein Benutzername ist normalerweise \"vorname.nachname\".",
                          style: TextStyle(fontSize: 18.0),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                shadowColor: Colors.transparent.withOpacity(0.5),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      "Erste Anmeldung geht nicht?",
                      style: TextStyle(fontSize: 22.0),
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Text(
                          "Falls du dich zum ersten mal anmeldest und es trotz richtigen Zugangsdaten nicht funktioniert, melde dich zuerst auf der Kaschuso Website bei \"schulnetz-mobile\" an.\nProbiere es danach erneut.",
                          style: TextStyle(fontSize: 18.0),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                shadowColor: Colors.transparent.withOpacity(0.5),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      "Bringt alles nichts?",
                      style: TextStyle(fontSize: 22.0),
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(14.0),
                        child: SelectableText(
                          "Kontaktiere mich unter thilo.jaeggi@ksso.ch",
                          style: TextStyle(fontSize: 18.0),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
