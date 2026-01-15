import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notely/helpers/api_client.dart';
import 'package:notely/helpers/grade_color.dart';
import 'package:notely/helpers/subscription_manager.dart';
import 'package:notely/models/exam.dart';
import 'package:notely/models/grade.dart';
import 'package:notely/models/homework.dart';
import 'package:notely/helpers/homework_database.dart';
import 'package:notely/models/student.dart';
import 'package:notely/pages/exams_page.dart';
import 'package:notely/pages/homework_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final APIClient _apiClient = APIClient();
  List<Exam> exams = <Exam>[];
  late Future<List<Homework>> homeworkFuture;

  List<Grade> _grades = <Grade>[];
  bool _gradesLoading = true;
  bool _gradesFailed = false;

  Student? _student;

  bool _examsLoading = true;
  bool _examsFailed = false;

  void _getGrades() async {
    try {
      final cachedGrades = await _apiClient.getGrades(true);
      if (!mounted) return;
      setState(() {
        _grades = cachedGrades;
        _gradesLoading = false;
        _gradesFailed = false;
      });

      final latestGrades = await _apiClient.getGrades(false);
      if (!mounted) return;
      setState(() {
        _grades = latestGrades;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gradesLoading = false;
        _gradesFailed = true;
      });
      debugPrint('Error loading grades: $e');
    }
  }

  void _getStudent() async {
    try {
      final cachedStudent = await _apiClient.getStudent(true);
      if (!mounted) return;
      setState(() {
        _student = cachedStudent;
      });

      final latestStudent = await _apiClient.getStudent(false);
      if (!mounted) return;
      setState(() {
        _student = latestStudent;
      });
      await _setAnalyticsProperties(latestStudent);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading student: $e');
    }
  }

  void _getExams() async {
    try {
      List<Exam> cachedExams = await _apiClient.getExams(true);
      cachedExams.sort((a, b) => a.startDate.compareTo(b.startDate));
      if (!mounted) return;
      setState(() {
        exams = cachedExams;
        _examsLoading = false;
        _examsFailed = false;
      });

      List<Exam> latestExams = await _apiClient.getExams(false);
      latestExams.sort((a, b) => a.startDate.compareTo(b.startDate));
      if (!mounted) return;
      setState(() {
        exams = latestExams;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _examsLoading = false;
        _examsFailed = true;
      });
      debugPrint('Error loading exams: $e');
    }
  }

  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  static const _iosNativeAdUnitId = 'ca-app-pub-2286905824384856/7515170733';
  static const _androidNativeAdUnitId =
      'ca-app-pub-2286905824384856/8660074907';

  String get _nativeAdUnitId {
    if (kIsWeb) return _androidNativeAdUnitId;
    if (kDebugMode)
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/3986624511'
          : 'ca-app-pub-3940256099942544/2247696110';
    return Platform.isIOS ? _iosNativeAdUnitId : _androidNativeAdUnitId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _loadNativeAdFor(brightness);
    }
  }

  Future<void> _loadNativeAdFor(Brightness brightness) async {
    // dispose old ad if any
    _nativeAd?.dispose();
    _nativeAd = null;
    _nativeAdIsLoaded = false;

    final isDark = brightness == Brightness.dark;

    final nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('NativeAd loaded.');
          if (!mounted) return;
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _nativeAdIsLoaded = false;
            _nativeAd = null;
          });
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 4.0,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white : Colors.black,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
      ),
    );

    _nativeAd = nativeAd;
    _nativeAd!.load();
  }

  List<Homework> homeworkList = <Homework>[];
  final Random random = Random();

  static const List<String> hellos = [
    "Hoi",
    "Sali",
    "Ciao",
    "Hallo",
    "Salut",
    "Hey",
  ];
  int randomHelloIndex = 0;

  void homeworkCallback(List<Homework> homework) {
    setState(() {
      homeworkList = homework;
    });
  }

  Future<void> _setAnalyticsProperties(Student student) async {
    final analytics = FirebaseAnalytics.instance;

    final school = await _getAnalyticsSchool();
    if (school == null) return;

    try {
      await analytics.setUserProperty(name: 'school', value: school);
      debugPrint("Set school property");
      await analytics.setDefaultEventParameters({'school': school});
    } catch (e) {
      debugPrint('Failed to set analytics school: $e');
    }
  }

  Future<String?> _getAnalyticsSchool() async {
    try {
      final school = _apiClient.school;
      if (school.trim().isEmpty) {
        return null;
      }
      debugPrint("School returned");

      return school.toLowerCase();
    } catch (e) {
      debugPrint('Failed to load school from api client for analytics: $e');
      return null;
    }
  }

  Future<List<Homework>> getHomework() async {
    List<Homework> homeworkList = await HomeworkDatabase.instance.readAll();
    homeworkList.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return homeworkList;
  }

  Brightness? _lastBrightness;

  @override
  initState() {
    super.initState();

    _getGrades();
    _getStudent();
    _getExams();

    homeworkFuture = getHomework();
    randomHelloIndex = random.nextInt(hellos.length);
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              children: [
                _buildGreetingHeader(),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 12),
                _buildNativeAd(),
                const SizedBox(height: 12),
                _buildGradesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader() {
    final textTheme = Theme.of(context).textTheme;
    final firstName = _student?.firstName.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${hellos[randomHelloIndex]} ${firstName ?? "..."}!",
          style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ) ??
              const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(child: _buildUpcomingExamsCard()),
        const SizedBox(width: 8.0),
        Expanded(child: kIsWeb ? Container() : _buildHomeworkCard()),
      ],
    );
  }

  Widget _buildUpcomingExamsCard() {
    Widget valueChild;
    if (_examsLoading && exams.isEmpty) {
      valueChild = const SizedBox(
        height: 36,
        width: 36,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_examsFailed) {
      valueChild = const Text(
        "–",
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
      );
    } else {
      final upcomingCount = exams
          .where((exam) => exam.startDate
              .isBefore(DateTime.now().add(const Duration(days: 14))))
          .length;
      valueChild = Text(
        upcomingCount.toString(),
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ) ??
            const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
            ),
      );
    }

    return _StatCard(
      icon: CupertinoIcons.calendar_today,
      title: "Tests demnächst",
      subtitle: "nächste 14 Tage",
      accentColor: Colors.orangeAccent,
      value: valueChild,
      onTap: _openExamsSheet,
    );
  }

  Widget _buildHomeworkCard() {
    return _StatCard(
      icon: CupertinoIcons.check_mark_circled,
      title: "Hausaufgaben",
      subtitle: "offen",
      accentColor: Colors.greenAccent[700],
      value: FutureBuilder<List<Homework>>(
          future: homeworkFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SizedBox(
                height: 36,
                width: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            } else if (snapshot.hasError) {
              return const Text("–",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600));
            }
            final homework = snapshot.data ?? [];
            final openCount = homework.where((item) => !item.isDone).length;
            return Text(
              openCount.toString(),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ) ??
                  const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
            );
          }),
      onTap: _openHomeworkSheet,
    );
  }

  Widget _buildGradesSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : theme.colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Neueste Noten",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (_gradesLoading && _grades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_gradesFailed)
            Text(
              "Noten konnten nicht geladen werden",
              style: theme.textTheme.bodyMedium,
            )
          else
            _buildGradesList(),
        ],
      ),
    );
  }

  Widget _buildGradesList() {
    final theme = Theme.of(context);
    final gradeList = (List<Grade>.from(_grades)
          ..sort((a, b) {
            final dateA = a.date;
            final dateB = b.date;
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          }))
        .take(7)
        .toList(growable: false);
    if (gradeList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          "Noch keine Noten vorhanden",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gradeList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildGradeTile(gradeList[index]),
    );
  }

  Widget _buildGradeTile(Grade grade) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65) ??
            Colors.grey;
    final badgeColor = gradeColor(grade);
    final markText = grade.mark?.toString() ?? "-";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  grade.title ?? "Ohne Titel",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  (grade.subject?.isNotEmpty ?? false)
                      ? grade.subject!
                      : (grade.course ?? ""),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "Note $markText",
              style: theme.textTheme.titleMedium?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeAd() {
    if (_nativeAd == null || !_nativeAdIsLoaded) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 110,
        ),
        child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: AdWidget(ad: _nativeAd!)),
      ),
    );
  }

  void _openExamsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExamsPage(
              examList: exams,
            ));
  }

  void _openHomeworkSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FutureBuilder<List<Homework>>(
            future: homeworkFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text("Error"),
                );
              }
              List<Homework> homework = snapshot.data!;
              return HomeworkPage(
                  homeworkList: homework, callBack: homeworkCallback);
            }));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onTap,
    this.accentColor,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget value;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : theme.colorScheme.surface;
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      letterSpacing: 0.2,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.textTheme.bodySmall?.color,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (accentColor ?? theme.colorScheme.primary)
                      .withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Icon(
                  icon,
                  color: accentColor ?? theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(title, style: titleStyle),
              const SizedBox(height: 8),
              value,
              Text(subtitle, style: subtitleStyle),
            ],
          ),
        ),
      ),
    );
  }
}
