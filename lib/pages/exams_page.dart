import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:notely/helpers/text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    _updateNativeAdIndex(widget.examList.length);
  }

  @override
  void dispose() {
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
    if (length <= 0) {
      _nativeAdIndex = -1;
      return;
    }
    _nativeAdIndex = _random.nextInt(length + 1);
  }

  void _loadNativeAdFor(Brightness brightness) {
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

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color subtitleColor =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.75) ??
            (isDarkMode ? Colors.white70 : Colors.black54);
    final titleStyle = pageTitleTextStyle(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tests",
                        style: titleStyle,
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: SizedBox(
                    height: 44,
                    width: 44,
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: (examList.isNotEmpty)
                ? Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
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
                : const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "😄",
                          style: TextStyle(fontSize: 128),
                        ),
                        Text(
                          "Keine Tests vorhanden!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeAd() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = Theme.of(context).primaryColor;

    final Color cardColor =
        isDark ? const Color(0xFF1C1C1E) : Colors.white.withValues(alpha: 0.05);
    if (_nativeAd == null || !_nativeAdIsLoaded) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          maxHeight: 120,
          maxWidth: 450,
        ),
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                  spreadRadius: isDark ? 0 : -8,
                ),
              ],
            ),
            child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),

              child: AdWidget(ad: _nativeAd!))),
      ),
    );
  }

  Widget _buildExamCard({
    required Exam exam,
    required Color subtitleColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = Theme.of(context).primaryColor;
    final DateTime start = exam.startDate.toLocal();
    final DateTime end = exam.endDate.toLocal();
    final Duration duration = end.difference(start);
    final String formattedDate =
        DateFormat("EEE, dd. MMM", 'de_CH').format(start);
    final String timeRange =
        "${DateFormat("HH:mm").format(start)} - ${DateFormat("HH:mm").format(end)}";
    final String? comment = _cleanText(exam.comment);
    final String? teacherInfo = _cleanText(exam.teachers?.join(', '));
    final String? room = _cleanText(exam.roomToken ?? exam.roomId);
    final String examTitle = _cleanText(exam.text) ??
        _cleanText(exam.courseToken) ??
        exam.courseName;

    final Color cardColor =
        isDark ? const Color(0xFF1C1C1E) : Colors.white.withValues(alpha: 0.05);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: isDark ? 0 : -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.courseName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      examTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaRow(
            icon: CupertinoIcons.time,
            label: "$timeRange · ${duration.inMinutes} Min.",
            subtitleColor: subtitleColor,
          ),
          if (room != null) ...[
            const SizedBox(height: 6),
            _buildMetaRow(
              icon: CupertinoIcons.map_pin,
              label: room,
              subtitleColor: subtitleColor,
            ),
          ],
          if (teacherInfo != null) ...[
            const SizedBox(height: 6),
            _buildMetaRow(
              icon: CupertinoIcons.person_2,
              label: teacherInfo,
              subtitleColor: subtitleColor,
            ),
          ],
          if (comment != null) ...[
            const SizedBox(height: 6),
            _buildMetaRow(
              icon: CupertinoIcons.text_alignleft,
              label: comment,
              subtitleColor: subtitleColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required Color subtitleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: subtitleColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 15,
              height: 1.3,
            ),
          ),
        ),
      ],
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
