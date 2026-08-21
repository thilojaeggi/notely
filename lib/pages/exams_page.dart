import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:notely/core/analytics/analytics_service.dart';
import 'package:notely/features/home/helpers/text_styles.dart';
import 'package:notely/features/subscription/subscription_manager.dart';
import '../models/exam.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({Key? key, required this.examList}) : super(key: key);
  final List<Exam> examList;
  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  List<Exam> get examList => widget.examList;
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  final Random _random = Random();
  int _nativeAdIndex = 0;

  static const _iosNativeAdUnitId = 'ca-app-pub-2286905824384856/4589637803';
  static const _androidNativeAdUnitId =
      'ca-app-pub-2286905824384856/8660074907';

  String get _nativeAdUnitId {
    if (kIsWeb) return _androidNativeAdUnitId;
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/3986624511'
          : 'ca-app-pub-3940256099942544/2247696110';
    }
    return Platform.isIOS ? _iosNativeAdUnitId : _androidNativeAdUnitId;
  }

  Brightness? _lastBrightness;

  void _onPremiumChanged() {
    if (SubscriptionManager().isPremium) {
      _nativeAd?.dispose();
      _nativeAd = null;
      _nativeAdIsLoaded = false;
      _nativeAdIndex = -1;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService().logExamsOverviewViewed(count: widget.examList.length);
    SubscriptionManager().isPremiumListenable.addListener(_onPremiumChanged);
    _updateNativeAdIndex(widget.examList.length);
  }

  @override
  void dispose() {
    SubscriptionManager().isPremiumListenable.removeListener(_onPremiumChanged);
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExamsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.examList.length != widget.examList.length) {
      _updateNativeAdIndex(widget.examList.length);
    }
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

  void _updateNativeAdIndex(int length) {
    if (length <= 0 || SubscriptionManager().isPremium) {
      _nativeAdIndex = -1;
      return;
    }
    _nativeAdIndex = _random.nextInt(length + 1);
  }

  Future<void> _loadNativeAdFor(Brightness brightness) async {
    if (SubscriptionManager().isPremium) return;

    // dispose old ad if any
    _nativeAd?.dispose();
    _nativeAd = null;
    _nativeAdIsLoaded = false;

    final isDark = brightness == Brightness.dark;

    final nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('NativeAd loaded in exams sheet.');
          if (!mounted) return;
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd in exams sheet failed to load: $error');
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
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 4.0,
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white : Colors.black,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.black.withValues(alpha: 0.7),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.5),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 10.0,
        ),
      ),
    );

    _nativeAd = nativeAd;
    _nativeAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color subtitleColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.6);
    final titleStyle = pageTitleTextStyle(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: (examList.isNotEmpty)
                  ? Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          top: 68,
                          bottom: MediaQuery.of(context).padding.bottom + 24,
                        ),
                        itemCount:
                            examList.length + (_nativeAdIndex >= 0 ? 1 : 0),
                        itemBuilder: (BuildContext ctxt, int index) {
                          final bool hasAdSlot = _nativeAdIndex >= 0;
                          final int adIndex =
                              hasAdSlot ? _nativeAdIndex : examList.length;

                          if (hasAdSlot && index == adIndex) {
                            return _buildNativeAd();
                          }

                          final int examIndex =
                              hasAdSlot && index > adIndex ? index - 1 : index;
                          return _buildExamCard(
                            exam: examList[examIndex],
                            subtitleColor: subtitleColor,
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.doc_checkmark,
                              size: 72,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Keine Tests vorhanden!",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Eingetragene Prüfungen werden hier und im Stundenplan automatisch angezeigt.",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16.0, 10.0, 8.0, 10.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .canvasColor
                          .withValues(alpha: isDarkMode ? 0.75 : 0.7),
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Tests",
                            style: titleStyle,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                          child: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: (isDarkMode ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.xmark,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAd() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardColor =
        isDark ? const Color(0xFF1C1C1E) : Colors.white;
    if (SubscriptionManager().isPremium || _nativeAd == null || !_nativeAdIsLoaded) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320,
          maxHeight: 350,
          maxWidth: 450,
        ),
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: AdWidget(ad: _nativeAd!))),
      ),
    );
  }

  Widget _buildExamCard({
    required Exam exam,
    required Color subtitleColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime start = exam.startDate.toLocal();
    final DateTime end = exam.endDate.toLocal();
    final String? comment = _cleanText(exam.comment);
    final String? teacherInfo = _cleanText(exam.teachers?.join(', '));
    final String? room = _cleanText(exam.roomToken ?? exam.roomId);
    final String examTitle = _cleanText(exam.text) ??
        _cleanText(exam.courseToken) ??
        exam.courseName;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime examDay = DateTime(start.year, start.month, start.day);
    final int diffDays = examDay.difference(today).inDays;

    final bool isToday = diffDays == 0;
    final bool isTomorrow = diffDays == 1;
    final bool isUpcomingSoon = diffDays > 1 && diffDays <= 7;

    final Color dateBadgeColor = isToday
        ? const Color(0xFFFF9500)
        : isTomorrow
            ? const Color(0xFFFF2D55)
            : isUpcomingSoon
                ? Colors.blueAccent
                : (isDark ? Colors.white70 : const Color(0xFF636366));

    final String dateBadgeText = isToday
        ? "Heute · ${DateFormat("dd. MMM", 'de_CH').format(start)}"
        : isTomorrow
            ? "Morgen · ${DateFormat("dd. MMM", 'de_CH').format(start)}"
            : DateFormat("EEE, dd. MMM", 'de_CH').format(start);

    final String timeRange =
        "${DateFormat("HH:mm").format(start)} - ${DateFormat("HH:mm").format(end)}";

    final Color cardColor =
        isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.doc_text_fill,
                      size: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      exam.courseName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (isToday || isTomorrow || isUpcomingSoon)
                      ? dateBadgeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 11.5,
                      color: dateBadgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateBadgeText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: dateBadgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            examTitle,
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.035)
                  : Colors.black.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 13,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeRange,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (room != null || teacherInfo != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (room != null) ...[
                        Icon(
                          CupertinoIcons.map_pin,
                          size: 12,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          room,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (room != null && teacherInfo != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            "·",
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (teacherInfo != null) ...[
                        Icon(
                          CupertinoIcons.person_2,
                          size: 12,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 3.5),
                        Expanded(
                          child: Text(
                            teacherInfo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (comment != null) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.25 : 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    size: 13,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      comment,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _cleanText(dynamic value) {
    if (value == null) return null;
    final String text = value.toString().trim();
    if (text.isEmpty || text == "null") {
      return null;
    }
    return text;
  }
}
