import 'package:flutter/material.dart';
import '/services/services.dart';
import '../constants.dart';
import 'dart:developer' as developer;

class MessageBoxController {
  _MessageBoxState? _messageBoxState;

  void _addState(_MessageBoxState messageBoxState) {
    _messageBoxState = messageBoxState;
  }

  bool isAttached() => _messageBoxState != null;

  void setIndex({int index = -1}) {
    if (isAttached()) {
      _messageBoxState?.setIndex(index);
    }
  }

  void message({Warning message = Warning.none}) {
    if (isAttached()) {
      _messageBoxState?.setIndex(message.index - 1);
    }
  }
}

class MessageBox extends StatefulWidget {
  int index = -1;
  MessageBoxController? controller;
  MessageBox({super.key, this.index = -1, this.controller});
  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox> {
  late int index;

  /// The warning showing, kept while it fades out - it showed the first
  /// warning's text as it went, as index is -1 by then
  int _shown = 0;
  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller!._addState(this);
    }
    index = widget.index;
  }

  setIndex(int boxIndex) {
    if (boxIndex > -1) {
      MapService().fabsController?.drop(height: 80);
    }
    setState(() {
      index = boxIndex;
      if (boxIndex > -1) _shown = boxIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('MessageBox().build() called index: $index',
        name: '_keyboard_');
    Map<String, dynamic> warning = warnings[_shown];
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 500),
      crossFadeState:
          index > -1 ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4), // // Light shadow top
              Colors.black.withValues(alpha: 0.6), // Dark contrast bottom
            ],
          ),
        ),
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Icon(warning['iconData'],
                    color: warning['color'], size: warning['size'])),
            Expanded(
              flex: 12,
              child: Text(
                warning['message'],
                style: TextStyle(fontSize: 20, color: warning['color']),
              ),
            ),
          ],
        ),
      ),
      secondChild: const SizedBox.shrink(),
      onEnd: () async {
        if (index > -1) {
          await Future.delayed(Duration(seconds: 2));
          if (!mounted) return;
          setState(() => index = -1);
          MapService().fabsController?.drop(height: 0);
        }
      },
    );
  }
}
