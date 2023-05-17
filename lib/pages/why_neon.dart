import 'package:flutter/material.dart';
import 'package:store_redirect/store_redirect.dart';

import '../config/CustomScrollBehavior.dart';

class WhyNeon extends StatefulWidget {
  const WhyNeon({Key? key}) : super(key: key);
  @override
  State<WhyNeon> createState() => _WhyNeonState();
}

class _WhyNeonState extends State<WhyNeon> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                FittedBox(
                  fit: BoxFit.contain,
                  child: const Text(
                    "Warum Werbung?",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.start,
                  ),
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
          ),
          Expanded(
              child: ScrollConfiguration(
            behavior: CustomScrollBehavior(),
            child: Scrollbar(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Create RichText with why notely needs financial support in german
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyText1,
                        children: const <TextSpan>[
                          TextSpan(
                            text: 'Notely ist eine kostenlose App, welche ',
                          ),
                          TextSpan(
                            text: ' auf finanzielle Unterstützung',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' angewiesen ist um weiter entwickelt zu werden und in den Stores verfügbar zu sein.',
                          ),
                          TextSpan(
                            text: '\n\n',
                          ),
                          TextSpan(
                              text:
                                  "Alleine dass Notely in den Stores erhältlich ist "),
                          TextSpan(
                            text: 'kostet jährlich 100 Fr.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' und die Entwicklung der App ist mit viel Aufwand von bereits mehreren Hundert Stunden verbunden.',
                          ),
                          TextSpan(
                            text: '\n\n',
                          ),
                          TextSpan(
                            text:
                                'Um Notely weiterhin anbieten und weiterentwickeln zu können, kannst du nun durch das erstellen eines',
                          ),
                          TextSpan(
                            text: ' kostenlosen Kontos ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: 'bei der '),
                          TextSpan(
                              style: TextStyle(fontWeight: FontWeight.bold),
                              text: 'Schweizer Bank '),
                          TextSpan(
                            text: 'neon Notely finanziell unterstützen. \n\n',
                          ),
                          TextSpan(
                            text:
                                'Für jedes erstellte Konto erhält Notely eine Provision von 10 Fr. und du erhältst gratis 10 Fr. auf dein Konto und zusätzlich eine prepaid MasterCard welche du überall einsetzen kannst.',
                          ),
                          TextSpan(
                            text: '\n\n',
                          ),
                          TextSpan(
                            text:
                                'Die Erstellung eines Kontos geht innert Minuten und ist kostenlos und unverbindlich. Du kannst das Konto jederzeit wieder kündigen falls du neon danach nicht mehr weiter verwenden möchtest.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                StoreRedirect.redirect(
                    androidAppId: "com.neonbanking.app",
                    iOSAppId: "1387883068");
              },
              child: const Text('neon installieren und Konto eröffnen'),
            ),
          ),
        ],
      ),
    );
  }
}
