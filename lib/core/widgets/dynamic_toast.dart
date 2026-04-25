import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DynamicToastOverlay extends StatefulWidget {
  final bool isVisible;
  final bool isSuccess;
  final String toastMessage;
  const DynamicToastOverlay(
      {super.key,
      required this.isSuccess,
      required this.toastMessage,
      required this.isVisible});

  @override
  State<DynamicToastOverlay> createState() => _DynamicToastOverlayState();
}

class _DynamicToastOverlayState extends State<DynamicToastOverlay> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: 11.2,
          ),
          AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutBack,
              width: 125.3,
              height: widget.isVisible ? 87 : 36.9,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 2.0),
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      children: [
                        const Spacer(),
                        Icon(
                          widget.isSuccess
                              ? CupertinoIcons.check_mark_circled
                              : CupertinoIcons.xmark_circle,
                          color: widget.isSuccess
                              ? Colors.green
                              : Colors.redAccent,
                          size: 37,
                        ),
                        (widget.toastMessage != "")
                            ? const Spacer()
                            : const SizedBox.shrink(),
                        Text(
                          widget.toastMessage,
                          style: const TextStyle(
                              fontSize: 22.0, color: Colors.white),
                        ),
                        const Spacer(),
                      ],
                    )),
              )),
        ],
      ),
    );
  }
}
