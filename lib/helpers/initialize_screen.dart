import 'package:flutter/material.dart';
import 'package:notely/helpers/initialization_helper.dart';

class InitializeScreen extends StatefulWidget {
  final Widget targetWidget;

  const InitializeScreen({required this.targetWidget});

  @override
  State<InitializeScreen> createState() => _InitializeScreenState();
}

class _InitializeScreenState extends State<InitializeScreen> {
  final _initializationHelper = InitializationHelper();

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );

  Future<void> _initialize() async {
    final navigator = Navigator.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializationHelper.initialize();
      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.targetWidget,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }
}
