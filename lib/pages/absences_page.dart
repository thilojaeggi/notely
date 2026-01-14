import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/text_styles.dart';
import 'package:notely/models/absence.dart';

class AbsencesPage extends StatefulWidget {
  const AbsencesPage({Key? key}) : super(key: key);

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  final APIClient _apiClient = APIClient();
  late Future<List<Absence>> _absencesFuture;

  BoxDecoration _cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color:
          isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14.0),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  _StatusMeta _statusMeta(String status) {
    switch (status) {
      case "nz":
        return const _StatusMeta("Nicht zählend", Colors.blueAccent);
      case "e":
        return const _StatusMeta("Entschuldigt", Colors.green);
      case "o":
        return const _StatusMeta("Offen", Colors.orange);
      default:
        return const _StatusMeta("Unbekannt", Colors.redAccent);
    }
  }

  Future<List<Absence>> _loadAbsences(bool useCache) async {
    try {
      return await _apiClient.getAbsences(useCache);
    } catch (e) {
      debugPrint('Error loading absences: $e');
      return [];
    }
  }

  Future<void> _refreshAbsences() async {
    final latestAbsences = await _loadAbsences(false);
    if (!mounted) return;
    setState(() {
      _absencesFuture = Future.value(latestAbsences);
    });
  }

  @override
  initState() {
    super.initState();
    _absencesFuture = _loadAbsences(true);
    _refreshAbsences();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = pageTitleTextStyle(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: SafeArea(
          top: true,
          child: Text(
            "Absenzen",
            style: titleStyle,
            textAlign: TextAlign.start,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: FutureBuilder<List<Absence>>(
          future: _absencesFuture,
          builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text("Error"),
                );
              }

              List<Absence> absenceList =
                  (snapshot.data ?? []).reversed.toList();
              return Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: absenceList.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    final absence = absenceList[index];
                    // Skip if required fields are null
                    if (absence.date == null ||
                        absence.course == null ||
                        absence.hourFrom == null ||
                        absence.hourTo == null ||
                        absence.status == null) {
                      return const SizedBox.shrink();
                    }

                    final statusMeta = _statusMeta(absence.status!);
                    final theme = Theme.of(context);
                    final subtitleColor =
                        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7) ??
                            Colors.grey;
                    final timeRange =
                        "${absence.hourFrom!.substring(0, absence.hourFrom!.length - 3)} - ${absence.hourTo!.substring(0, absence.hourTo!.length - 3)}";

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      decoration: _cardDecoration(context),
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  absence.course ?? '',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat("dd.MM.yyyy")
                                    .format(DateTime.parse(absence.date!)),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: subtitleColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timeRange,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusMeta.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusMeta.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: statusMeta.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      
    );
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta(this.label, this.color);
}
